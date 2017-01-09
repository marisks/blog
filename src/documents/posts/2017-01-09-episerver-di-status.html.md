---
layout: post
title: "Episerver Dependency Injection status"
description: "Episerver just released a new version which added a constructor injection support in scheduled jobs. It encouraged me to create a list of different Episerver infrastructure parts which still do not support a constructor injection."
category:
tags: [EPiServer]
date: 2017-01-09
visible: true
---

<p class="lead">
Episerver just released a new version which added a constructor injection support in scheduled jobs. It encouraged me to create a list of different Episerver infrastructure parts which still do not support a constructor injection.
</p>

Initially, I was thinking just to look at the _Episerver_ documentation and find which parts of the infrastructure might not have constructor injection working. But [Valdis Iljučonoks](http://blog.tech-fellow.net/) suggested to look up for _Activator.CreateInstance_ usages in the _Episerver_ code.

So I used [Reflector](http://www.red-gate.com/products/dotnet-development/reflector/) to search for _Activator.CreateInstance_ usages. It has several overloads but only these five are used by the _Episerver_:

<img src="/img/2017-01/activator-createinstance-usages.png" class="img-responsive" alt="Activator.CreateInstance methods used in Episerver">

But while there are only five methods in use, there is quite a lof of usages. For example, _Activator.CreateInstance&lt;T&gt;_ is used 21 times.

<img src="/img/2017-01/activator-createinstance-of-T-usages.png" class="img-responsive" alt="Usages of Activator.CreateInstance of T">

I understand that there are cases when _Activator.CreateInstance_ should be used instead of resolving type instance with _IoC Container_. As an _Episerver_ developer, I care more about extension points in the framework. So the list will be based on my knowledge of the most used services and an analysis of the _Activator.CreateInstance_ method usages.

# CMS

_CMS_ always had a constructor injection support for controllers and now it also supports a constructor injection in [scheduled jobs](http://blog.tech-fellow.net/2016/12/28/scheduled-jobs-updates/). But there are still some parts which do not support a constructor injection.

## AspNetIdentity's IUIUser

It was surprising to me that _ApplicationUserProvider_ in the _EPiServer.Cms.UI.AspNetIdentity_ namespace uses _Activator_ for user creation. It means that you will not be able to use constructor injection when creating your own type of user. Here you can see how it is used:

```
public override IUIUser CreateUser(string username, string password, string email, string passwordQuestion, string passwordAnswer, bool isApproved, out UIUserCreateStatus status, out IEnumerable<string> errors)
{
    errors = Enumerable.Empty<string>();
    status = UIUserCreateStatus.Success;
    TUser local1 = Activator.CreateInstance<TUser>();
    local1.set_Email(email);
    local1.IsApproved = isApproved;
    TUser user = local1;
    user.set_UserName(username);
    IdentityResult result = this._userManager().Create<TUser, string>(user, password);
    if (!result.Succeeded)
    {
        errors = result.Errors;
        status = UIUserCreateStatus.ProviderError;
        return null;
    }
    return user;
}
```

Luckily, you can implement your own user provider by inheriting from _ApplicationUserProvider_ and overriding this _CreateUser_ method. But I would better see some user factory which could have a default implementation with _Activator_ usage. Then developers would be able to create their own implementations of this factory  if needed.

## ICriterionModel in visitor groups

_ICriterionModel_ is initialized with _Activator_ in the _EPiServer.Personalization.VisitorGroups.CriterionBase_ class's _Initialize_ method. But same as in _IUIUser_ case, it is possible to override _Initialize_ method in your own criterion model implementation.

## ICriterion in visitor groups

Same as with _ICriterionModel_, it does not support constructor injection. _EPiServer.Personalization.VisitorGroups.VisitorGroupRole_ class's _CreateCriterion_ method uses _Activator_ to instantiate _ICriterion_. But it is not possible to override _CreateCriterion_ method as it is private.

## ISelectionFactory in visitor groups

_ISelectionFactory_ is used when creating _Dojo_ dropdown list in the administrative interface. Custom implementations of such selection factory do not support constructor injection. _ISelectionFactory_ is instantiated with _Activator_ in the _EPiServer.Personalization.VisitorGroups.DojoHtmlExtensions_ class's _DojoDropDownFor_ method.

## IGeneratesAdministrativeInterface in visitor groups

Some might be interested into extending visitor group administrative interface through _IGeneratesAdministrativeInterface_. Unfortunately, it is created with _Activator_ in the _EPiServer.Cms.Shell.UI.Controllers.Internal.VisitorGroupsController_. Two controller actions - _CriteriaModelDefinition_ and _CriteriaUI_ initializes it with _Activator_ and there is no way to override this behavior. _EPiServer.Web.Mvc.VisitorGroups.VisitorGroupModelBinder_ class's _ConvertDictionaryToObject_ method also uses _Activator_ to initialize _IGeneratesAdministrativeInterface_.

## IViewTemplateModelRegistrator

 Sometimes there is a need to register different templates for different content types. Then a custom implementation of _IViewTemplateModelRegistrator_ helps to achieve it. But unfortunately, instances of it are created with _Activator_ in the _EPiServer.DataAbstraction.RuntimeModel.Internal.ViewRegistrator_ class's _InstantiateViewTemplateRegisters_ method. As this method is private, it is not possible to override the behavior. The only way to fix this is own implementation of _IViewRegistrator_.

# Commerce

As _Commerce_ is built on top of the _CMS_, anything which supports a constructor injection in _CMS_ supports it also in _Commerce_. For example, controllers support a constructor injection. But Commerce has an additional infrastructure which might not support a constructor injection.

## IPaymentPlugin

Unfortunately, payment gateways by default do not support constructor injection. _IPaymentPlugin_ is instantiated with _Activator_ in the _EPiServer.Commerce.Order.DefaultPaymentProcessor_ class's _CreatePaymentGatewayProvider_ private method. While it is possible to create an own implementation of payment processor by implementing _IPaymentProcessor_, it is not possible to reuse logic of the _DefaultPaymentProcessor_ as _CreatePaymentGatewayProvider_ method is private.

## Payment

Custom _Payment_ implementations also do not support constructor injection. There are few places where _Payment_ is instantiated with _Activator_:
- _Mediachase.Commerce.Orders.PaymentCollection_ class's method _AddNew_
- _Mediachase.Commerce.Orders.PaymentConverter_ class's method _Create_

## IPaymentGateway

Also, _IPaymentGateway_ is instantiated with _Activator_ in the _Mediachase.Commerce.Workflow.Activities.Cart.ProcessPaymentActivity_ class's _ProcessPayment_ method.

## IShippingGateway

_IShippingGateway_ is instantiated with _Activator_ in the _Mediachase.Commerce.Workflow.Activities.ProcessShipmentsActivity_ class's _ProcessShipments_ method. It is interesting that _IMarketService_ in the same method is resolved with service locator:

```
IMarket market = ServiceLocator.Current
  .GetInstance<IMarketService>()
  .GetMarket(orderGroup.MarketId);
IShippingGateway gateway = (market != null)
  ? ((IShippingGateway) Activator.CreateInstance(type, new object[] { market }))
  : ((IShippingGateway) Activator.CreateInstance(type));
```

## IShippingPlugin

_EPiServer.Commerce.Order.Calculator.DefaultShippingCalculator_ class's _GetShippingGateway_ method uses _Activator_ to instantiate _IShippingPlugin_.
_GetShippingGateway_ method is private. So to override the behavior, a custom implementation of _IShippingCalculator_ is required.

# Summary

When I started to write this article, I thought that there will be a lot of places where dependency injection is not supported with a constructor injection. But it seems that _Episerver_ did a great job to make it more extensible.

There are still some areas which require improvements - visitor groups in _CMS_, payments, shipping in _Commerce_ and other.
