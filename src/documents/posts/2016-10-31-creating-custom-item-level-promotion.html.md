---
layout: post
title: "Creating custom item level promotion"
description: "Some time ago I wrote an article how to create an order level promotion. In this article, I will describe how to create an item (entry) level promotion."
category:
tags: [EPiServer]
date: 2016-10-31
visible: true
---

<p class="lead">
Some time ago I wrote an article how to create <a href="http://marisks.net/2016/05/31/episerver-marketing-beta-creating-custom-order-promotion-update/">an order level promotion</a>. In this article, I will describe how to create an item (entry) level promotion.
</p>

In this example, I will show how to create entry level promotion based on a line item meta field - applying a discount when line item meta field discount value matches a discount value defined in the promotion.

First of all, define promotion. This promotion has one property with a discount percentage which to apply. Entry level promotion should inherit from _EntryPromotion_ class.

```
[ContentType(
	DisplayName = "Additional Item Discount promotion",
	GUID = "6F65BF90-542F-44A7-98D5-2FCA8A4FDF00")]
public class AdditionalItemDiscountPromoData : EntryPromotion
{
	[Display(Name = "Discount %")]
	public virtual decimal DiscountPercent { get; set; }
}
```

Next, define promotion processor. It should inherit from _EntryPromotionProcessorBase_ with type parameter of our promotion - _AdditionalItemDiscountPromoData_.

```
public class AdditionalItemDiscountPromoProcessor
      : EntryPromotionProcessorBase<AdditionalItemDiscountPromoData>
```

As in order promotion, it requires overriding several methods - _Evaluate_, _CanBeFulfilled_ and _GetPromotionItems_. _Evaluate_ method is the main place to put your promotion logic.

```
protected override RewardDescription Evaluate(
    AdditionalItemDiscountPromoData promotionData,
    PromotionProcessorContext context)
{
    var orderForm = context.OrderForm;
    var lineItems = GetLineItems(orderForm)
                        .Where(item => HasDiscount(item, promotionData.DiscountPercent))
                        .ToArray();

    var affectedCodes = lineItems.Select(x => x.Code);
    var totalQuantity = lineItems.Sum(x => x.Quantity);
    var affectedEntries = context.EntryPrices.ExtractEntries(affectedCodes, totalQuantity);

    return RewardDescription.CreatePercentageReward(
        FulfillmentStatus.Fulfilled,
        new[] { CreateRedemptionDescription(affectedEntries) },
        promotionData,
        promotionData.DiscountPercent,
        description: $"{promotionData.DiscountPercent} % discount applied to line items");
}
```

This _Evaluate_ method gets those line items which has discount defined in the line item's meta field. The base class provides method _GetLineItems_ which helps to get line items from the order form. The order form can be retrieved from context which is injected into an _Evaluate_ method. Then line items get filtered with _HasDiscount_ method to get items which contain discount. _HasDiscount_ method is a custom method described later.

Next step is getting _affected entries_. This is a very important step - the only way to get affected entries is by using context's _EntryPrices_ property's _ExtractEntries_ method. When I tried to create item level promotion the first time, I didn't know that and created affected entries manually and it failed.

The last step is creating a reward. In this case, it is a percentage reward but it could be also an amount reward. _RewardDescription_ class has factory method - _CreatePercentageReward_ which helps to create one. It needs several parameters which are quite straight forward. Only redemption description list parameter should be constructed by calling _CraeteRedemptionDescription_ factory method from the base class.

_HasDiscount_ method is simple. It just checks if discount percent on the line item matches promotion discount percent.
```
private static bool HasDiscount(ILineItem item, decimal discountPercent)
{
    var itemDiscountPercent =
        (decimal) (item.Properties[Constants.AdditionalDiscountPercentMetaField] ?? 0.0m);
    return itemDiscountPercent == discountPercent;
}
```

Next method to override from the base class is _CanBeFulfilled_.
```
protected override bool CanBeFulfilled(
    AdditionalItemDiscountPromoData promotionData,
    PromotionProcessorContext context)
{
    var orderForm = context.OrderForm;
    var lineItems = GetLineItems(orderForm);
    return lineItems.Any(item => HasDiscount(item, promotionData.DiscountPercent));
}
```

