---
layout: post
title: "Dependency injection recipe for Episerver developer"
description: >
  <t render="markdown">
  Choosing proper dependency injection type might be hard. But it is not so hard when you have a recipe.
  </t>
category:
tags: [EPiServer]
date: 2017-11-23
visible: true
---

# Ingredients

- [dependent object](https://en.wikipedia.org/wiki/Dependency_injection)
- [dependency](https://en.wikipedia.org/wiki/Dependency_injection)

# Method

1. Find out if the dependent object supports constructor injection.

 **TIP**: Your custom classes, controllers, scheduled jobs (Episerver 10.3+) supports constructor injection. You also can check what does not support constructor injection [here](http://marisks.net/2017/01/09/episerver-di-status/) (it might not be up to date).

2. Use constructor injection if supported.
3. If constructor injection is not available, check if there is a method injection available. For example, when implementing _IInitializableModule_, there is a context available as a method argument to the _Initialize_ method. The context has a property of _Service Locator_ available called _Locate_. You can get different _Episerver_ services from it or use the _Advanced_ property to get any dependency you need.

 ```csharp
 public void Initialize(InitializationEngine context)
 {
     if (_initialized)
     {
         return;
     }

     var loader = context.Locate.ContentLoader();
     var service = context.Locate.Advanced.GetInstance<IMyService>();
 }
 ```

 While _Service Locator_ is an anti-pattern, initialization modules are the composition root here. So it is okay to use it.

4. If method injection is not available, use either _Service Locator_ or _Injected_ property. Both are same - _Injected_ property uses _Service Locator_ under the hood. Choose what you like better. The only rule - be consistent within your codebase.

 **TIP**: In case of 3. and 4. try to "locate" only one dependency which is the entry point for your logic and which uses constructor injection to get all needed services.

 ```csharp
 public class EntryPoint
 {
     public EntryPoint(IContentLoader contentLoader, ReferenceConverter referenceConverter)
     {
         // Initialization code here
     }

     public void Execute()
     {
         // Run your logic here.
     }
 }

 public void Initialize(InitializationEngine context)
 {
     if (_initialized)
     {
         return;
     }

     var service = context.Locate.Advanced.GetInstance<EntryPoint>();
     service.Execute();
 }
 ```

 Here you can see that the only dependency we are locating in the initializable module is _EntryPoint_. Then _EntryPoint_ uses constructor injection to get all the needed services.