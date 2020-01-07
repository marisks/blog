---
layout: post
title: "Getting promotion value from the order"
description: >
  <t render="markdown">
  Episerver provides a simple API to get an order's and line item's monetary discount value. Though sometimes you have to know more about the discount. I will show you how to get a percentage or monetary value from the promotions applied to the order.
  </t>
category:
tags: [EPiServer]
date: 2019-10-23
visible: true
---

`IOrderForm` has a property with all promotions applied to the order. Each promotion record provides information about the saved monetary amount, about the type of the reward, has a reference to the promotion data and more information. But it lacks information about the percentage value of promotion if a promotion's type is a percentage.

The only way to get the percentage value of the promotion is by loading the promotion by a reference and then getting its value.

```csharp
public static decimal GetDiscountValue(this PromotionInformation promotionInfo, IContentLoader contentLoader)
{
    if (promotionInfo.RewardType != RewardType.Percentage)
    {
        return promotionInfo.SavedAmount;
    }

    if (contentLoader.TryGet<PromotionData>(promotionInfo.PromotionGuid, out var promotion)
        && promotion is IMonetaryDiscount monetaryDiscount)
    {
        return monetaryDiscount.Discount.Percentage;
    }

    return promotionInfo.SavedAmount;
}
```

Here I have created an extension method to get the correct value based on a reward type. When the reward type is not a percentage, return saved amount value from the promotion. Otherwise, load the promotion and return percentage value. Only the promotion of `IMonetaryDiscount` can have a percentage value.

Now you can use this method to get a percentage or monetary value like this:

```csharp
public void WorkOnPromotionValue(IOrderForm orderForm, IContentLoader contentLoader)
{
    var promotion = orderForm.Promotions.First();
    var value = promotion.GetDiscountValue(contentLoader);

    if (promotion.RewardType == RewardType.Percentage)
    {
        var percentage = value;
        // Do some work with percentage ...
    }
    else
    {
        var money = value;
        // Do some work with money ...
    }
}
```

It would be much better if Episerver would store percentage value in the order too. Promotions might be removed, and it will not be possible to get the percentage value anymore. And promotions are removed quite often as too many promotions severely affect the site's performance when calculating discounted price.