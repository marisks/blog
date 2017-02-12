---
layout: post
title: "Better event handling in Episerver"
description: >
  <t render="markdown">
  In January I wrote an [article](/2017/01/22/episerver-content-events-explained/) which documented Episerver content events. As it was seen from this article, there are plenty of events available and those have different event arguments with different properties where not all of those properties are used. This makes the API hard to use.
  </t>
category:
tags: [EPiServer]
date: 2017-02-12
visible: true
---

When thinking about _Episerver_ content events as an outer border of your application according to [the ports and adapters architecture](http://blog.ploeh.dk/2013/12/03/layers-onions-ports-adapters-its-all-the-same/) (even known as [a pizza architecture](http://blog.tech-fellow.net/2016/10/17/baking-round-shaped-software/) :)), then we have to implement some adapter for these events. This adapter should translate _Episerver_ events into our application's events.

There is a good solution for such purpose. Some time ago [Valdis Iļjučonoks](http://blog.tech-fellow.net/) wrote an [article](http://blog.tech-fellow.net/2016/10/30/baking-round-shaped-software-mapping-to-the-code/) how [Mediator pattern](https://en.wikipedia.org/wiki/Mediator_pattern) can help with this. I am going to use [MediatR](https://github.com/jbogard/MediatR) library for this purpose.

First of all, install _MediatR_ in your project.

```
Install-Package MediatR
```

Then there will be a need for an initialization module where the events will be handled. Create one, in the _Initialize_ method load _IContentEvents_ and attach an event handler to the events you care. In this example, I am attaching to the _SavedContent_ event. Do not forget to detach the events in the _Uninitialize_ method.

```
[InitializableModule]
[ModuleDependency(typeof(EPiServer.Web.InitializationModule))]
public class EventInitialization : IInitializableModule
{
    private static bool _initialized;

    private Injected<IMediator> InjectedMediator { get; set; }
    private IMediator Mediator => InjectedMediator.Service;

    public void Initialize(InitializationEngine context)
    {
        if (_initialized)
        {
            return;
        }

        var contentEvents = context.Locate.ContentEvents();
        contentEvents.SavedContent += OnSavedContent;

        _initialized = true;
    }

    private void OnSavedContent(object sender, ContentEventArgs contentEventArgs)
    {
    }

    public void Uninitialize(InitializationEngine context)
    {
    }
}
```

So now there is an event handler and we somehow should call the Mediator. To start with it, we have to create our own _event_ types. Here is an example of the _SavedContentEvent_.

```
public class SavedContentEvent : INotification
{
    public SavedContentEvent(ContentReference contentLink, IContent content)
    {
        ContentLink = contentLink;
        Content = content;
    }

    public ContentReference ContentLink { get; set; }

    public IContent Content { get; set; }
}
```

This event contains only those properties which are important for this event and not more.

Now we are ready to publish our first event. Locate mediator instance, create our event from the _ContentEventArgs_ and call a mediator's _Publish_ method with our event as a parameter.

```
private Injected<IMediator> InjectedMediator { get; set; }
private IMediator Mediator => InjectedMediator.Service;

private void OnSavedContent(object sender, ContentEventArgs contentEventArgs)
{
    var ev = new SavedContentEvent(contentEventArgs.ContentLink, contentEventArgs.Content);
    Mediator.Publish(ev);
}
```

The last step for the mediator to be able to publish events is its configuration. You can find configuration examples for different IoC containers in the documentation. Here is an example of the configuration required for _StructureMap_ which is added in the configurable initialization module.

```
container.Scan(
    scanner =>
    {
        scanner.TheCallingAssembly();
        scanner.AssemblyContainingType<IMediator>();
        scanner.WithDefaultConventions();
        scanner.ConnectImplementationsToTypesClosing(typeof(IRequestHandler<,>));
        scanner.ConnectImplementationsToTypesClosing(typeof(IAsyncRequestHandler<,>));
        scanner.ConnectImplementationsToTypesClosing(typeof(ICancellableAsyncRequestHandler<>));
        scanner.ConnectImplementationsToTypesClosing(typeof(INotificationHandler<>));
        scanner.ConnectImplementationsToTypesClosing(typeof(IAsyncNotificationHandler<>));
        scanner.ConnectImplementationsToTypesClosing(typeof(ICancellableAsyncNotificationHandler<>));
    });
container.For<SingleInstanceFactory>().Use<SingleInstanceFactory>(ctx => t => ctx.GetInstance(t));
container.For<MultiInstanceFactory>().Use<MultiInstanceFactory>(ctx => t => ctx.GetAllInstances(t));
```

Now when everything is set up, how to use these published events? You have to create handlers for the events. The meditator will send events to all event handlers. So you can create as much event handlers as you need for the single event. Event handlers support [Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection), so you can inject whatever services you need in the constructor. Here is an example how handlers for the _SavedContentEvent_ could look like.

```
public class SendAdminEmailOnSavedContent : INotificationHandler<SavedContentEvent>
{
    private readonly IEmailService _emailService;

    public SendAdminEmailOnSavedContent(IEmailService emailService)
    {
        _emailService = emailService;
    }

    public void Handle(SavedContentEvent notification)
    {
        // Handle event.
    }
}

public class LogOnSavedContent: INotificationHandler<SavedContentEvent>
{
    public void Handle(SavedContentEvent notification)
    {
        // Handle event.
    }
}
```

# Summary

This solution might look too complex for handling some simple events but usually, those simple events become quite complex in our applications. And then event handling for all cases of those are baked in the initialization module's single method. The code becomes hard to maintain.

With a mediator, events have separate handlers for each case you need. So it is much easier to change the code when requirements change. It is much easier to add new event handling for new requirements and in general, the code becomes much easier to reason about.
