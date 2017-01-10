---
layout: post
title: "Disposables, StructureMap and Web API Composition Root"
description: >
  <t render="markdown">
  In the last [article](/2013/01/22/better-way-to-configure-structuremap-in-aspnet-webapi/) I wrote how to create StructureMap composition root for Web API, but I mentioned that it will not work with dependences which are disposable. Solution for this issue is simple - use StructureMap's nested containers.
  </t>
category:
tags: [StructureMap, IoC, WebAPI, DI, ASP.NET]
date: 2013-01-26
---

To implement it you have to change Create method of the class which implements IHttpControllerActivator. Create nested container first, register it for dispose on HttpRequestMessage and then resolve Web API controller using nested container. When nested container gets disposed it will call Dispose method on each disposable instance which it created.

Here is the code:

```
public IHttpController Create(
        HttpRequestMessage request,
        HttpControllerDescriptor controllerDescriptor,
        Type controllerType)
{
    var nestedContainer = container.GetNestedContainer();
    request.RegisterForDispose(nestedContainer);
    return (IHttpController)nestedContainer.GetInstance(controllerType);
}
```

And do not to forget replace default IHttpControllerActivator with new one.

```
GlobalConfiguration.Configuration.Services
        .Replace(typeof(IHttpControllerActivator),
            new StructureMapHttpControllerActivator(container));
```
