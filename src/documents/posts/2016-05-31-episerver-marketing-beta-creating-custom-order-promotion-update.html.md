---
layout: post
title: "EPiServer Marketing [Beta] - creating custom order promotion (Update)"
description: "Last week I wrote an article about creating an order promotion with new EPiServer Marketing [Beta]. I haven't noticed the new version which came out last week and had some improvements in an API. This article describes changes in promotions for Commerce 9.16.0."
category:
tags: [EPiServer]
date: 2016-05-31
visible: true
---

<p class="lead">
Last week I wrote an article about creating an order promotion with new EPiServer Marketing [Beta]. I haven't noticed the new version which came out last week and had some improvements in an API. This article describes changes in promotions for Commerce 9.16.0.
</p>

Thanks to [@lunchin](http://marisks.net/2016/05/24/episerver-marketing-beta-creating-custom-order-promotion/#comment-2693609996) pointing me that new Commerce version came out with improvements.

So the changes. First of all, custom promotion processor should inherit proper base class:
- for _OrderPromotion_ use _OrderPromotionProcessorBase_,
- for _EntryPromotion_ use _EntryPromotionProcessorBase_,
- for _ShippingPromotion_ use _ShippingPromotionProcessorBase_.

Another change is that you are not able to new up new instances of _RedemptionDescription_, but instead, use base processor's method _CreateRedemptionDescription_.

Here is the same promotion I showed last week but updated to the latest version:

```
[ContentType(
    DisplayName = "Additional Discount promotion",
    GUID = "E6271950-DB98-4FE6-9626-CEFCBF46BE19")]
public class AdditionalDiscountPromoData : OrderPromotion
{
}

public class AdditionalDiscountPromoProcessor
    : OrderPromotionProcessorBase<AdditionalDiscountPromoData> // <-- Inherits from specific base
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
            new[] { CreateRedemptionDescription(orderForm) }, // <-- Changed RedemptionDescription initialization
            promotionData,
            additionalDiscountPercent,
            description: $"{additionalDiscountPercent} % discount applied to order as set by support staff");
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

# Summary

New API now ensures that promotions can be built only the right way - appropriate _RewardDescription_ for each promotion type.

But I am not sure that the change is good from the API correctness standpoint. All base classes implement _IPromotionProcessor_ interface and it's method _Evaluate_ returns _RewardDescription_ which requires _RedemptionDescription_ in the constructor. But _RedemptionDescription_ has an internal constructor and can't be created outside of _EPiServer's_ base classes. Because of that, no other _IPromotionProcessor_ interface implementations can be created. While it is unlikely that someone would like to create another base class for promotion processor, creating a stub implementation of it for unit tests is impossible now.
