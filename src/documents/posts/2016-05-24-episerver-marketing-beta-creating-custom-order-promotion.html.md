---
layout: post
title: "EPiServer Marketing [Beta] - creating custom order promotion"
description: "Lately, I had to build a custom order promotion in one of our projects in Geta. We are using latest EPiServer Marketing features but unfortunately as it is in Beta still, its API changes quite often. I had to re-build my custom promotion already twice. In this article, I will describe how to build a custom order promotion with the latest EPiServer Commerce version (9.15.0)."
category:
tags: [EPiServer]
date: 2016-05-24
visible: true
---

<p class="lead">
Lately, I had to build a custom order promotion in one of our projects in Geta. We are using latest EPiServer Marketing features but unfortunately as it is in Beta still, its API changes quite often. I had to re-build my custom promotion already twice. In this article, I will describe how to build a custom order promotion with the latest EPiServer Commerce version (9.15.0).
</p>

In the new version of _EPiServer Marketing_, promotion is just _IContent_. It can be loaded with _IContentLoader_, modified with _IContentRepository_ etc.. There are several types of promotions. Below I defined simple _OrderPromotion_ which applies a discount to the whole order.

```
[ContentType(
        DisplayName = "Additional Discount promotion",
        GUID = "E6271950-DB98-4FE6-9626-CEFCBF46BE19")]
public class AdditionalDiscountPromoData : OrderPromotion
{
}
```

There are also other [types](http://world.episerver.com/documentation/Items/Developers-Guide/Episerver-Commerce/9/Marketing/discounts-beta/) of promotions - _EntryPromotion_ and _ShippingPromotion_.

Promotions are handled with promotion processors. For custom promotion, new promotion processor which inherits from _PromotionProcessorBase_ should be implemented.

```
public class AdditionalDiscountPromoProcessor : PromotionProcessorBase<AdditionalDiscountPromoData>
{
    protected override RewardDescription Evaluate(
        AdditionalDiscountPromoData promotionData,
        PromotionProcessorContext context)
    {
        var orderForm = context.OrderForm;
        var cart = context.OrderGroup as Cart;
        if (cart == null)
        {
            return NoReward(promotionData);
        }

        var additionalDiscountPercent = (decimal)(cart[Constants.AdditionalDiscountPercentMetaField] ?? 0.0m);
        if (additionalDiscountPercent == 0)
        {
            return NoReward(promotionData);
        }

        return RewardDescription.CreatePercentageReward(
            FulfillmentStatus.Fulfilled,
            new[] {new RedemptionDescription(new AffectedOrder(orderForm)) },
            promotionData,
            additionalDiscountPercent,
            description: $"{additionalDiscountPercent} % discount applied to order");
    }

    private RewardDescription NoReward(PromotionData promotionData)
    {
        return new RewardDescription(
                FulfillmentStatus.NotFulfilled,
                Enumerable.Empty<RedemptionDescription>(),
                promotionData,
                unitDiscount: 0,
                unitPercentage: 0,
                rewardType: RewardType.None,
                description: "No discount applied");
    }

    protected override PromotionItems GetPromotionItems(AdditionalDiscountPromoData promotionData)
    {
        return new PromotionItems(
            promotionData,
            new CatalogItemSelection(null, CatalogItemSelectionType.All, true),
            new CatalogItemSelection(null, CatalogItemSelectionType.All, true));
    }
}
```

Two methods should be implemented - _Evaluate_ and _GetPromotionItems_.

_Evaluate_ is used to calculate what promotion should be or should not be applied. In the example above I am checking if _AdditionalDiscountPercentMetaField_ is defined on the _Cart_. If it is not defined, I return _RewardDescription_ with status _NotFulfilled_. So no discount will be applied. But if it has discount value, _Fulfilled_ _RewardDescription_ gets returned.

When creating _RewardDescription_ correct sequence of _RedemptionDescription_ should be provided. For _OrderPromotion_ _RedemptionDescription_ should take _AffectedOrder_ parameter in the constructor. Other promotion types should use other _Affected*_ types - _AffectedItem_ for _EntryPromotion_ and _AffectedShipment_ for _ShippingPromotion_. These two should be used only for items which have discount. The previous version of _Marketing_ required _AffectedItem_ to be used for each line item in the order even if you used _OrderPromotion_.

Another method which should be implemented is _GetPromotionItems_ - this is a new method. As I understand, it defines _a query_ to look up for items to which discount might be applied. I do not know exactly how to build these _queries_ but in the provided example all items are defined as valid for promotion.

# Summary

It is really nice how _EPiServer_ simplified and improved promotion creation. But some parts of an API is quite hard to understand without documentation. For example, a relation between promotion types and _Affected*_ types. API should guide developer to use correct types.

I think that _GetPromotionItems_ should not be forced on but have a default implementation. 90% of the time all items will apply for promotion. Also, building of _queries_ should have a fluent interface so that API is easier to discover and use.
