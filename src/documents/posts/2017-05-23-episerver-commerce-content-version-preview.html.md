---
layout: post
title: "Episerver commerce content version preview"
description: >
  <t render="markdown">
  Episerver has preview functionality available in edit mode. It did not satisfy our customer. The customer wanted to see the page as it will be displayed when get published. But I found that Episerver has "hidden" feature which enables you to display concrete commerce content version.
  </t>
category:
tags: [EPiServer]
date: 2017-05-23
visible: true
---

_Episerver's_ _HierarchicalCatalogPartialRouter_ already supports the versioned content display. You just have to take a string representation of the content link wich has version info and append it to the URL by separating it with two commas. The URL will look like this:

```
http://mysite.com/mycatalogroot/mycatalog/mycategory/myproduct,,123_334_CatalogContent
```

But it will not work by default. Such URL works only when the _Episerver's_ context mode is "Edit" or "Preview". This can be set with a custom router. Such router can look like this:

```csharp
public class PreviewRouter : IPartialRouter<IContent, ContentVersion>
{
    public object RoutePartial(IContent content, SegmentContext segmentContext)
    {
        if (IsCommerce(segmentContext))
        {
            return RouteCommerce(segmentContext);
        }

        return null;
    }

    private static bool IsCommerce(SegmentContext segmentContext)
    {
        var commerceRegex = new Regex(@"[0-9]+[_][0-9]+[_]CatalogContent$");
        return commerceRegex.IsMatch(segmentContext.RemainingPath);
    }

    private static object RouteCommerce(SegmentContext segmentContext)
    {
        segmentContext.ContextMode = ContextMode.Preview;
        return null;
    }

    public PartialRouteData GetPartialVirtualPath(
        ContentVersion version,
        string language,
        RouteValueDictionary routeValues,
        RequestContext requestContext)
    {
        var contentLink = requestContext.GetContentLink();

        if (PageEditing.PageIsInEditMode)
        {
            return null;
        }

        return new PartialRouteData
        {
            BasePathRoot = contentLink,
            PartialVirtualPath = $"{version}/"
        };
    }
}
```

The main method whitch does the thing is _RoutePartial_. Basically, I am checking if the URL contains a content link to the commerce content and setting context mode to the _Preview_.

The last step is a registration of our router. It can be achieved in an initialization module.

```csharp
[InitializableModule]
[ModuleDependency(typeof(EPiServer.Commerce.Initialization.InitializationModule))]
public class PreviewInitialization : IInitializableModule
{
    public void Initialize(InitializationEngine context)
    {
        var partialRouter = context.Locate.Advanced.GetInstance<PreviewRouter>();
        RouteTable.Routes.RegisterPartialRouter(partialRouter);
    }

    public void Uninitialize(InitializationEngine context)
    {
    }
}
```

Now the URL with versioned commerce content should work.