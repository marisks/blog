---
layout: post
title: "Using MassTransit to improve EPiServer data import on Azure"
description: "Azure has Service Bus service available, but while it is called 'Service Bus' it is messaging service as MSMQ or RabitMQ. Creating reliable message passing might be hard, but luckly there are several frameworks available. In this article I am going to describe how to use MassTransit's Service Bus framework with Azure Service Bus to improve EPiServer data import."
category: [EPiServer]
tags: [EPiServer, Azure]
date: 2015-06-01
visible: true
---

<p class="lead">
Azure has Service Bus service available, but while it is called 'Service Bus' it is messaging service as MSMQ or RabitMQ. Creating reliable message passing might be hard, but luckly there are several frameworks available. In this article I am going to describe how to use MassTransit's Service Bus framework with Azure Service Bus to improve EPiServer data import.
</p>

# Introduction

More than a month ago I wrote an article [Azure infrastructure usage for EPiServer data import](/2015/04/20/azure-infrastructure-usage-for-episerver-data-import/) in which I described how to use _Azure Service Bus_ _Queues_ to create import of _EPiServer_ data. 

While _Azure Service Bus_ _Queues_ did it's work, it has several issues. _Queues_ are only transport layer - those are used to pass messages around. It means that you have to handle errors, retry policy and transaction handling on your own.

