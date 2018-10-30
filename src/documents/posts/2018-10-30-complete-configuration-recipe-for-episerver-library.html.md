---
layout: post
title: "A complete configuration recipe for Episerver library"
description: >
  <t render="markdown">
    In the previous two articles, I described how to use different techniques for Episerver library configuration. Now it's time to wrap it in a complete solution.
  </t>
category:
tags: [EPiServer]
date: 2018-10-30
visible: true
---

## Introduction

I have created an example library to show how the configuration should be set up. The library adds _Episerver_ content event logging. A library user can configure the log level and to which events to subscribe (it supports two events in an example).

## Library implementation

First of all, let's create the functionality of our library. I am creating a class which logs an event using _Episerver_ logging. It has two parameters - the name of an event and _ContentEventArgs_ arguments, and it logs the provided information.

```csharp
public class ContentEventLogger
{
    private readonly ILogger _logger = LogManager.GetLogger(typeof(ContentEventLogger));

    public virtual void Log(string name, ContentEventArgs args)
    {
        _logger.Log(Level.Information, $"Event: {name}; Content: {args.Content?.Name}");
    }
}
```

The requirements stated that we should be able to change the log level by some configuration. For this purpose, I am creating a settings class and inject it in our logger.

```csharp
public class LoggerSettings
{
    public LoggerSettings()
    {
        Level = Level.Information;
    }

    public Level Level { get; private set; }

    public LoggerSettings LogLevel(Level level)
    {
        return new LoggerSettings { Level = level };
    }
}

public class ContentEventLogger
{
    private readonly LoggerSettings _settings;
    private readonly ILogger _logger = LogManager.GetLogger(typeof(ContentEventLogger));

    public ContentEventLogger(LoggerSettings settings)
    {
        _settings = settings ?? throw new ArgumentNullException(nameof(settings));
    }

    public virtual void Log(string name, ContentEventArgs args)
    {
        _logger.Log(_settings.Level, $"Event: {name}; Content: {args.Content?.Name}");
    }
}
```

## Library's settings configuration

Now we provided settings of our logger through dependency injection. However, how to configure it so that settings are injected, and it is simple enough for our library users?

_Episerver_ has an API for dependency injection configuration. We can use it to register our settings and our logger in an _IConfigurableModule_.

```csharp
public void ConfigureContainer(ServiceConfigurationContext context)
{
    var settings = new LoggerSettings();
    context.Services.AddSingleton(settings);
    context.Services.AddSingleton<ContentEventLogger>();
}
```

While this works, the question is who is responsible for this registration. If we create an _IConfigurableModule_ in our library, then the user will not be able to set the settings they need. If we make the user responsible for all registrations, the user will need proper documentation to not mess up with it. In this example, the configuration is simple, but what would happen if the user has to register ten or more services?

The solution is in the middle. We can provide a simple API for the user to configure the library in their _IConfigurableModule_ but same time without too many details.

For this purpose, I am creating several extension methods for _ServiceConfigurationContext_. There is one extension method which uses default configuration and the second one which allows setting log level you want. Notice that I prefixed extension methods with _Add_. This approach is a convention used in _ASP.NET Core_.

```csharp
public static void AddContentEventLogger(
    this ServiceConfigurationContext context)
{
    context.AddContentEventLogger(_ => _);
}

public static void AddContentEventLogger(
    this ServiceConfigurationContext context,
     Func<LoggerSettings, LoggerSettings> configure)
{
    var settings = configure(new LoggerSettings());

    context.Services.AddSingleton(settings);
    context.Services.AddSingleton<ContentEventLogger>();
}
```

With these extension methods, the user can register our logger in their _IConfigurableModule_.

```csharp
public void ConfigureContainer(ServiceConfigurationContext context)
{
    context.AddContentEventLogger();

    // or

    context.AddContentEventLogger(x => x.LogLevel(Level.Error));
}
```

## Initialization configuration

While we have implemented our logging functionality, it is not used anywhere. We have to attach it to _Episerver_ events. So we need some initialization logic.

Again, we can create an initialization module in our library and attach to the events but this way our library user loses control. They are not able to configure to which events to attach.

Instead, let's create a particular class for our library initialization for which we provide additional settings.

```csharp
public enum ContentEvent
{
    Created,
    Published
}

public class InitializerSettings
{
    public IEnumerable<ContentEvent> Events { get; private set; }

    public InitializerSettings()
    {
        Events = Enumerable.Empty<ContentEvent>();
    }

    public InitializerSettings SubscribeTo(ContentEvent contentEvent)
    {
        return new InitializerSettings
        {
            Events = Events.Union(new [] {contentEvent})
        };
    }
}

public class Initializer
{
    private readonly IContentEvents _contentEvents;
    private readonly ContentEventLogger _logger;

    public Initializer(
        IContentEvents contentEvents,
        ContentEventLogger logger)
    {
        _contentEvents = contentEvents ?? throw new ArgumentNullException(nameof(contentEvents));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public void Initialize(InitializerSettings settings)
    {
        foreach (var contentEvent in settings.Events)
        {
            Subscribe(contentEvent);
        }
    }

    private void Subscribe(ContentEvent contentEvent)
    {
        switch (contentEvent)
        {
            case ContentEvent.Created:
                _contentEvents.CreatedContent += _contentEvents_CreatedContent;
                break;
            case ContentEvent.Published:
                _contentEvents.PublishedContent += _contentEvents_PublishedContent;
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(contentEvent), contentEvent, null);
        }
    }

    private void _contentEvents_PublishedContent(object sender, ContentEventArgs e)
    {
        _logger.Log("Published", e);
    }

    private void _contentEvents_CreatedContent(object sender, ContentEventArgs e)
    {
        _logger.Log("Created", e);
    }
}
```

By calling _Initialize_ and providing settings, we can attach to different (or multiple) events. As with dependency injection configuration, we can add a helper extension method. Notice that for this extension method I used _Use_ prefix. Also, same as in _ASP.NET Core_.

```csharp
public static void UseContentEventLogger(
  this InitializationEngine context, Func<InitializerSettings, InitializerSettings> configure)
{
  var settings = configure(new InitializerSettings());

  var initializer = context.Locate.Advanced.GetInstance<Initializer>();
  initializer.Initialize(settings);
}
```

Besides, do not forget to register our initializer in a container with _AddContentEventLogger_ extension method.

```csharp
public static void AddContentEventLogger(
  this ServiceConfigurationContext context, Func<LoggerSettings, LoggerSettings> configure)
{
  var settings = configure(new LoggerSettings());

  context.Services.AddSingleton(settings);
  context.Services.AddSingleton<ContentEventLogger>();

  context.Services.AddSingleton<Initializer>();
}
```

Once this is done, the user can attach to the different events in their _IInitializableModule_.

```csharp
 public void Initialize(InitializationEngine context)
{
  context.UseContentEventLogger(
      x => x
          .SubscribeTo(ContentEvent.Created)
          .SubscribeTo(ContentEvent.Published));
}
```

## Summary

Providing configuration options for your library users is important. However, it is also important to have a good API. By following _ASP.NET Core_ example, we can create nice configuration API for _Episerver_ too.

For the full example, check [GitHub](https://github.com/marisks/examples/tree/master/ContentEventLogger).

\# configuring!