---
layout: post
title: "Creating a simple coupon code discount"
description: "Coupon code discounts are one of the simplest discount types. All new EPiServer promotions can be configured to be applied with coupon code. In this article, I will show how to add a coupon code to an order and create a simple order discount using it."
category:
tags: [EPiServer]
date: 2016-10-21
visible: true
---
<p class="lead">
Coupon code discounts are one of the simplest discount types. All new EPiServer promotions can be configured to be applied with coupon code. In this article, I will show how to add a coupon code to an order and create a simple order discount using it.
</p>

Adding coupon codes to an order is simple. Actually, add the coupon code to the cart (which is a kind of order).

```
public void SetCuponCode(string cuponCode)
{
	if (string.IsNullOrEmpty(cuponCode))
	{
		return;
	}

	var orderForm = (IOrderForm) CartHelper.Cart.OrderForms.First();
	if (orderForm.CouponCodes.Contains(cuponCode))
	{
		return;
	}
	orderForm.CouponCodes.Add(cuponCode);
}
```

Coupon codes can be set on the cart's order form but as _CouponCodes_ property is defined as an explicit _IOrderForm_ interface implementation, the order form has to be cast to _IOrderForm_. Then add a coupon code to the _CouponCodes_ property if it is not already added.

Do not forget to run cart validation workflow and save changes.

```
OrderGroupWorkflowManager.RunWorkflow(CartHelper.Cart, OrderGroupWorkflowManager.CartValidateWorkflowName);
CartHelper.Cart.AcceptChanges();
```

Next step would be creating a coupon code field in the cart UI, post it to the cart controller, and use this method to set coupon codes.

Then editors will be able to create new discounts with coupon codes. The simplest discount type for that is _Discount off Total Order Value_.

<img src="/img/2016-10/discount_off_total_order.png" alt="Discount off Total Order Value option" class="img-responsive">

Set coupon code in the _Promotion code_ field.

<img src="/img/2016-10/promotion_code.png" alt="Coupon code field - promotion code" class="img-responsive">

And set what amount do get off of the total order value - percentage or the exact amount. Notice that _Spend at least_ has to be set too and it should be more than zero.

<img src="/img/2016-10/discount_off_total_order_value.png" alt="Off total order value fields" class="img-responsive">

Now simple coupon code discount is created and can be used on the site.
