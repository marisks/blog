---
layout: post
title: "New Geta.NotFoundHandler"
description: >
  <t render="markdown">
  BVN.404Handler and Geta.404Handler are re-released as Geta.NotFoundHandler. The new library supports ASP.NET 5 and Optimizely 12.
  </t>
category:
tags: [EPiServer,Optimizely]
date: 2021-11-04
visible: true
---

# The new name - Geta.NotFoundHandler

We have changed the name of the package again. The reason for this is that the old name was inconsistent throughout the code. The assembly name was `Geta.404Handler`, but namespaces started with `Geta.NotFoundHandler`. We could have changed namespaces to have `404Handler` in the name, but namespaces' parts in .NET can't start with a number.

# ASP.NET 5 and Optimizely

After reviewing the library, we found that it was not so dependent on *Optimizely* (*Episerver*). So we refactored the library that supports ASP.NET 5 and added administrative UI integration in *Optimizely*. Now there are three separate packages:
- `Geta.NotFoundHandler` - the core library for ASP.NET 5.
- `Geta.NotFoundHandler.Admin` - the administrative UI.
- `Geta.NotFoundHandler.Optimizely` - a module that integrates administrative UI in Optimizely UI.

# Getting started in ASP.NET

In an ASP.NET 5 project install `Geta.NotFoundHandler.Admin` and in the `Startup.ConfigureServices` method configure the *NotFoundHandler*. You have to provide a connection string at least.

```
public void ConfigureServices(IServiceCollection services)
{
    var connectionString = ... // Retrieve connection string here
    services.AddNotFoundHandler(o =>
    {
        o.UseSqlServer(connectionstring);
    });
}
```

By default, users in the *Administrators* role will have access to the administration UI. You can change the default policy in the configuration:

```
public void ConfigureServices(IServiceCollection services)
{
    var connectionString = ... // Retrieve connection string here
    services.AddNotFoundHandler(o =>
    {
        o.UseSqlServer(connectionstring);
    }, policy =>
    {
        policy.RequireRole("MyRole");
    });
}
```

Next, initialize *NotFoundHandler* in the `Configure` method as the first registration. It will make sure that the handler will catch all 404 errors.

```
public void Configure(IApplicationBuilder app)
{
    app.UseNotFoundHandler();
}
```

Now you should be able to access administrative UI by `https://mysite/Geta.NotFoundHandler.Admin`.

<img src="/img/2021-11/redirects.png" class="img-responsive" alt="">

# Getting started in Optimizely

In an Optimizely project install `Geta.NotFoundHandler.Optimizely` package. Then configure the handler in `Startup.ConfigureServices` method. Set the connection string and add access for the CMS administrators.

```
public void ConfigureServices(IServiceCollection services)
{
    var connectionString = ... // Retrieve connection string here
    services.AddNotFoundHandler(o =>
    {
        o.UseSqlServer(connectionString);
    }, policy =>
    {
        policy.RequireRole(Roles.CmsAdmins);
    });
    services.AddOptimizelyNotFoundHandler();
}
```

As in the ASP.NET case, initialize *NotFoundHandler* in the `Configure` method as the first registration.

```
public void Configure(IApplicationBuilder app)
{
    app.UseNotFoundHandler();
}
```

Run the application and in the *Optimizely* administrative UI you will find a link to the *NotFounHandler* administrative UI in the top menu.

<img src="/img/2021-11/optimizely-redirects.jpg" class="img-responsive" alt="">

# Summary

*NotFoundHandler* now is ready for use in the new *Optimizely* 12, but if you are using older versions of *Optimizely/Episerver*, then we will still support those as [Geta.404Handler](https://github.com/Geta/404handler).

The source code and documentation for the new *NotFoundHandler* is available on [GitHub](https://github.com/Geta/geta-notfoundhandler).
