---
layout: post
title: "Episerver Commerce 11 to 12 upgrade market breaking changes"
description: >
  <t render="markdown">
  Lately, I was upgrading several projects from Episerver Commerce 11 to version 12. During the upgrade, I have noticed that there are some breaking changes regarding markets.
  </t>
category:
tags: [EPiServer]
date: 2018-05-31
visible: true
---

Episerver has made the _Market_ property on _IOrderGroup_ obsolete. If you are using it, you will see this warning message:

```text
'IOrderGroup.Market' is obsolete: 'This property is no longer used. Use IMarketService to get the market from MarketId instead. Will remain at least until May 2019.'
```

At first, you are tempted to ignore it and fix later as this is just obsolete. You expect it to work as before for some time. However, this is a breaking change you will notice in runtime. The _Market_ property will be null.

So fix all warnings related to this property and use _IMarketService_ to get the market you need:

```csharp
private readonly IMarketService _marketService;

public ProductController(IMarketService marketService)
{
    _marketService = marketService;
}

private void Run(ICart cart)
{
    var market = _marketService.GetMarket(cart.MarketId);
}
```

Episerver has documented all breaking changes here: [Breaking changes in Commerce 12](https://world.episerver.com/documentation/upgrading/episerver-commerce/commerce-12/breaking-changes-commerce-12/).