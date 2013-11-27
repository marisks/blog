---
layout: post
title: "Setting up RavenDB in EPiServer"
description: ""
category: 
tags: [RavenDB,EPiServer]
date: 2013-02-21
---

I am using RavenDB in EPiServer for several months already. It is great replacement for DDS (Dynamic Data Store).

Setting up RavenDB in EPiServer is same as in some other ASP.NET application. I am using StructureMap as dependency resolver, but it could be any DI container. I created StructureMap Registry and I am registering there DocumentStore as singleton and DocumentSession as HybridHttpOrThreadLocalScoped:

    public class RavenDbRegistry : Registry
    {
        public RavenDbRegistry()
        {
            For<IDocumentStore>()
                    .Singleton()
                    .Use(
                         context =>
                         new DocumentStore
                             {
                                     ConnectionStringName = "RavenDB"
                             }.Initialize()
                    );

            For<IDocumentSession>()
                    .HybridHttpOrThreadLocalScoped()
                    .Use(
                         context =>
                         context
                                 .GetInstance<IDocumentStore>()
                                 .OpenSession());
        }
    }

Connection string is retrieved same as in SQL server - from connectionStrings section in Web.config and looks like this: "Url=http://localhost:8080;Database=Stores"

After creating Registry do not forget to add it and other Registries to container:

	public class StructureMapBootStrapper
    {
        public static IContainer Configure()
        {
            ObjectFactory.Initialize(
                                     x =>
                                     {
                                         x.AddRegistry<RepositoryRegistry>();
                                         x.AddRegistry<ServiceRegistry>();
                                         x.AddRegistry<RavenDbRegistry>();
                                     });

            return ObjectFactory.Container;
        }
    }

Initialize container in Global.asax on Application_Start.

    protected void Application_Start(object sender, EventArgs e)
    {
        var container = StructureMapBootStrapper.Configure();
        // Other initialization code ...
    }

If you have setup your composition root properly (see previous articles about Web API [here](/2013/01/22/better-way-to-configure-structuremap-in-aspnet-webapi/) and [here](/2013/01/26/disposables-structuremap-and-web-api-composition-root/)), you can use IDocumentSession in your code by injecting it. For example, using it in Web API:

    public class StoreController : ApiController
    {
        IDocumentSession session;
        public StoreController(IDocumentSession session)
        {
            this.session = session;
        }

        public  Store Get(string id)
        {
            return session.Load<Store>(id);
        }
    }