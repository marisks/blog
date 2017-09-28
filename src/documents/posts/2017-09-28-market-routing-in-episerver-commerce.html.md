---
layout: post
title: "Market routing in Episerver Commerce"
description: >
  <t render="markdown">
  The most of the Episerver Commerce project examples (for example, [Quicksilver](https://github.com/episerver/Quicksilver/)) are using cookies to store selected market. The URL doesn't change which can cause several SEO issues. Crawlers are not able to index market specific content. If the market info could be included in the URL, it would solve most of these problems.
  </t>
category:
tags: [EPiServer]
date: 2017-09-28
visible: true
---

The solution to this problem is not trivial. There are some great articles about custom routing in _Episerver_ - [Custom routing for EPiServer content](http://joelabrahamsson.com/custom-routing-for-episerver-content/) and [Episerver segments explained, registering custom routes in Episerver](http://www.jondjones.com/learn-episerver-cms/episerver-developers-guide/episerver-routing/episerver-segments-explained-registering-custom-routes-in-episerver). But these articles do not have a complete solution for the market routing.

I wanted to make URLs to look like this: http://mysite.com/en/europe/products, where _europe_ is a market ID.

The first task is to create a special segment for the market.

```csharp
public class MarketSegment : SegmentBase
{
    private readonly IMarketService _marketService;
    private readonly ICurrentMarket _currentMarket;

    public const string SegmentName = "market";

    public MarketSegment(IMarketService marketService, ICurrentMarket currentMarket)
        : base(SegmentName)
    {
        if (marketService == null) throw new ArgumentNullException(nameof(marketService));
        if (currentMarket == null) throw new ArgumentNullException(nameof(currentMarket));
        _marketService = marketService;
        _currentMarket = currentMarket;
    }

    public override bool RouteDataMatch(SegmentContext context)
    {
        var segmentPair = context.GetNextValue(context.RemainingPath);
        var marketCode = segmentPair.Next;

        if (!string.IsNullOrEmpty(marketCode))
        {
            return ProcessSegment(context, segmentPair);
        }

        if (context.Defaults.ContainsKey(Name))
        {
            context.RouteData.Values[Name] = context.Defaults[Name];
            return true;
        }

        return false;
    }

    public override string GetVirtualPathSegment(RequestContext requestContext, RouteValueDictionary values)
    {
        var contentLink = requestContext.GetRouteValue("node", values) as ContentReference;
        if (ContentReference.IsNullOrEmpty(contentLink)) // Skips for non-content items.
        {
            return null;
        }

        var currentMarket = _currentMarket.GetCurrentMarket();
        return currentMarket.MarketId.Value.ToLower();
    }

    private bool ProcessSegment(SegmentContext context, SegmentPair segmentPair)
    {
        var marketCode = segmentPair.Next;
        var marketId = new MarketId(marketCode);
        var market = _marketService.GetMarket(marketId);
        if (market == null) return false;

        context.RouteData.Values[Name] = marketCode;
        context.RemainingPath = segmentPair.Remaining;

        _currentMarket.SetCurrentMarket(marketId);

        return true;
    }
}
```

Here the market segment inherits from the _SegmentBase_ class which provides default behavior. You have to override two methods - _RouteDataMatch_ and _GetVirtualPathSegment_. 

The _RouteDataMatch_ method is used for URL interpretation - here you check if your segment is found in the URL and do the actions based on the segment value. Here I am getting the next segment value which should be my market segment. The next segment depends on already parsed segments. As the first segment is used for language, the second one will be the market segment. If the segment has value, I am trying to interpret it. I am just checking if the market with such code exists. If it does, then I am setting the current market value. Additionally, I am adding market info to the _RouteData_.

The _GetVirtualPathSegment_ method is used to generate URL of content. Here you provide the value for your segment in the URL. In my case, it is checking if the content is _Episerver_ content and then returns a current market ID value. This value then will be presented in the URLs.

The next step requires some "hacking." I have to register my custom segment with a custom content route. But I must put it before any default _Episerver_ route. Otherwise, it will not be picked. By default, _Episerver_ has only one extension method for adding content routes - _MapContentRoute_. It appends the route at the end. So I have created an extension method to insert route at any position. I will not list it here as it is quite long, but you can find it on [Github](https://github.com/marisks/examples/blob/master/MarketRouting/Quicksilver/Sources/EPiServer.Reference.Commerce.Site/Features/Market/Routing/RouteCollectionExtensions.cs#L49).

Now register the segment and the custom route.

```csharp
public static void MapMarketSegment(this RouteCollection routes)
{
    var segment = new MarketSegment(MarketService, CurrentMarket);
    var segmentMappings = new Dictionary<string, ISegment> { { MarketSegment.SegmentName, segment } };
    var parameters = new MapContentRouteParameters
    {
        Direction = SupportedDirection.Both,
        SegmentMappings = segmentMappings
    };
    routes.InsertAndMapContentRoute(
        index: routes.IndexOf("pages"),
        name: MarketSegment.SegmentName,
        url: "{language}/{market}/{node}/{partial}/{action}",
        defaults: new { action = "index" },
        parameters: parameters);
}

public static int IndexOf(this RouteCollection routes, string name)
{
    var defaultRoute = routes
        .Select(r => r as DefaultContentRoute)
        .Where(x => x != null)
        .First(x => x.Name.Equals(name, StringComparison.InvariantCultureIgnoreCase));
    return routes.IndexOf(defaultRoute);
}
```

First, create a market segment and provide all the necessary services to it. Then create content route parameters with our segment. The last step is inserting the new content route. I have added it before the _pages_ route which is the default route for _Episerver_ content.

The last step is calling this _MapMarketSegment_ in the _Global.asax.cs_ on _RegisterRoutes_. Make sure to call it after base route registration.

```csharp
protected override void RegisterRoutes(RouteCollection routes)
{
    base.RegisterRoutes(routes);

    routes.MapRoute(
        name: "Default",
        url: "{controller}/{action}/{id}",
        defaults: new { action = "Index", id = UrlParameter.Optional });

    RouteTable.Routes.MapMarketSegment();
}
```

Now, you should be able to see markets in the URL and change the market by changing the market ID in the URL.

I have created an example project based on the Quicksilver. The project is available on [Github](https://github.com/marisks/examples/tree/master/MarketRouting).