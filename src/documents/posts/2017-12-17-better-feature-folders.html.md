---
layout: post
title: "Better feature folders"
description: >
  <t render="markdown">
  Previously, I wrote an article how to create a [Razor view engine which supports feature folders](/2017/02/03/razor-view-engine-for-feature-folders/). This view engine had one drawback.
  </t>
category:
tags: [EPiServer]
date: 2017-12-17
visible: true
---

The view engine I described previously required view names to be unique across the solution. For example, you could not have view name "Index.cshtml," but had to use a controller name as a prefix like "HomeIndex.cshtml." It is not very handy.

There is a better way how to resolve views for controllers. I have created a view engine which resolves views by controller path (namespace). I found an [article by Imran Baloch](https://weblogs.asp.net/imranbaloch/view-engine-with-dynamic-view-location) which led me in the right direction.

I have created a NuGet package available it.

```powershell
Install-Package FeaturesViewEngine
```

The package contains one base class which could be used for your custom view resolution and another class with the default implementation.

The default view engine - _DefaultControllerFeaturesViewEngine_ resolves paths relative to the controller in three locations:

```text
%feature%/{0}.cshtml
%feature%/Views/{0}.cshtml
%feature%/Views/{1}{0}.cshtml
```

Here _{0}_ is an action name and _{1}_ is a controller name as usual. But _%feature%_ is a custom placeholder which will be replaced by the path to the controller. The path is resolved by the controller's namespace, but it removes assembly name in front of the namespace. For example, you have an assembly _My.Web_ which has a controller like this:

```csharp
namespace My.Web.Features.Home
{
    public class HomeController : Controller
    {
    }
}
```

Then the path to the controller's feature will be _Features/Home_. It removes _My.Web_ from the path.

If you have different view paths relative to the controller, then you can implement your feature engine using the abstract _ControllerFeaturesViewEngine_ class as a base. You can take a default view engine as an example:

```csharp
public sealed class DefaultControllerFeaturesViewEngine : ControllerFeaturesViewEngine
{
    public DefaultControllerFeaturesViewEngine()
    {
        var paths = new[]
        {
            $"{FeaturePlaceholder}/{{0}}.cshtml",
            $"{FeaturePlaceholder}/Views/{{0}}.cshtml",
            $"{FeaturePlaceholder}/Views/{{1}}{{0}}.cshtml"
        };

        ViewLocationFormats =
            paths
                .Union(ViewLocationFormats)
                .ToArray();

        PartialViewLocationFormats =
            paths
                .Union(PartialViewLocationFormats)
                .ToArray();
    }
}
```

Create your view engine and modify the paths according to your needs. Here I am using _FeaturePlaceholder_ which is a constant of _%feature%_.

If you have a custom namespace prefix which doesn't match assembly name, then you can override the _NamespacePrefixToRemove_ method with your prefix override logic.

# Summary

This view engine allows having more flexibility when resolving views for controllers. But you have to remember to configure partial view resolving separately as described in [Razor view engine for feature folders](/2017/02/03/razor-view-engine-for-feature-folders/) article.

There is one drawback to this view engine I didn't mention. It disables view caching because of some restrictions of the base MVC Razor engine.