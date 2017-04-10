---
layout: post
title: "Manual order discount"
description: >
  <t render="markdown">
  Last week I had a requirement to implement a manual order discount which can be set on any cart by the administrator/editor. I found that there is a manual discount for line items in the Commerce Manager and found how to use those in my code. When I tried to implement it the same way for the order discount, then [it didn't work](http://world.episerver.com/forum/developer-forum/Episerver-Commerce/Thread-Container/2017/4/how-to-add-manual-order-promotion/). The order discount requires a different approach which is described in this article.
  </t>
category:
tags: [EPiServer]
date: 2017-04-09
visible: true
---

NOTE: If you need a manual line item discount, then look at [this forum thread](http://world.episerver.com/forum/developer-forum/Episerver-Commerce/Thread-Container/2017/4/how-to-add-manual-order-promotion/).

An administrator or editor should be able to apply an order discount by amount or percentage. For this reason, you need to store a discount value and a discount type - amount or percentage somewhere. Order (including a cart) has a feature of meta-data which is the best place to add those values.

The first step is the creation of the meta-field and assigning it to a cart. You also should add that meta-field to the purchase order and copy values from the cart to the purchase order on a checkout. This way you will be able to track what discount was applied.

```
[InitializableModule]
[ModuleDependency(typeof(EPiServer.Web.InitializationModule))]
public class Initialization : IInitializableModule
{
    public void Initialize(InitializationEngine context)
    {
        CreateMetaField(new MetaFieldInfo(Constants.ManualDiscountValueMetaField, MetaDataType.Decimal)
        {
            FriendlyName = "Manual discount value",
            IsNullable = true
        });

        AddFieldToMetaClass(OrderContext.Current.ShoppingCartMetaClass, GetMetaField(Constants.ManualDiscountValueMetaField));
        AddFieldToMetaClass(OrderContext.Current.PurchaseOrderMetaClass, GetMetaField(Constants.ManualDiscountValueMetaField));

        CreateMetaField(new MetaFieldInfo(Constants.ManualDiscountTypeMetaField, MetaDataType.ShortString)
        {
            FriendlyName = "Manual discount type",
            IsNullable = true
        });

        AddFieldToMetaClass(OrderContext.Current.ShoppingCartMetaClass, GetMetaField(Constants.ManualDiscountTypeMetaField));
        AddFieldToMetaClass(OrderContext.Current.PurchaseOrderMetaClass, GetMetaField(Constants.ManualDiscountTypeMetaField));
    }

    public void Uninitialize(InitializationEngine context)
    {
    }

    private void AddFieldToMetaClass(MetaClass metaClass, MetaField metaField)
    {
        if (metaClass.MetaFields.Any(x => x.Name == metaField.Name))
        {
            return;
        }

        metaClass.AddField(metaField);
    }

    private MetaField GetMetaField(string name)
    {
        var metaContext = OrderContext.MetaDataContext;
        return MetaField.GetList(metaContext).FirstOrDefault(x => x.Name == name);
    }

    private void CreateMetaField(MetaFieldInfo fieldInfo)
    {
        var metaContext = OrderContext.MetaDataContext;
        if (MetaField.GetList(metaContext).Any(x => x.Name == fieldInfo.Name))
        {
            return;
        }

        MetaField.Create(
            metaContext,
            fieldInfo.MetaNamespace,
            fieldInfo.Name,
            fieldInfo.FriendlyName,
            fieldInfo.Description,
            fieldInfo.MetaFieldType,
            fieldInfo.Length,
            fieldInfo.IsNullable,
            fieldInfo.IsMultiLanguage,
            fieldInfo.IsSearchable,
            fieldInfo.IsEncrypted);
    }

    private class MetaFieldInfo
    {
        public MetaFieldInfo(string name, MetaDataType metaFieldType)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));
            Name = name;
            MetaFieldType = metaFieldType;
            FriendlyName = name;
        }

        public string Name { get; }
        public string MetaNamespace { get; set; } = string.Empty;
        public string FriendlyName { get; set; }
        public string Description { get; set; } = string.Empty;
        public MetaDataType MetaFieldType { get; }
        public bool IsNullable { get; set; }
        public int Length { get; set; }
        public bool IsMultiLanguage { get; set; }
        public bool IsSearchable { get; set; }
        public bool IsEncrypted { get; set; }
    }
}
```

Here I am using _MetaFieldInfo_ private class to simplify meta-field creation by requiring to provide just basic info. Another code is pretty simple - it adds a meta field to the _Commerce_ and assigns it to the meta-class.

After meta-fields are created, create a user interface which allows administrators to set this discount. Then save posted values in the cart.

```
var cart = _orderRepository.LoadOrCreateCart<ICart>(customerId, Constants.CartName);
cart.Properties[Constants.ManualDiscountValueMetaField] = discount;
cart.Properties[Constants.ManualDiscountTypeMetaField] = discountType.ToString();
cart.ApplyDiscounts(_promotionEngine, new PromotionEngineSettings());
_orderRepository.Save(cart);
```

In this example, I am loading a cart by customer _Id_, then setting meta-field values on the _Properties_ property and saving the cart. But before the cart saves, you should call _ApplyDiscounts_ extension method which will re-calculate all the discounts applied to the cart.

_DiscountType_ in this example is just an _Enum_ with two values - _Amount_ and _Percent_.

For easier access to the meta-fields, create helper extension methods.

```
public static class ExtendedPropertiesExtensions
{
    public static DiscountType GetManualDiscountType(this IExtendedProperties container)
    {
        var typeString = container.Properties[Constants.ManualDiscountTypeMetaField]?.ToString() ?? string.Empty;
        DiscountType discountType;
        return Enum.TryParse(typeString, true, out discountType) ? discountType : DiscountType.Amount;
    }

    public static decimal GetManualDiscount(this IExtendedProperties container)
    {
        return (decimal)(container.Properties[Constants.ManualDiscountValueMetaField] ?? 0.0m);
    }
}
```

Now there is everything set up to be able to create discount processing.

```
[ContentType(
    DisplayName = "Order manual discount",
    Description = "A discount used by administrators to set on the cart order in the Cart module.",
    GUID = "AD1403E8-5545-4F5A-A52A-0A21215435CA")]
public class ManualOrderDiscountPromotion : OrderPromotion
{
}

public class ManualOrderDiscountPromotionProcessor : OrderPromotionProcessorBase<ManualOrderDiscountPromotion>
{
    protected override RewardDescription Evaluate(
        ManualOrderDiscountPromotion promotionData,
        PromotionProcessorContext context)
    {
        var orderForm = context.OrderForm;
        var cart = context.OrderGroup as ICart;
        if (cart == null)
        {
            return NoReward(promotionData);
        }

        var value = cart.GetManualDiscount();
        if (value == 0)
        {
            return NoReward(promotionData);
        }

        switch (cart.GetManualDiscountType())
        {
            case DiscountType.Amount:
                return RewardDescription.CreateMoneyReward(
                    FulfillmentStatus.Fulfilled,
                    new[] { CreateRedemptionDescription(orderForm) },
                    promotionData,
                    value,
                    description: $"{value} amount discount applied to order");
            case DiscountType.Percent:
                return RewardDescription.CreatePercentageReward(
                    FulfillmentStatus.Fulfilled,
                    new[] { CreateRedemptionDescription(orderForm) },
                    promotionData,
                    value,
                    description: $"{value} % discount applied to order");
            default:
                throw new ArgumentOutOfRangeException();
        }
    }

    protected override bool CanBeFulfilled(
        ManualOrderDiscountPromotion promotionData,
        PromotionProcessorContext context)
    {
        var cart = context.OrderGroup as ICart;
        if (cart == null)
        {
            return false;
        }

        return cart.GetManualDiscount() != 0;
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

    protected override PromotionItems GetPromotionItems(ManualOrderDiscountPromotion promotionData)
    {
        return new PromotionItems(
            promotionData,
            new CatalogItemSelection(null, CatalogItemSelectionType.All, true),
            new CatalogItemSelection(null, CatalogItemSelectionType.All, true));
    }
}
```

First of all, define an order promotion for the manual order discount. There is no need for any meta-data - so no properties needed.

Then create a promotion processor. Do not apply a promotion when an order is not a cart and when the discount value is zero. For an amount discount and a percentage discount, you should call two different methods to create a reward - _RewardDescription.CreateMoneyReward_ and _RewardDescription.CreatePercentageReward_.

The last step - create a special campaign and a discount with this new type in a _Commerce -> Marketing_ section.