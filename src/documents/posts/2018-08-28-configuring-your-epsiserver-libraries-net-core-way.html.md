---
layout: post
title: "Configuring your Episerver libraries .NET Core way"
description: >
  <t render="markdown">
  Quite often when you develop a library, you need to run some initialization code or allow a library user to configure your it. Usually, developers add initializable modules in their libraries and use settings from Web.config to configure their libraries. However, these approaches have some drawbacks.
  </t>
category:
tags: [EPiServer]
date: 2018-08-28
visible: true
---

# Drawbacks of initializable modules and configuration settings

The main drawback of initializable modules in libraries is that a library user cannot control when an initializable module is called. The user might want to disable initialization code too.

Another drawback is the startup time. Episerver scans for initializable modules, and it will take slightly more time to find and run those. If each small library would have an initializable module, then a more significant project which uses several libraries might be slow at startup.

Putting configuration settings in the Web.config forces to use only one way of configuration. If a developer wants to retrieve a configuration from another source (for example, database), then there is no way to do it. Also, in the future when we will get to .NET Core in Episerver, the library which forces usage of Web.config will not work anymore.

# The new way

First of all, the configuration should be done in the code. This allows a developer to choose the source of configuration. In the simplest form, it is hardcoded in the code.

_ASP.NET Core_ has an excellent example of how to achieve it. It uses [ConfigureServices](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/startup?view=aspnetcore-2.1#the-configureservices-method) method for IoC configuration and [Configure](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/startup?view=aspnetcore-2.1#the-configure-method) method for request handling (and other) configuration.

In _Episerver_, we have two similar extension points - [IConfigurableModule](https://world.episerver.com/documentation/developer-guides/CMS/initialization/dependency-injection/) for IoC configuration and [IInitializableModule](https://world.episerver.com/documentation/developer-guides/CMS/initialization/) for other initialization code. Previously, we used to create own _IConfigurableModule_ and _IInitializableModule_ in our libraries, but instead, we should allow our library users to call library configuration code in their modules.

The usage of an imaginable library's - _MyLibrary_ configuration might look like this:

```csharp
[InitializableModule]
public class IoCModule : IConfigurableModule
{
  public void ConfigureContainer(ServiceConfigurationContext context)
  {
    context.AddMyLibrary();
  }
  public void Initialize(InitializationEngine context)
  {
  }
  public void Uninitialize(InitializationEngine context)
  {
  }
}

[InitializableModule]
[ModuleDependency(
  typeof(EPiServer.Web.InitializationModule),
  typeof(EPiServer.Commerce.Initialization.InitializationModule))]
public class AppInitialization : IInitializableModule
{
  public void Initialize(InitializationEngine context)
  {
    context.UseMyLibrary(settings => {
      settings.MyProperty = 20;
      return settings;
    });
  }

  public void Uninitialize(InitializationEngine context)
  {
  }
}
```

Here I am using the same naming as in _ASP.NET Core_ - _IoC_ configuration extension methods start with _Add_ and configuration methods in an initializable module start with _Use_. In the initializable module, you will have an option to configure the library by passing an action with settings configuration as a parameter.

An extension for IoC configuration is simple. It just registers your classes in an IoC container.

```csharp
public static class IoCExtensions
{
  public static void AddMyLibrary(this ServiceConfigurationContext context)
  {
    context.Services.AddTransient<IService, Service>();
  }
}
```

An extension with configuration is a little bit more complicated. First of all, you will need a settings class. You can add default settings in the constructor.

```csharp
public class MySettings
{
  public MySettings()
  {
    MyProperty = 10;
  }
  public int MyProperty { get; set; }
}
```

Next, you need a class as an entry point for your library initialization. This class is responsible for passing settings to an appropriate destination. It could be some context class, storing in a database, passing settings to the service classes, etc.

```csharp
public class MyLibraryInitializer
{
  IService _service;

  public MyLibraryInitializer(IService service, IService2 service2 ...)
  {
    _service = service;
  }

  public void Initialize(MySettings settings)
  {
    _service.AddMyProperty(settings.MyProperty);
  }
}
```

Now you can create an extension. This extension is just responsible for passing configured settings to the initializer.

```csharp
public static class InitializationExtensions
{
  public static void UseMyLibrary(this this InitializationEngine context, Func<MySettings, MySettings> configure)
  {
    var settings = new MySettings();
    settings = configure(settings);

    var initializer = context.Locate.Advanced.GetInstance<MyLibraryInitializer>();
    initializer.Initialize(settings);
  }
}
```

Now with this approach developers are free to choose how and when to call the initialization code of your library.