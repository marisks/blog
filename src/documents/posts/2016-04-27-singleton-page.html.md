---
layout: post
title: "Singleton page"
description: ""
category:
tags: [EPiServer]
date: 2016-04-27
visible: true
---
<p class="lead">
Quite often when developing a website on EPiServer, I am creating page types which are used only for a single page. Such pages could be - cart page, order page, password reset page etc. To load such page, the pattern I use is adding properties with content references of those pages on the start page, then load start page and then load configured page. This sounds too complicated when I know that this page has only a single instance. Also, it is quite often that I forget to configure these pages for different environments. So few months ago I had an idea to create extension methods which would allow loading these pages in a simple way.
</p>

A singleton page extension method looks for the first page of a particular type under given root page. Usually, you would like to search under start page. There are extensions for _ContentReference_ and for _PageData_.

```
var testPage1 = ContentReference.StartPage.GetSingletonPage<TestPage>();

var startPage = _contentLoader.Get<StartPage>(ContentReference.StartPage);
var testPage2 = startPage.GetSingletonPage<TestPage>();
```

But it is also possible to search under any page. For example, in a commerce solution you might have a _Checkout_ page with _Order confirmation_ and _Order summary_ pages as children.

```
var checkoutPage = ContentReference.StartPage.GetSingletonPage<CheckoutPage>();
var orderConfirmationPage = checkoutPage.GetSingletonPage<OrderConfirmationPage>();
var orderSummaryPage = checkoutPage.GetSingletonPage<OrderSummaryPage>();
```
A singleton page API under the hood uses simple concurrent dictionary to cache content references for particular singleton page under the root page.  This allows to search for the page only once and next time use cached _ContentReference_.

An API also allows to create and inject your own caching mechanism. For example, you would like to use _EPiServer's CacheManager_ or fake cache for testing.

```
public class FakeCache : DefaultContentReferenceCache
{
    public ConcurrentDictionary<CacheKey, ContentReference> InternalCache => Cache;
}

...

var fakeCache = new FakeCache();
Extensions.InjectedCache = new Injected<IContentReferenceCache>(fakeCache);
```

Currently, the project does not have a _NuGet_ package, but it is quite easy to copy/paste an extension code from [GitHub](https://github.com/marisks/SingletonPage). The project also has [tests](https://github.com/marisks/SingletonPage/tree/master/src/SingletonPage.Tests) which could be used as a reference.

# Summary

Using this API you can create a project without the need to configure singleton pages or use API as a fallback when the page is not configured. _Per Nergård_ recently wrote an [article](http://world.episerver.com/blogs/Per-Nergard/Dates/2016/4/limit-block-and-page-types-to-be-created-only-once-updated/) how to limit page types and block types to be created only once. Combining both techniques creates a good solution for managing singleton pages.