_CanBeFulfilled_ should return true or false if discount should be applied. In this case it checks if there are any affected line items.

In the _GetPromotionItems_ method as in an order promotion, it is possible to define for which items to apply for a promotion. In this case, it just applied the promotion to all items.
```
protected override PromotionItems GetPromotionItems(AdditionalItemDiscountPromoData promotionData)
{
    return new PromotionItems(
        promotionData,
        new CatalogItemSelection(null, CatalogItemSelectionType.All, true),
        new CatalogItemSelection(null, CatalogItemSelectionType.All, true));
}
```

Here is the full example:
```
[ContentType(
    DisplayName = "Additional Item Discount promotion",
    GUID = "6F65BF90-542F-44A7-98D5-2FCA8A4FDF00")]
public class AdditionalItemDiscountPromoData : EntryPromotion
{
    [Display(Name = "Discount %")]
    public virtual decimal DiscountPercent { get; set; }
}

public class AdditionalItemDiscountPromoProcessor
    : EntryPromotionProcessorBase<AdditionalItemDiscountPromoData>
{
    protected override RewardDescription Evaluate(
        AdditionalItemDiscountPromoData promotionData,
        PromotionProcessorContext context)
    {
        var orderForm = context.OrderForm;
        var lineItems = GetLineItems(orderForm)
                            .Where(item => HasDiscount(item, promotionData.DiscountPercent))
                            .ToArray();

        var affectedCodes = lineItems.Select(x => x.Code);
        var totalQuantity = lineItems.Sum(x => x.Quantity);
        var affectedEntries = context.EntryPrices.ExtractEntries(affectedCodes, totalQuantity);

        return RewardDescription.CreatePercentageReward(
            FulfillmentStatus.Fulfilled,
            new[] { CreateRedemptionDescription(affectedEntries) },
            promotionData,
            promotionData.DiscountPercent,
            description: $"{promotionData.DiscountPercent} % discount applied to line items");
    }

    protected override bool CanBeFulfilled(
        AdditionalItemDiscountPromoData promotionData,
        PromotionProcessorContext context)
    {
        var orderForm = context.OrderForm;
        var lineItems = GetLineItems(orderForm);
        return lineItems.Any(item => HasDiscount(item, promotionData.DiscountPercent));
    }

    private static bool HasDiscount(ILineItem item, decimal discountPercent)
    {
        var itemDiscountPercent =
            (decimal) (item.Properties[Constants.AdditionalDiscountPercentMetaField] ?? 0.0m);
        return itemDiscountPercent == discountPercent;
    }

    protected override PromotionItems GetPromotionItems(AdditionalItemDiscountPromoData promotionData)
    {
        return new PromotionItems(
            promotionData,
            new CatalogItemSelection(null, CatalogItemSelectionType.All, true),
            new CatalogItemSelection(null, CatalogItemSelectionType.All, true));
    }
}
```

# Summary

Item level promotion creation is not hard but there are some hard to figure out APIs.

Why is it required to use _context.EntryPrices.ExtractEntries_ method to create affected entries while it would be better to create those ourselves? It would be easier to discover. _context.EntryPrices.ExtractEntries_ behind the scenes adds entries to some buffer. So if you create affected entries manually, it fails to get items from the buffer. It might be created for performance reasons but I think that it would be better to add items to that buffer after calling _Evaluate_ method based on provided affected entries. _context.EntryPrices.ExtractEntries_ also is against [Command-query separation](https://en.wikipedia.org/wiki/Command%E2%80%93query_separation) principle - it returns data and modifies state.

The purpose of the _CanBeFulfilled_ method is not easy to understand as you are returning fulfilment status anyway in the _Evaluate_ method.

I still do not understand the reason behind the _GetPromotionItems_ method. As I am returning affected entries already in _Evaluate_ method, why should I use _GetPromotionItems_ method? Also, how to implement it properly if I would want to return specific items?

While working with promotions got much easier, I think that there are a lot of work to improve the developer experience.
