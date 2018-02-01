---
layout: post
title: "ServiceConfiguration attribute considered harmful"
description: >
  <t render="markdown">
  When working with Episerver, there are several ways how to register your classes in an IoC container. You can choose between StructureMap's configuration API, Episerver's configuration API or use Episerver's ServiceConfiguration attribute on your class.
  </t>
category:
tags: [EPiServer]
date: 2018-01-31
visible: true
---

There are several issues when using _ServiceConfiguration_ attribute. Yes, it is easier just to add an attribute to your class and forget about its registration in an IoC container. But this is the only benefit you get.

# Lifecycle management

When using _ServiceConfiguration_ attribute, the lifecycle of a service is determined before the composition of an object graph. This might lead to weird bugs in the code.
For example, some service might be configured as a singleton (with ServiceConfiguration attribute), and it depends on another service.

```csharp
[ServiceConfiguration(ServiceType = typeof(IService), Lifecycle = ServiceInstanceScope.Singleton)]
public class MyService : IService
{
    private IDependency _dependency;

    public MyService(IDependency dependency)
    {
        _dependency = dependency;
    }

    public void Execute()
    {
        _dependency.Run();
    }
}
```

At this time, you might not know what lifecycle your dependency has. If it is a singleton, then it is okay. But if the dependency is transient, you might get weird results.

Deferring lifecycle management for later - in the composition root or IoC container configuration, allows you to make these decisions when you see the whole picture - all components you have to compose. It is easier with [Poor DI](http://blog.ploeh.dk/2014/06/10/pure-di/) to find lifecycle incompatibilities as a compiler will not allow you even to compile the wrong composition. With _IoC_ containers and their configuration API it is harder, but at least the configuration is in one place.

# Single Responsibility Principle (SRP)

As of single responsibility principle, your code should not have more than one reason to change. With ServiceConfiguration attribute you add another reason - lifecycle management and IoC configuration. IoC configuration leaks into your code. If you would like to reuse your class outside of _Episerver_ code, you would need to modify it.

# Summary

Unfortunately, [Episerver's documentation](https://world.episerver.com/documentation/developer-guides/CMS/initialization/dependency-injection/) describes _ServiceConfiguration_ as a first example (_Implicit registration of services_).

I suggest you always to use "Explicit registration of services." Create an _IConfigurableModule_ module and register your services. You also might want to use _StructureMap_ configuration instead. It would give you more options and more flexibility by splitting different configs into separate registry files.