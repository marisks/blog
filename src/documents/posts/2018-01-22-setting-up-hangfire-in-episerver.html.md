---
layout: post
title: "Setting up Hangfire in Episerver"
description: >
  <t render="markdown">
  [Hangfire](https://www.hangfire.io/) is a great tool for running tasks in the background. When working on the _Episerver_ _CMS_ and _Commerce_ projects, you have to send emails or run another background task quite often, and _Hangfire_ helps to achieve this reliably.
  </t>
category:
tags: [EPiServer]
date: 2018-01-22
visible: true
---

# Installation

For Episerver integration you will need the main package of _Hangfire_ and also _StructureMap_ integration package:

```powershell
Install-Package Hangfire
Install-Package Hangfire.StructureMap
```

# Configuration

First, add the base configuration to the _Owin_ startup class:

```csharp
GlobalConfiguration.Configuration
    .UseSqlServerStorage("EPiServerDB");
app.UseHangfireDashboard();
app.UseHangfireServer();
```

Here you are configuring the SQL Server connection string. I prefer to use the same DB as for _Episerver_, so am using _Episerver_ DB connection name. Then we are configuring default dashboard (default path - "/hangfire") and _Hangfire_ server to run in the same ASP.NET application.

## Dashboard authorization

By default, _Hangfire_ allows access to the dashboard only for local requests. But I wanted _Episerver_ admins to access it. For this purpose, you can implement a custom authorization filter:

```csharp
public class AdminAuthorizationFilter : IDashboardAuthorizationFilter
{
    public bool Authorize(DashboardContext context)
    {
        return PrincipalInfo.HasAdminAccess;
    }
}
```

Here I am using _Episerver's_ _PrincipalInfo_, and it's property - _HasAdminAccess_ to find out if a user has admin rights.

Then configure dashboard to use it:

```csharp
app.UseHangfireDashboard(
    "/hangfire",
    new DashboardOptions
    {
        Authorization = new[] {new AdminAuthorizationFilter()}
    });
```

When configuring additional options, you also have to provide a path to the dashboard.

## StructureMap configuration

You have to configure _Hangfire_ to support dependency injection in your background jobs. You can do it in the initializable module where you are setting up your IoC container:

```csharp
[ModuleDependency(typeof(ServiceContainerInitialization))]
[InitializableModule]
public class DependencyResolverInitialization : IConfigurableModule
{
    public void ConfigureContainer(ServiceConfigurationContext context)
    {
        // IoC configuration here

        Hangfire.GlobalConfiguration.Configuration.UseStructureMapActivator(context.StructureMap());
    }
}
```

While you can use _Hangfire_ by calling methods from the static _BackgroundJob_ class, I would suggest using _IBackgroundJobClient_ which is injected into your classes. By default, _StructureMap_ is not able to resolve it. So you have to add _IBackgroundJobClient_ to the _StructureMap_ configuration. Here is an example, how to configure it from the _StructureMap_ registry:

```csharp
For<IBackgroundJobClient>().Singleton().Use(() => new BackgroundJobClient());
```

## Dashboard integration in the Episerver Shell

I found only one solution to achieve it - display _Hangfire_ dashboard in the iframe. For this, you have to create a container page. As I am using MVC, the easiest way was by introducing a controller and _Razor_ view. The controller is very simple:

```csharp
public class HangfireCmsController : Controller
{
    public ActionResult Index()
    {
        return View();
    }
}
```

I have used the name of the controller "HangfireCms" so that it will not collide with dashboard URL.

Now we can add the view:

```html
@using EPiServer
@using EPiServer.Framework.Web.Mvc.Html
@using EPiServer.Framework.Web.Resources
@using EPiServer.Shell.Navigation

@{
    Layout = null;
}

<!DOCTYPE html>

<html>
<head runat="server">
    <meta name="viewport" content="width=device-width" />
    <title>Dashboard</title>

    @Html.Raw(ClientResources.RenderResources("ShellCore"))
    @Html.Raw(ClientResources.RenderResources("ShellWidgets"))
    @Html.Raw(ClientResources.RenderResources("ShellCoreLightTheme"))
    @Html.Raw(ClientResources.RenderResources("ShellWidgetsLightTheme"))
    @Html.Raw(ClientResources.RenderResources("Navigation"))
    @Html.CssLink(UriSupport.ResolveUrlFromUIBySettings("App_Themes/Default/Styles/system.css"))
    @Html.CssLink(UriSupport.ResolveUrlFromUIBySettings("App_Themes/Default/Styles/ToolButton.css"))
    <style>
        .iframe-container {
            width: 100%;
            height: 100%;
        }
        iframe {
            width:100%;
            height:100%;
        }
    </style>
</head>
<body class="claro">
@Html.Raw(Html.GlobalMenu())
<div class="iframe-container">
    <iframe src="/hangfire" title="Hangfire Dashboard">
        <p>Your browser does not support iframes.</p>
    </iframe>
</div>
</body>
</html>
```

Now, you can configure _Shell_ menus. Create a menu provider which has a new section for _Hangfire_ and sub-menu which points to the dashboard "wrapper" controller:

```csharp
[MenuProvider]
public class HangfireMenuProvider : IMenuProvider
{
    public IEnumerable<MenuItem> GetMenuItems()
    {
        var section =
            new SectionMenuItem("Hangfire", "/global/hangfire")
            {
                IsAvailable = request => PrincipalInfo.HasAdminAccess
            };

        var dashboard =
            new UrlMenuItem("Dashboard", "/global/hangfire/dashboard", "/hangfirecms")
            {
                IsAvailable = request => PrincipalInfo.HasAdminAccess
            };
        return new MenuItem[] { section, dashboard };
    }
}
```

The last step is removing "Back to the site" link on the dashboard as it is not needed. You can achieve it by _AppPath_ property of _DashboardOptions_ to _null_.

```csharp
app.UseHangfireDashboard(
    "/hangfire",
    new DashboardOptions
    {
        Authorization = new[] {new AdminAuthorizationFilter()},
        AppPath = null // Hide back to site link
    });
```

# Usage

The simplest case is fire and forget. Inject _IBackgroundJobClient_ in your code where you need it and call _Enqueue_ method to run the task:

```csharp
public class ReceiptController : Controller
{
    private readonly IBackgroundJobClient _jobClient;
    private readonly EmailClient _emailClient;

    public Events(EmailClient emailClient, IBackgroundJobClient jobClient)
    {
        _jobClient = jobClient ?? throw new ArgumentNullException(nameof(jobClient));
        _emailClient = emailClient ?? throw new ArgumentNullException(nameof(emailClient));
    }

    public ActionResult Index()
    {
        OrderReference orderLink = // obtain a purchase order link ...
        _jobClient.Enqueue(() => _emailClient.SendReceiptEmail(orderLink));
        return View();
    }
}
```

Make sure that you are passing only simple parameters to the method as those are serialized and stored in the database. Also, make sure that you are not using anything which depends on the web context (request, response, etc.) in the task code. In my example, _EmailClient_ should not depend on _HttpContext_ for instance.

For more examples, see [Hangfire documentation](http://docs.hangfire.io/en/latest/background-methods/index.html).