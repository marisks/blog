---
layout: post
title: "Azure infrastructure usage for EPiServer data import"
description: "I was working in EPiServer Commerce project on product import and thought that it would be great to use Azure infrastructure to make import process more reliable and consume less resources of Web server. In this article I am describing sample project using Azure Service Bus Queues and Worker Roles for this task."
category: [EPiServer]
tags: [EPiServer,Azure]
date: 2015-04-20
visible: true
---

<p class="lead">
I was working in EPiServer Commerce project on product import and thought that it would be great to use Azure infrastructure to make import process more reliable and consume less resources of Web server. In this article I am describing sample project using Azure Service Bus Queues and Worker Roles for this task.
</p>

In my current _EPiServer Commerce_ solution import is done using custom _Scheduled Jobs_ which are resource intensive. Jobs has to be run at night to not decrease performance of Web servers. When something fails during import process _Scheduled Jobs_ should start from beginning and only next night. It is not good solution in global world where applications should run 24/7 and should perform well any time. Udi Dahan describes this issue well in article [Status fields on entities - HARMFUL?](http://particular.net/blog/status-fields-on-entities-harmful). I created sample _EPiServer CMS_ site with page import to test such architecture.

# Sample site

I am not going to create _EPiServer Commerce_ site for this demo, but use CMS site as the main idea for data import remains same.

I have described new _EPiServer CMS_ project creation and hosting on _Azure_ in previous [blog post](/2015/04/11/episerver-cms-site-as-azure-web-app/). Additionaly there are added simple start page and article page types to the project. Source code for the site and whole solution can be found on [GitHub](https://github.com/marisks/NewsSite). For data import test I am going to import article pages from CSV file. Here is sample CSV file format:

    Name,Intro,Content,ImageUrl
    "The Car","The Car was presented today","Today the greatest of cars was presented - <b>The Car</b>.",http://www.publicdomainpictures.net/pictures/100000/velka/vintage-convertible-automobile.jpg

# Solution architecture

<img src="/img/2015-04/azure_episerver_import_arch.png" alt="Azure EPiServer import architecture" class="img-responsive">

1. The CSV file is uploaded onto _Azure Storage_. 
2. _EPiServer_ _Scheduled Job_ time to time looks for added import files. 
3. When file appears, it creates _Service Bus_ message with file information and publishes onto the file import queue. 
4. File import _Worker_ gets messages from file import queue, 
5. reads file from _Storage_, 
6. parses it and creates messages with article data (one message per article). 
7. Then it publishes messages with article data onto the article import queue. 
8. Second _Worker_ - article import worker gets messages from article import queue 
9. and posts them to _Web API_ endpoint on _EPiServer_ site where new articles get created.

In this sample architecture we can see that any data transformation, file download/processing tasks can be moved to _Workers_. Such _Workers_ can run paralelly and their throughput can be increased or decreased by needs or configured to autoscale. Also it offloads main _EPiServer_ site from background processing tasks.

# Storage for import data

When running Web application on _Azure_ there is no available file system for storing large amount of data and it has to be uploaded somehow to the system for processing. In on-premise solution easiest way is to have separated disk for data and configure FTP for upload. In _Azure_ I can use _Azure Storage_.

There are multiple ways how to upload import files to it. You can create the page for import file upload and use [Storage API](http://azure.microsoft.com/en-us/documentation/articles/storage-dotnet-how-to-use-blobs/) or use some tool. In this article I am going to use [AzCopy](http://azure.microsoft.com/en-us/documentation/articles/storage-use-azcopy/) tool.

I already have created storage for _EPiServer CMS_ and will use it for import data too, but I will add separate container and will call it _epiimportdata_.

<img src="/img/2015-04/azure_storage_new_container.png" alt="Azure new Storage container view" class="img-responsive">

After container has been created I can use _AzCopy_ to upload the file which is located on my computer - _D:\Temp\data\articles.csv_. Provide source directory for _AzCopy_, destination container URL and destination _Storage_ primary or secondary key.

    PS D:\Temp> AzCopy /Source:D:\Temp\data\ /Dest:https://epinewssite.blob.core.windows.net/epiimportdata /DestKey:{key} /S
    Finished 1 of total 1 file(s).
    [2015-04-15 09:34:14] Transfer summary:
    -----------------
    Total files transferred: 1
    Transfer successfully:   1
    Transfer skipped:        0
    Transfer failed:         0
    Elapsed time:            00.00:00:01

After upload completed you can view files in _Azure Portal_.

<img src="/img/2015-04/azure_storage_file_view.png" alt="Azure Storage Container file view" class="img-responsive">

# Processing

## EPiServer Scheduled Job for Storage monitoring

When file is uploaded to the _Storage_, system should start processing it. There are several ways to crate Storage container file monitoring, for example, using [WebJob](http://stackoverflow.com/a/22053735/660154).

I created _EPiServer_ _Scheduled Job_ which is running periodically and watching for new files in _Storage_. It uses [Azure Storage API](http://azure.microsoft.com/en-us/documentation/articles/storage-dotnet-how-to-use-blobs/) to list files and creates file DTO objects (_ImportFile_) with file (blob) data - _Name_ and _URL_. Then it creates message to publish on _ImportQueue_ queue in _ServiceBus_.

    [ScheduledPlugIn(DisplayName = "Init import", SortIndex = 2000)]
    public class ImportInitializationJob : JobBase
    {
        public override string Execute()
        {
            var container = CreateStorageContainer();

            foreach (var item in container.ListBlobs()
                                            .OfType<CloudBlockBlob>())
            {
                var importFile = new ImportFile
                {
                    Name = item.Name, Uri = item.Uri
                };
                var message = new BrokeredMessage(importFile);
                QueueConnector.Client.Send(message);
            }

            return "Success";
        }

        private const string ContainerName = "epiimportdata";

        private static CloudBlobContainer CreateStorageContainer()
        {
            var cn = ConfigurationManager
                            .ConnectionStrings["EPiServerAzureBlobs"]
                            .ConnectionString;
            var storageAccount = CloudStorageAccount.Parse(cn);
            var blobClient = storageAccount.CreateCloudBlobClient();

            var container = blobClient.GetContainerReference(ContainerName);
            container.CreateIfNotExists();
            return container;
        }
    }

I am reusing _EPiServer_ _Azure Storage_, but creating separate container. In production system you would like to move processed files to another container or other path before sending message to the queue, that next time when _Scheduled Job_ is running, it will not load same file again.

For DTO objects I created separate library project called _Contracts_. I am referencing it in all projects which produces or consumes messages from queues.

_QueueConnector_ in this example is taken from article [.NET Multi-Tier Application Using Service Bus Queues](http://azure.microsoft.com/en-us/documentation/articles/cloud-services-dotnet-multi-tier-app-using-service-bus-queues/). I just changed queue name and created namespace manager from connection string. I reused same _ServiceBus_ namespace as used for _EPiServer_ - _epinewssite_.

    public static class QueueConnector
    {
        public static QueueClient Client;

        public const string Namespace = "epinewssite";
        public const string QueueName = "ImportQueue";

        public static NamespaceManager CreateNamespaceManager()
        {
            var cn = ConfigurationManager
                    .ConnectionStrings["EPiServerAzureEvents"]
                    .ConnectionString;
            return NamespaceManager.CreateFromConnectionString(cn);
        }

        public static void Initialize()
        {
            ServiceBusEnvironment.SystemConnectivity.Mode =
                ConnectivityMode.Http;

            var namespaceManager = CreateNamespaceManager();

            if (!namespaceManager.QueueExists(QueueName))
            {
                namespaceManager.CreateQueue(QueueName);
            }

            var messagingFactory = MessagingFactory.Create(
                namespaceManager.Address,
                namespaceManager.Settings.TokenProvider);
            Client = messagingFactory.CreateQueueClient(QueueName);
        }
    }

Now can try and run _Scheduled Job_. Deploy new version of Web site to _Azure_ and run _Sheduled Job_. Then in [old Azure Portal](https://manage.windowsazure.com) click _Service Bus_ in the menu on the left and from the list choose namespace.

<img src="/img/2015-04/azure_service_bus_connection.png" alt="Azure Service Bus view" class="img-responsive">

Then open _Queues_ tab and you should see that in _importqueue_ _QUEUE LENGTH_ column has value _1_.

<img src="/img/2015-04/azure_service_bus_importqueue.png" alt="Azure Service Bus import queue view" class="img-responsive">

## Import file Worker

First of all I have to create _Azure Cloud Service_ project.

<img src="/img/2015-04/new_azure_cloud_service.png" alt="New Azure Cloud Service dialog" class="img-responsive">

Then choose to create _Worker Role with Service Bus Queue_ and rename it by clicking on small pencil on the right and type it's name.

<img src="/img/2015-04/new_worker_role.png" alt="New Worker Role dialog" class="img-responsive">

Two new projects will be created - _Worker Role_ project and _Azure Cloud Service_ project. _Azure Cloud Service_ project contains all needed configuration and also is responsible for deployment to _Azure_.

_Worker Role_ project contains _WorkerRole.cs_ which is starting point. As I created _Worker Role with Service Bus Queue_ it already contains code to handle messages from queue.

First of all I am going to configure connection strings for _Service Bus_ and _Storage_. In the _Azure Cloud Service_ project, right-click on the _Worker Role_ under _Roles_ folder and select _Properties_. Then select _Settings_ tab on the left. There is already setting for _Service Bus Queue_, but I have to change it to my _Service Bus_ connection string. Then I also added _Storage_ connection string.

<img src="/img/2015-04/worker_role_settings.png" alt="Worker Role settings dialog" class="img-responsive">

In _WorkerRole.cs_ _OnStart_ method configure two _Service Bus_ clients - one for incomming messages and other for outgoing. In production system you might have multiple incoming and outgoing messages, but for this example I use one one for each direction. To read _Worker Role_ settings I am using _CloudConfigurationManager_.

    const string InQueueName = "ImportQueue";
    const string OutQueueName = "ImportArticleQueue";

    QueueClient InClient;
    QueueClient OutClient;

    public override bool OnStart()
    {
        ServicePointManager.DefaultConnectionLimit = 12;

        var cn = CloudConfigurationManager.GetSetting("Microsoft.ServiceBus.ConnectionString");
        var namespaceManager = NamespaceManager.CreateFromConnectionString(cn);
        if (!namespaceManager.QueueExists(InQueueName))
        {
            namespaceManager.CreateQueue(InQueueName);
        }

        if (!namespaceManager.QueueExists(OutQueueName))
        {
            namespaceManager.CreateQueue(OutQueueName);
        }

        InClient = QueueClient.CreateFromConnectionString(cn, InQueueName);
        OutClient = QueueClient.CreateFromConnectionString(cn, OutQueueName);
        return base.OnStart();
    }

Then I created method to initialize _Storage Container_.

    private const string ContainerName = "epiimportdata";

    private static CloudBlobContainer CreateStorageContainer()
    {
        var connectionString = CloudConfigurationManager.GetSetting("EPiServerAzureBlobs");
        var storageAccount = CloudStorageAccount.Parse(connectionString);
        var blobClient = storageAccount.CreateCloudBlobClient();

        var container = blobClient.GetContainerReference(ContainerName);
        container.CreateIfNotExists();
        return container;
    }

Now I am rady to consume messages. Execution of the worker is done in _Run_ method. First of all I am reading message into my DTO - _ImportFile_, then getting blob reference for file by it's name. I am reading and parsing CSV file in _ReadArticles_ method and creating sequence of _Artice_ DTOs. When it's done publish _Article_ DTOs on outgoing queue.

    public override void Run()
    {
        Trace.WriteLine("Starting processing of messages");

        InClient.OnMessage((receivedMessage) =>
            {
                try
                {
                    Trace.WriteLine("Processing Service Bus message: " + 
                                     receivedMessage.SequenceNumber.ToString());

                    var importFile = receivedMessage.GetBody<ImportFile>();
                    var container = CreateStorageContainer();
                    var blob = container.GetBlockBlobReference(importFile.Name);

                    var articles = ReadArticles(blob).ToList();

                    articles.ForEach(article =>
                    {
                        var message = new BrokeredMessage(article);
                        OutClient.Send(message);
                    });

                    receivedMessage.Complete();
                }
                catch(Exception ex)
                {
                    Trace.TraceError("Exception: {0} \n Stack Trace: {1}",
                                        ex.Message, ex.StackTrace);
                }
            });

        CompletedEvent.WaitOne();
    }

For CSV parsing I am just reading file line by line and split columns by comma, but in production solution I probably would use some library to do it, for example, [CSV helper](http://joshclose.github.io/CsvHelper/).

    private static IEnumerable<Article> ReadArticles(CloudBlockBlob blob)
    {
        var text = blob.DownloadText();
        
        using (var sr = new StringReader(text))
        {
            string line;
            var row = 0;
            while ((line = sr.ReadLine()) != null)
            {
                row++;
                if (row == 1) continue;

                var fields = line.Split(',');
                yield return new Article
                {
                    Name = fields[0],
                    Intro = fields[1],
                    Content = fields[2],
                    ImageUrl = fields[3]
                };
            }
        }
    }

Now _Worker_ is ready for deployment. Right-click on _Azure Cloud Service_ project and choose _Publish_. Sign in by providing credentials and create new cloud service - provide name and region.

<img src="/img/2015-04/create_cloud_service.png" alt="Create Cloud Service dialog" class="img-responsive">

Then choose environment - _Staging_ or _Production_, build configuration and service configuration.

<img src="/img/2015-04/cloud_service_publishing_settings.png" alt="Cloud Service publishing settings dialog" class="img-responsive">

After all settings are configured click _Publish_. You can see progress in _Azure Activity Log_.

<img src="/img/2015-04/cloud_service_publishing.png" alt="Azure Activity Log dialog" class="img-responsive">

Deployment will take quite a lot of time. After deployment finished, _Worker_ will run automatically and will consume messages from queue. Now we should have two queues and second queue will contain one message.

<img src="/img/2015-04/azure_service_bus_importarticlequeue.png" alt="Azure Service Bus queue view" class="img-responsive">

## Import articles Worker

For article import I will create another _Worker_. Follow same steps as for first _Worker_ - create new _Worker Role with Service Bus_, configure _Service Bus_ connection string, but skip _Storage_ configuration as I will not use it in new _Worker_. Also I will need only one queue for incomming _Article_ messages - _ImportArticleQueue_.

    const string InQueueName = "ImportArticleQueue";

    QueueClient InClient;

    public override bool OnStart()
    {
        ServicePointManager.DefaultConnectionLimit = 12;

        var cn = CloudConfigurationManager.GetSetting("Microsoft.ServiceBus.ConnectionString");
        var namespaceManager = NamespaceManager.CreateFromConnectionString(cn);
        if (!namespaceManager.QueueExists(InQueueName))
        {
            namespaceManager.CreateQueue(InQueueName);
        }

        InClient = QueueClient.CreateFromConnectionString(cn, InQueueName);
        return base.OnStart();
    }

Then I am going to consume _Article_ messages and just post to _Web API_ end-point which I created in _EPiServer_ site.

    public override void Run()
    {
        Trace.WriteLine("Starting processing of messages");

        InClient.OnMessage((receivedMessage) =>
            {
                try
                {
                    // Process the message
                    Trace.WriteLine("Processing Service Bus message: " 
                                    + receivedMessage.SequenceNumber.ToString());

                    var article = receivedMessage.GetBody<Article>();

                    using (var client = CreateClient())
                    {
                        var str = JsonConvert.SerializeObject(article);
                        var content = new StringContent(str, Encoding.UTF8, "text/json");
                        var result = client.PostAsync("api/article", content).Result;
                        result.EnsureSuccessStatusCode();
                    }
                }
                catch
                {
                    // Handle any message processing specific exceptions here
                }
            });

        CompletedEvent.WaitOne();
    }

    private HttpClient CreateClient()
    {
        var client = new HttpClient {BaseAddress = new Uri("http://epinewssite.azurewebsites.net/")};
        client.DefaultRequestHeaders.Accept.Clear();
        client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        return client;
    }

_Web API_ controller just creates new page if it does not exist yet.

    public void Post(Article article)
    {
        var existing = _contentRepository
                            .GetChildren<ArticlePage>(ContentReference.StartPage)
                            .FirstOrDefault(x => x.Name == article.Name);
        if (existing != null)
        {
            return;
        }

        var newArticlePage = _contentRepository
                                .GetDefault<ArticlePage>(ContentReference.StartPage);

        newArticlePage.Name = article.Name;
        newArticlePage.Intro = article.Intro;
        newArticlePage.Content = new XhtmlString(article.Content);

        _contentRepository.Save(newArticlePage, SaveAction.Publish, AccessLevel.NoAccess);
    }

Now publish _Cloud Service_ again and will see that message disappears from queue and new article appears in _EPiServer CMS_. Import process is created and working.

# Summary

For smaller tasks like in this example, it might not be reasonable to use all this infrastructure and simpler solution would be just creating some _Scheduled Job_ or page for data upload and import. But more complex import process could benefit from such solution. For example, such process might require to transform product CSV file, download sales data from 3rd party service, download images and thumbnails from media service and in the result package all data and import with [EPiServer Commerce Service API](http://world.episerver.com/documentation/Items/EPiServer-Service-API/).

_Azure_ might not only improve your import process. I was using _Azure Storage_ and _Service Bus Queues_, but there are available lot more [services](http://azure.microsoft.com/en-us/overview/what-is-azure/) you can use for your solution needs. Just use them when needed.