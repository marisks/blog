---
layout: post
title: "A feature's sub-tech folders vs sub-feature folders"
description: >
  <t render="markdown">
  Almost a year ago I wrote an [article](/2016/02/16/feature-folders-vs-tech-folders/) about feature folders vs tech folders. I explained why you should favor feature folders vs tech folders. While I see this style of architecture more and more, I also see that developers use tech folders inside feature folders. In this article, I am going to describe alternatives to this type of structure.  
  </t>
category:
tags: [EPiServer]
date: 2017-01-29
visible: true
---

# Sub-tech folders

So how do sub-tech folders look like? Developers structure their MVC application into feature folders but one level below that starts adding different folders specific to MVC - _ViewModels_, _Controllers_, _Models_, _Views_. Also, there might be other technical folders like - _Services_, _Interfaces_, _Implementations_, _Repositories_ etc. At the end, feature folder will look like this:

<img src="/img/2017-01/sub-tech-folders.png" class="img-responsive" alt="Sub-tech folder structure in the solution explorer">

Now a feature folder looks like a small MVC application. This looks better than before with huge MVC application where everything goes into these tech folders but still, tech folders hide your application purpose.

There are several issues with this approach. As I mentioned, it hides the purpose of your application and with feature folders - specific feature's main components. See [Quicksilver's Cart feature](https://github.com/episerver/Quicksilver/tree/ce8274120ac63f01de57c1500a7c8f9ddffd9400/Sources/EPiServer.Reference.Commerce.Site/Features/Cart) - the structure looks like in the typical MVC application and it is impossible to say what are the main components of this feature.

Another issue is that it hides smaller features. It is really easy to add multiple features into one feature folder. Yes, those now are grouped and easier to find but those still mixes different features. Same [Quicksilver's Cart feature](https://github.com/episerver/Quicksilver/tree/ce8274120ac63f01de57c1500a7c8f9ddffd9400/Sources/EPiServer.Reference.Commerce.Site/Features/Cart/Controllers) hides _Wishlist_.

Sub-tech folders also make closely related code be separated. For example, I've seen where interfaces are explicitly put into a different folder than implementations - _Interfaces_ and _Implementations_. This makes harder to reason about the code. Another example can be found in the [Quicksilver](https://github.com/episerver/Quicksilver/tree/ce8274120ac63f01de57c1500a7c8f9ddffd9400/Sources/EPiServer.Reference.Commerce.Site/Features/Cart) - view model factories are separated from view models which those factories are creating.

Then comes the issue with any other type of code. How one will call the tech folder where the class doesn't fit in the existing tech folders? Maybe call it _Others_ or _Classes_? It sounds weird. So developers tend to not extract separate classes even if it would lead to a better design but keep all the logic in controllers, views, models etc. Then we see huge controllers which are hard to maintain.

# No sub-folders

Another option - do not use any sub-folders and place everything in the root of the feature folder. This is a most common approach dealing with feature folders. You can find examples of that in the [Scott Sauber's blog](https://scottsauber.com/2016/04/25/feature-folder-structure-in-asp-net-core/), [Jimmy Bogard's talk](https://vimeo.com/131633177) and more.

<img src="/img/2017-01/no-subfolders.png" class="img-responsive" alt="No sub-folder structure in the solution explorer">

While it works and works fine, in the _Episerver_ projects it might get quite messy as the pages might have quite complex views with lots of partial views. Also, front-end code for these views will get into the feature folder and make it messier.

# Sub-feature folders

The sub-feature folder is the concept of splitting your feature into smaller ones. You might have checkout feature which could be split into shipment, billing, order confirmation etc. sub-features. So creating a separate folder for each of these sub-features makes it much easier to reason about the code.

It might look like this:

<img src="/img/2017-01/sub-feature-folders.png" class="img-responsive" alt="Sub-feature folder structure in the solution explorer">

There are some disadvantages. It is hard to configure MVC to pick up views from the sub-feature folders. Also, it still keeps all the front-end stuff together with the back-end.

# Solution

So if tech sub-folders are not good, without sub-folders it might get messy, and feature sub-folders have their own issues, what is the solution? It depends. It depends on your project - how complex it is, how complex your views are etc.

You can mix different concepts together. Find what matches your needs. I will give you few hints.

## Tech and feature sub-folder mix

The reason why tech sub-folders are bad is because developers tend to create those too granular. It is enough to separate just bigger concepts. For example, create a separate folder for views if you have a lot of them or create a separate folder for models. But do not split it more granularly.

With feature sub-folders, do not be afraid to mix in some tech folders if it becomes too messy. Add a separate folder for views, models etc. in the feature sub-folder.

<img src="/img/2017-01/mix-folders.png" class="img-responsive" alt="Sub-tech and sub-feature folder structure in the solution explorer">

## Layered approach

With bigger and really complex applications which have a lot of business logic, it is wise to separate those into layers according to [Domain Driven Design](https://en.wikipedia.org/wiki/Domain-driven_design). There is a good book - [Implementing Domain-Driven Design](https://www.amazon.com/Implementing-Domain-Driven-Design-Vaughn-Vernon-ebook/dp/B00BCLEBN8/) which describes this approach well.

Basically, separate your domain, application, UI, data access etc. logic within the feature. It might be separated within feature folder or split into separate assemblies.

When separating these concepts in the feature folder, it might look like this:

<img src="/img/2017-01/layered-folders.png" class="img-responsive" alt="Layered folder structure in the solution explorer">

# Summary

There are different ways how you can structure your code but the main goal is to keep it easy to work with. You can achieve it different ways but keep in mind that the "feature" is a main concept.