Luckly there are several frameworks available to help with these issues. Most popular ones are [MassTransit](http://masstransit-project.com/) and [NServiceBus](http://particular.net/nservicebus), but there are also other frameworks like [Rebus](http://mookid.dk/oncode/rebus). In this article I am going to describe how to use _MassTransit_ for my task.

In my article I used tutorial from [David Prothero](http://looselycoupledlabs.com/author/davidprothero-com/) - [MassTransit on Microsoft Azure](http://looselycoupledlabs.com/2014/09/masstransit-on-microsoft-azure-2/).

# Solution

## Setup

I am using the project from previous [article](/2015/04/20/azure-infrastructure-usage-for-episerver-data-import/). So you have to read it before to understand solution completely.

This time I decided to share common initialization and configuration between projects and created new project for shared configuration initialization - _Configuration_.

Then install _NuGet_ package for _MassTransit_ with _Azure Service Bus_ into all projects which uses _Azure Service Bus_ - _Configuration_, _ImportArticleProcessor_, _ImportDataProcessor_, _NewsSite_.

    Install-Package MassTransit.AzureServiceBus

After installing _NuGet_ package add common configuration to _Configuration_ project. I called class _AzureBusConfiguration_ and added names of namespace and all queues there. Probably in production system you would want to make it configurable (at least namespace name).

    public static class AzureBusConfiguration
    {
        public const string Namespace = "epinewssite";
        public const string ImportDataQueueName = "importqueue";
        public const string ImportArticleQueueName = "importarticlequeue";
    }

Next create _MassTransit's_ _Bus_ initialization class _AzureBusInitializer_ with factory method which creates _IServiceBus_ instance. Here I am just wrapping my _Bus_ initialization logic for whole application. Each _Bus_ instance is created with watching for messages on some queue, with additional initialization if needed and creating connection to _Azure Service Bus_ _Queue_ using connection string.

    public class AzureBusInitializer
    {
        public static IServiceBus CreateBus(
            string queueName,
            Action<ServiceBusConfigurator> moreInitialization,
            string connectionString)
        {
            var bus = ServiceBusFactory.New(sbc =>
            {
                sbc.UseLibLog();

                var queueUri = "azure-sb://" + AzureBusConfiguration.Namespace + "/" + queueName;

                sbc.ReceiveFrom(queueUri);

                sbc.UseAzureServiceBus(a => a.ConfigureNamespace(
                    AzureBusConfiguration.Namespace, h =>
                    {
                        h.SetKeyName("RootManageSharedAccessKey");
                        h.SetKey(CnBuilder(connectionString).SharedAccessKey);
                    }));
                sbc.UseAzureServiceBusRouting();

                moreInitialization(sbc);
            });

            return bus;
        }

        private static ServiceBusConnectionStringBuilder CnBuilder(string connectionString)
        {
            return new ServiceBusConnectionStringBuilder(connectionString);
        }
    }

## Scheduled Job for import initialization

Previous _Scheduled Job_ can be found [here](https://github.com/marisks/NewsSite/blob/master/NewsSite/Business/ImportInitializationJob.cs). I changed _Execute_ method to use newly created _Bus_ initializer. _Bus_ is created by providing queue name to listen for messages on, additional initialization and connection string. This _Scheduled Job_ does not listen to any messages, so it doesn't metter what queue name to provide. Also it do not require aditional initialization, but connection string is retrieved from _Web.config_. We can publish message without wrapping into another class like with _Azure_ _Queues_ (which requires to wrap message within _BrokeredMessage_).

    public override string Execute()
    {
        var cn = ConfigurationManager
                .ConnectionStrings["EPiServerAzureEvents"]
                .ConnectionString;
        
        var container = CreateStorageContainer();

        using (var bus = AzureBusInitializer.CreateBus(
            AzureBusConfiguration.ImportDataQueueName, x => { }, cn))
        {
            foreach (var item in container.ListBlobs()
                                            .OfType<CloudBlockBlob>())
            {
                var importFile = new ImportFile
                {
                    Name = item.Name, Uri = item.Uri
                };
                bus.Publish(importFile, x => {x.SetDeliveryMode(DeliveryMode.Persistent);});
            }
        }

        return "Success";
    }

Now if you run your _Scheduled Job_ it will run successfully, but you will not see any message on _Azure_ _Queues_ because _MassTransit_ requires at least one subscriber to particular message.

## Import data processor

First create message consumer in _ImportDataProcessor_ project. It will watch for messages of _ImportFile_. Consumer class should inherit from _Consumes&lt;T&gt;.Context_ and implement _Consume_ method. _Consume_ method receives message as parameter and received data is hold in _Message_ property. Received message also has _Bus_ property which is reference to _Bus_ instance the message was sent on. As I am publishing another message here, I am reusing it. I am not sure if that is good solution. In production system I would inject _Bus_ instance in _Consumer's_ constructor.

    public class ImportFileConsumer : Consumes<ImportFile>.Context
    {
        public void Consume(IConsumeContext<ImportFile> message)
        {
            var importFile = message.Message;
            var container = CreateStorageContainer();
            var blob = container.GetBlockBlobReference(importFile.Name);

            var articles = ReadArticles(blob).ToList();

            articles.ForEach(article =>
            {
                message.Bus.Publish(article);
            });
        }

        // other code omitted
    }

Next configure _Bus_ to run on _Worker_ process. _Worker_ process do not need _Run_ method anymore. Now just create _Bus_ and provide additional initialization logic which adds _ImportFileConsumer_ to listen for messages.

    public class WorkerRole : RoleEntryPoint
    {
        readonly ManualResetEvent CompletedEvent = new ManualResetEvent(false);
        private IServiceBus _bus;

        public override bool OnStart()
        {
            ServicePointManager.DefaultConnectionLimit = 12;

            var cn = CloudConfigurationManager
                        .GetSetting("Microsoft.ServiceBus.ConnectionString");

            _bus = AzureBusInitializer.CreateBus(
                AzureBusConfiguration.ImportDataQueueName, sbc =>
                {
                    sbc.SetConcurrentConsumerLimit(64);
                    sbc.Subscribe(subs =>
                    {
                        subs.Consumer<ImportFileConsumer>().Permanent();
                    });
                }, cn);

            return base.OnStart();
        }

        public override void OnStop()
        {
            if (_bus != null)
                _bus.Dispose();

            CompletedEvent.Set();
            base.OnStop();
        }
    }

## Import article processor

_ImportArticleProcessor_ is similar to _ImportDataProcessor_. It has _Article_ message consumer defined and initializes _Bus_ same way, but listens on another queue.

    public class ImportArticleConsumer : Consumes<Article>.Context
    {
        public void Consume(IConsumeContext<Article> message)
        {
            var article = message.Message;

            using (var client = CreateClient())
            {
                var str = JsonConvert.SerializeObject(article);
                var content = new StringContent(str, Encoding.UTF8, "text/json");
                var result = client.PostAsync("api/article", content).Result;
                result.EnsureSuccessStatusCode();
            }
        }

        // omitted code
    }

    public class WorkerRole : RoleEntryPoint
    {
        readonly ManualResetEvent CompletedEvent = new ManualResetEvent(false);
        private IServiceBus _bus;

        public override bool OnStart()
        {
            ServicePointManager.DefaultConnectionLimit = 12;

            var cn = CloudConfigurationManager
                        .GetSetting("Microsoft.ServiceBus.ConnectionString");

            _bus = AzureBusInitializer.CreateBus(
                AzureBusConfiguration.ImportArticleQueueName, sbc =>
                {
                    sbc.SetConcurrentConsumerLimit(64);
                    sbc.Subscribe(subs =>
                    {
                        subs.Consumer<ImportArticleConsumer>().Permanent();
                    });
                }, cn);

            
            return base.OnStart();
        }

        public override void OnStop()
        {
             if (_bus != null)
                _bus.Dispose();

            CompletedEvent.Set();
            base.OnStop();
        }
    }

Now application is ready to run. After you publish it on _Azure_ and run you will see that 2 new queues are created and also _MassTransit_ will create 2 new topics with one subscriber for each. When you run import job queues will receive messages and articles gets imported. If your job or site hangs during the run, _MassTransit_ will handle it and next time when consumer gets back to work, it will consume missed messages. These scenarios can be easily tested locally with [Azure Compute emulators](https://azure.microsoft.com/en-us/documentation/articles/cloud-services-performance-testing-visual-studio-profiler/).

Source code can be found on [GitHub](https://github.com/marisks/news_site_masstransit).

# Summary

While working with _Azure Service Bus_ _Queues_ is not hard, complicated scenarios might not work or might require additional work to be done. _MassTransit_ helps to deal with that and starting with it is not harder than working directly with _Azure Queues_.