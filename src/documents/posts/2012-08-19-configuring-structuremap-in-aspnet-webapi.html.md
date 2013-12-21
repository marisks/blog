---
layout: post
title: "Configuring StructureMap in ASP.NET WebAPI"
description: "Last week I started to work in project with WebAPI and first thing what I noticed was improper usage of StructureMap as IoC container. I googled for StructureMap configuration in WebAPI, but couldn't find good solution. But."
category: 
tags: [StructureMap, WebAPI, ASP.NET, DI, IoC]
date: 2012-08-19
---

<p class="lead">
Last week I started to work in project with WebAPI and first thing what I noticed was improper usage of StructureMap as IoC container. I googled for StructureMap configuration in WebAPI, but couldn't find good solution. But, I found great tutorial how to inject dependencies into WebAPI controllers and do dependency injection with Unity IoC container: [Using the Web API Dependency Resolver](http://www.asp.net/web-api/overview/extensibility/using-the-web-api-dependency-resolver). 
</p>

Dependency injection in WebAPI are done with two classes - first implements IDependencyScope interface and second inherits first class and implements IDependencyResolver interface. IDependencyScope represents child scope - any resources created in it should be released in Dispose method. Unity container supports creating child containers and it is used in WebAPI. StructureMap starting with version 2.6.1 also supports child container creation - those are called "nested containers" ([“Nested Containers” in StructureMap 2.6.1](http://codebetter.com/jeremymiller/2010/02/10/nested-containers-in-structuremap-2-6-1/)). When nested containers in StructureMap are disposed, all transient objects that it created also are disposed - that's what we want to achieve in IDependencyScope implementation. Solution is easy - just replace Unity implementation from [Using the Web API Dependency Resolver](http://www.asp.net/web-api/overview/extensibility/using-the-web-api-dependency-resolver) article with StructureMap implementation.

Here is final result:

    public class StructureMapScope : IDependencyScope
    {
    	private readonly IContainer container;
    
    	public StructureMapScope(IContainer container)
    	{
    		if (container == null)
    		{
    			throw new ArgumentNullException("container");
    		}
    		this.container = container;
    	}
    
    	public object GetService(Type serviceType)
    	{
    		if (serviceType == null)
    		{
    			return null;
    		}
    
    		if (serviceType.IsAbstract || serviceType.IsInterface)
    		{
    			return this.container.TryGetInstance(serviceType);
    		}
    
    		return this.container.GetInstance(serviceType);
    	}
    
    	public IEnumerable<object> GetServices(Type serviceType)
    	{
    		return this.container.GetAllInstances(serviceType).Cast<object>();
    	}
    
    	public void Dispose()
    	{
    		this.container.Dispose();
    	}
    }
    	  
    public class StructureMapDependencyResolver : StructureMapScope, IDependencyResolver
    {
    	private readonly IContainer container;
    
    	public StructureMapDependencyResolver(IContainer container) : base(container)
    	{
    		this.container = container;
    	}
    
    	public IDependencyScope BeginScope()
    	{
    		var childContainer = this.container.GetNestedContainer();
    		return new StructureMapScope(childContainer);
    	}
    }

Finally you have to initialize your container and register your dependency resolver in Global.asax:

	// Initialize your container here ...
	GobalConfiguration.Configuration.DependencyResolver = new StructureMapDependencyResolver(container);