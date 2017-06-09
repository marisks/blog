---
layout: post
title: "EpiEvents - a library for simpler Episerver event handling"
description: >
  <t render="markdown">
  A few months ago I wrote an [article](/2017/02/12/better-event-handling-in-episerver/) about better event handling. Now I have created and published a library which allows you to handle Episerver events in this way easier.
  </t>
category:
tags: [EPiServer]
date: 2017-06-09
visible: true
---

Install the library from the [Episerver NuGet Feed](http://nuget.episerver.com/feed/packages.svc/):

```powershell
Install-Package EpiEvents.Core
```

The library uses [MediatR](https://github.com/jbogard/MediatR) for event publishing and handling. You have to configure it in the _StructureMap_ config.

```csharp
Scan(x =>
{
    x.TheCallingAssembly();
    x.ConnectImplementationsToTypesClosing(typeof(INotificationHandler<>));
    x.ConnectImplementationsToTypesClosing(typeof(IAsyncNotificationHandler<>));
});
For<SingleInstanceFactory>().Use<SingleInstanceFactory>(ctx => t => ctx.GetInstance(t));
For<MultiInstanceFactory>().Use<MultiInstanceFactory>(ctx => t => ctx.GetAllInstances(t));
For<IMediator>().Use<Mediator>();
```

You also have to configure default settings for the _EpiEvents_.

```csharp
For<EpiEvents.Core.ISettings>().Use<EpiEvents.Core.DefaultSettings>();
```

Default settings disable all loading events. Loading events cause Episerver to slow down. But you can enable those events in the _appSettings_.

```xml
<add key="EpiEvents:EnableLoadingEvents" value="true" />
```

Handling of an event is simple. Create _MediatR's_ _INotificationHandler_ with a type parameter of the event you want to handle.

```csharp
public class SampleHandler : INotificationHandler<CreatedContent>
{
    public void Handle(CreatedContent notification)
    {
        // Handle your event
    }
}
```

For more information see the [GitHub page](https://github.com/marisks/EpiEvents).
