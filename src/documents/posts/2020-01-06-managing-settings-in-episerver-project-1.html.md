---
layout: post
title: "Managing settings in Episerver project - part 1"
description: >
  <t render="markdown">
  When developing the Episerver site, you usually need to store and use some settings. In this article, I will describe the most commonly used approaches for it.
  </t>
category:
tags: [EPiServer]
date: 2020-01-06
visible: true
---

# appSettings in Web.config

In the ASP.NET world (.NET Framework, not Core), the most common place for settings is the `appSettings` section in the _Web.config_ file. You can configure solution-wide settings here. It is possible to add transformations for different environments where you are deploying the application.

Also, you can add "partial" settings in a separate file. This is useful when each developer has their own settings. Just add the "partial" file to the `.gitignore`, and in the _Web.config_ on the _appSettings_ tag, add `file` attribute that points to your "partial" settings file.

```xml
<appSettings file="appSettings.dev.config">
  <add key="MySetting" value="The configuration">
</appSettings>
```

Once you configured your application, you can retrieve settings using `ConfigurarionManager`.

```csharp
var mySetting = ConfigurationManager.AppSettings["MySetting"];
```

It returns a string value. If you need another type, you have to cast to it.

## Pros

- Built-in ASP.NET feature.
- Easy to use.
- Transformations allow creating separate setting values for different environments.

## Cons

- Unable to change values in runtime. Requires re-deploy.
- By default, everything is a string. You need to cast to other types.
- Unable to store complex types without serializing to some string format (comma-separated strings, XML, JSON).


# Custom settings section in Web.config

A custom settings section is a good alternative to `appSettings`. It is harder to implement and use, but has several benefits over `appSettings`. With it, you do not mix your settings with other application settings.

I will not cover creating a custom configuration section here, but Joel Abrahamsson has a excellent article about it: [Creating a custom Configuration Section in .NET](http://joelabrahamsson.com/creating-a-custom-configuration-section-in-net/).

## Pros

- Built-in ASP.NET feature.
- Separates your settings from other application settings.
- Transformations allow creating separate setting values for different environments.
- You can create complex types using configuration Elements and Collections.

## Cons

- More complex implementation and usage than `appSettings`.
- Unable to change values in runtime. Requires re-deploy.
- Properties of the configuration are still just strings, and you need to cast those to other types.


# Settings on the Start page

It is quite common to use a start page as setting storage in Episerver projects. You can add properties on the start page and configure it to display on the separate tab.

```csharp
[Display(GroupName = GroupNames.Settings, Order = 100)]
public virtual ContentReference MyLink { get; set; }
```

Then you can use Episerver API to load the start page and use the setting.

```csharp
var startPage = _contentLoader.Get<StartPage>(ContentReference.StartPage);
var myLink = startPage.MyLink;
```

When using a start page, you can define properties of any type Episerver has support. You can use integers, strings, content references, or even use blocks for complex types. A full list of supported types can be found here: [Built-in property types](https://world.episerver.com/documentation/developer-guides/CMS/Content/Properties/built-in-property-types/).

Another advantage of using the start page is UI. You can easily change settings by opening the start page, changing settings, and then publishing the page. For example, it can be used for "feature switching" to enable/disable some functionality on the site.

## Pros

- Easy to use Episerver API.
- Multi-language settings.
- It can be changed in runtime.
- Configure from UI.

## Cons

- Environment specific configuration should be configured manually in each environment.
- The start page is not specifically built for settings.


# Summary

As you see in this article, each approach for storing and using settings has its advantages and disadvantages. So all approaches also have their use cases.

`appSettings` and custom configuration sections are great for a configuration that differs by the environment. Also, you would not want to setup settings that often change in `Web.config`. So this is the right place for settings that are required for 3rd party API integration, some connection details, etc.

The start page can be used for settings that you might change often or should be changed at runtime. As I mentioned previously, it is the right place for "feature switching." Also, you would not want to setup settings on the start page when you need those different in different environments.

The right decision where and how to store settings should be made by a project team depending on requirements.

In the next article, I will describe other options you can use and better organize settings in Episerver.
