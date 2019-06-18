---
layout: post
title: "Promotion exclusion levels in Episerver Commerce"
description: >
  <t render="markdown">
  Recently I received a question from a customer regarding combining different discounts. They had an issue that a discount with a bigger discount value was overridden by another discount which was applied with a coupon code. We were trying different combinations to enable such discounts without any luck and then asked Episerver support for help.
  </t>
category:
tags: [EPiServer]
date: 2019-06-18
visible: true
---

# The issue

We have item level discounts on two categories where one category has a 30% discount and the second one has a 50% discount. Then we defined an order level discount of 40% when a coupon code is applied. The order of discounts is 50% -> 40% -> 30%.

When we tried to add products from both categories and then apply a coupon code, we got a validation error that it is an invalid discount combination.

# The research and the solution

Episerver support sent us a _Quicksilver_ example where this setup worked but with a small difference - 40% discount was an item level discount. We tried to re-create the same setup, but it still did not work.

After some research, I found that Episerver support changed Quicksilver code, which applies discounts. They have changed the exclusion level from `Order` to `Unit` when calling `ApplyDiscounts` on the cart.

```csharp
cart.ApplyDiscounts(_promotionEngine, new PromotionEngineSettings
{
    ExclusionLevel = ExclusionLevel.Unit
});
```

The default value for `ExclusionLevel` is `Order`. So the combination we tried to apply didn't work. Strangely, this is a default value as such discount combinations are common in e-commerce solutions.

So if you need control of combining different discounts on item level, always use `ExclusionLevel.Unit`.

Thanks to Cuong Phan from Episerver support for help!