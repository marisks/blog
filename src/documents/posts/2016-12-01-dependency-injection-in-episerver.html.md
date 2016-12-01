---
layout: post
title: "Dependency injection in EPiServer"
description: "The concept of a dependency injection is simple - pass a dependent object in your object to use it. But that is not the only concept involved and some of the used concepts are better than others. In the EPiServer world, several patterns are used and misused."
category:
tags: [EPiServer]
date: 2016-12-01
visible: true
---
<p class="lead">
The concept of <a href="https://en.wikipedia.org/wiki/Dependency_injection">a dependency injection</a> is simple - pass a dependent object in your object to use it. But that is not the only concept involved and some of the used concepts are better than others. In the EPiServer world, several patterns are used and misused.
</p>

# Service locator

One of the concepts which sometimes is mistakenly perceived as a kind of dependency injection is [Service locator](https://en.wikipedia.org/wiki/Service_locator_pattern). But it is not and it is even an [anti-pattern](http://blog.ploeh.dk/2010/02/03/ServiceLocatorisanAnti-Pattern/). The main issue with _Service locator_ is that it hides dependencies.

Unfortunately, it is widely used in _EPiServer_ development. Many developers use service locator instead of using dependency injection. I also have used service locator in examples on this blog. Also, service locator often is used in the scheduled jobs, extension methods and other places where it is not possible to inject dependent object.

# Constructor and method injection

[Constructor injection](https://en.wikipedia.org/wiki/Dependency_injection#Constructor_injection) is the most used type of the dependency injection. The dependent object is injected as a constructor parameter.

Method injection is similar to the constructor injection but the dependent object is injected into the method which uses that object.

Both patterns are the most appropriate way to do dependency injection. But unfortunately, it is not always possible. While you are able to design your classes so that those use a constructor injection or a method injection, many framework dependent classes can't be designed that way.

_EPiServer_ supports constructor injection for controllers. It is possible to inject dependent objects in your _EPiServer_ controllers if you have [configured it properly](http://world.episerver.com/documentation/Items/Developers-Guide/Episerver-CMS/9/Initialization/dependency-injection/) - created _MVC_ dependency resolver.

While dependency injection support for controllers is great, _EPiServer_ has other types of infrastructure which don't support it. For example, scheduled jobs and initialization modules do not support constructor injection. Instead, you have to use service locator or property injection.

# Property injection

[Property injection](https://jeremybytes.blogspot.com/2014/01/dependency-injection-property-injection.html) or [setter injection](https://en.wikipedia.org/wiki/Dependency_injection#Setter_injection) is the type of dependency injection when a dependent object is injected into the already constructed object via a property or special setter method. This method allows injecting dependencies into the object which can't have a constructor with parameters.

_EPiServer_ has support for property injection via [Injected&lt;T&gt;](http://world.episerver.com/documentation/Class-library/?documentId=cms/10/1692DF76) class. The service you would like to inject should be _wrapped_ as a type parameter of the _Injected&lt;T&gt;_ class and defined as a property on your class. Then during the object construction or after construction via containers _BuildUp_ method it populates property values. If it is not possible, then it uses a service locator to lazily load the object. This scenario is quite common when your properties are private and/or static.

There are several issues with this approach. First of all, your object depends on the _Injected&lt;T&gt;_ class which is not related to your class problem domain. Another issue is with commonly accepted pattern to make these properties private. This way dependency is hidden and works like service locator which as you know is an anti-pattern.

Instead of using _Injected&lt;T&gt;_, I would like to see _EPiServer_ to add support for constructor injection via overridable factories.

# Composition root

[Composition root](http://blog.ploeh.dk/2011/07/28/CompositionRoot/) is a single point in the application where whole object graph gets constructed. In _ASP.NET MVC_ application usually, it is custom a _IControllerFactory_. When developing applications with _EPiServer_ it is not common to use a custom _IControllerFactory_. Also, it is missing composition roots for scheduled job, an initialization module, and other infrastructure code creation.

It is possible to create object graph manually ([Pure DI](http://blog.ploeh.dk/2014/06/10/pure-di/)) in the composition root but usually some kind of _DI Container_ is used. _EPiServer_ uses [StructureMap](http://structuremap.github.io/) under the hood but recently implemented their own [explicit service registration API](http://world.episerver.com/documentation/Items/Developers-Guide/Episerver-CMS/9/Initialization/dependency-injection). I do not like this because it hides the power of the DI container. For example, _StructureMap_ has [registries](http://structuremap.github.io/registration/registry-dsl/) which allow splitting registration logic into separate modules. It also has convention based service registration while _EPiServer_ doesn't support it.

I think that _EPiServer_ should not re-implement registration API but instead allow to register their internal services using any DI container. And application developers should still use their DI container API.

Another way to register services in _EPiServer_ is [implicit service registration](http://world.episerver.com/documentation/Items/Developers-Guide/Episerver-CMS/9/Initialization/dependency-injection). While at first, it seems really simple solution it is a quite dangerous one and should not be used widely. There are several reasons why it is dangerous.

First of all, it hides service registration so that you can't see explicitly in the registration code that something is registered. For example, if there is some service with implicit registration in a referenced library and you want to register your service which implements the same interface. Then you might get into a situation when both registrations conflict and then it is hard to find why. One of my colleagues had such issue and spent several hours solving it.

Another issue is that during the development of the service you do not know what lifetime it should run in. It is the decision of the composition
and should be handled in the composition root. For example, you might set the service to be a singleton and also inject some other services in your class. But you do not know the lifetime of those other services. If injected services are transient (per request), then you might get odd behavior as only the instance of first time created injected service will be used.

# Summary

_EPiServer_ has gone into the right direction by supporting dependency injection but it still requires some improvements and revise some ambiguous implementations. I would like to see _EPiServer_ to go to most simple solutions when adding support for dependency injection - like factories for different types of framework part composition.
