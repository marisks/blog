---
layout: post
title: "Better way to configure StructureMap in ASP.NET WebAPI"
description: "Few months ago Mark Seeman posted an article about why using Web API's IDependencyResolver is not appropriate. He suggests composing the dependency graph in IHttpControllerActivator because it provides context for composition."
category: 
tags: [StructureMap, WebAPI, ASP.NET, DI, IoC]
date: 2013-01-22
---

<p class="lead">
Few months ago [Mark Seeman](http://blog.ploeh.dk/) posted [article](http://blog.ploeh.dk/2012/09/28/DependencyInjectionAndLifetimeManagementWithASPNETWebAPI.aspx) about why using Web API's IDependencyResolver is not appropriate. He suggests composing the dependency graph in IHttpControllerActivator because it provides context for composition. More about it could be read in his article.
</p>

In other [article](http://blog.ploeh.dk/2012/10/03/DependencyInjectionInASPNETWebAPIWithCastleWindsor.aspx) Mark shows how to set up Castle Windsor container for Web API. I am going to show implementation for StructureMap. All you need to do is create custom IHttpControllerActivator implementation and implement Create method where you resolve controller instances. As controller types are concrete classes we just have to call GetInstance method by providing controller type.

	public class StructureMapHttpControllerActivator : IHttpControllerActivator
    {
        private readonly IContainer container;

        public StructureMapHttpControllerActivator(IContainer container)
        {
            this.container = container;
        }

        public IHttpController Create(
                HttpRequestMessage request,
                HttpControllerDescriptor controllerDescriptor,
                Type controllerType)
        {
            return (IHttpController)this.container.GetInstance(controllerType);
        }
    }

It will resolve any dependencies required by controller on controller creation.

But this solution will do well only if you do not have any disposable dependencies. With StructureMap you have to release any disposable dependences manually.

To register new IHttpControllerActivator just replace default one with yours in Global.asax on application start.

	GlobalConfiguration.Configuration.Services
		.Replace(typeof(IHttpControllerActivator), 
			new StructureMapHttpControllerActivator(container));