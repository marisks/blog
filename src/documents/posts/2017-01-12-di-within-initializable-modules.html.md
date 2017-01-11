---
layout: post
title: "Dependency Injection within Initialization Modules"
description: >
  <t render="markdown">
  In the [last article](/2017/01/09/episerver-di-status/), I did not mention [Initialization Modules](http://world.episerver.com/documentation/Items/Developers-Guide/Episerver-CMS/9/Initialization/Creating-an-initialization-module/). Those also do not support a constructor injection but _Initialization Modules_ are different.</t>
category:
tags: [EPiServer]
date: 2017-01-12
visible: true
---

_Initialization Modules_ are the part of the infrastructure which runs during site startup. Those do not run after startup anymore. So it is fine to step away from rules applied to other application code.

But then what are the good practices to resolve services in the _Initialization Modules_? _Service locator_ is [an anti-pattern](http://blog.ploeh.dk/2010/02/03/ServiceLocatorisanAnti-Pattern/), _Injected&lt;T&gt;_ also is [an anti-pattern](/2016/12/01/dependency-injection-in-episerver/#property-injection) (as it is hidden _Service locator_).

_Episerver_ provides another service location in the _Initialization Modules_ - a _Locate_ property of the _InitializationEngine_:

```
public void Initialize(InitializationEngine context)
{
    var loader = context.Locate.ContentLoader();
    var anotherLoader = context.Locate.Advanced.GetInstance<IContentLoader>();
}
```

The _Locate_ property is a _ServiceLocationHelper_. This helper has methods to get to the common _Episerver_ services. The _Advanced_ property of this helper is an instance of the _IServiceLocator_ which can be used to locate other services.

# Summary

While it would be better to have a constructor injection support in the _Initialization Modules_, it is fine to use provided service location mechanisms to resolve service instances.
