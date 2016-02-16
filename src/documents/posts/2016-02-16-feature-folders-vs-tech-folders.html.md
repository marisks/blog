---
layout: post
title: "Feature folders vs Tech folders"
description: "For several years using ASP.NET MVC we tend to organize our code by Models, Controllers, and Views. In EPiServer development, we also split it more - into Page types, View models, and other types. But lately, developers started to realize that it is hard to manage such codebase and started to organize the code by features. In this article, I will analyze both approaches using Dependency Structure Matrix."
category:
tags: [.NET, EPiServer]
date: 2016-02-16
visible: true
---
<p class="lead">
For several years using ASP.NET MVC we tend to organize our code by Models, Controllers, and Views. In EPiServer development, we also split it more - into Page types, View models, and other types. But lately, developers started to realize that it is hard to manage such codebase and started to organize the code by features. In this article, I will analyze both approaches using Dependency Structure Matrix.
</p>

# Introduction

_ASP.NET MVC_ and _EPiServer CMS_ _Visual Studio_ templates by default split the code into _Models_, _Views_, _Controllers_ folders and it leads most of the developers to use this style of code structuring. I'll call this approach as _Tech folders_. But there are other ways available.

_ASP.NET MVC_ provides  [Areas](https://msdn.microsoft.com/en-us/library/ee671793%28v=vs.100%29.aspx?f=255&MSPPError=-2147217396) support which can be used to organize your code by features. _EPiServer_ code also can be organized using _Areas_. [Valdis Iljuconoks](http://blog.tech-fellow.net/) has two articles about it - [Full support for Asp.Net Mvc areas in EPiServer 7.5](http://blog.tech-fellow.net/2015/01/21/full-support-for-asp-net-mvc-areas-in-episerver-7-5/) and [Asp.Net Mvc Areas in EPiServer - Part 2](http://blog.tech-fellow.net/2015/08/10/asp-net-mvc-areas-in-episerver-part-2/).

Another approach is _Feature folders_.  There are quite a lot of articles which describes it:

- [Feature Folders In ASP.NET MVC](http://timgthomas.com/2013/10/feature-folders-in-asp-net-mvc/)
- [Feature Folders and JavaScript](http://timgthomas.com/2013/10/feature-folders-and-javascript/)
- [Introducing the ASP.NET MVC “Feature Folders” Project Structure](http://www.chwe.at/2014/04/introducing-the-asp.net-mvc-feature-folders-project-structure/)
- [Grouping by feature in ASP.Net MVC](http://www.meadow.se/wordpress/grouping-by-feature-in-asp-net-mvc/)
- [The Obvious Architecture](http://developer.7digital.com/blog/obvious-architecture)
- [A View Engine for ASP.NET MVC Feature-Based Organized](http://trycatchfail.com/blog/post/A-View-Engine-for-ASPNET-MVC-Feature-Based-Organized)
- [Structure your code by feature](http://www.planetgeek.ch/2012/01/25/3077/)
- [A Feature-Oriented Directory Structure For C# Projects](https://spin.atomicobject.com/2015/11/18/feature-oriented-c-sharp-structure/)

Also, _EPiServer's_ _Commerce_ starter site - [Quicksilver](https://github.com/episerver/Quicksilver) uses _Feature folders_.

Both _Areas_ and _Feature folders_ separate the code by features, so I will refer to both as _Feature folders_.

Further, I am going to show analysis of dependencies between components in both approaches. I created two _EPiServer_ _Alloy Tech_ sites where the first one is left untouched, but the   second one is refactored into _Feature folders_.

# Dependency Structure Matrix

For analysis, I used [Dependency Structure Matrix](http://www.ndepend.com/docs/dependency-structure-matrix-dsm) and used the evaluation version of [NDepend](http://www.ndepend.com/) to create it. Below is a sample matrix.

<img src="/img/2016-02/dsm-sample.png" alt="Dependency Structure Matrix sample" class="img-responsive">

Rows and columns are _components_ which can be assemblies, namespaces or types. Each _component_ lives in column and row with the same index. Blue cells represent dependency when the _component_ in the column is using the _component_ in the row. Green cells represent opposite dependency. Black cells represent dependency cycle.

Read more about Dependency Structure Matrix on [NDepend page](http://www.ndepend.com/docs/dependency-structure-matrix-dsm).

# Namespace dependencies

First let's look at a higher level - dependencies between namespaces.

Below is a _Feature folders'_ namespace dependency matrix.

<img src="/img/2016-02/feature-folders-namespace-dsm.png" alt="Feature folders' namespace dependency matrix." class="img-responsive">

From the _Features_ namespace (inner square) it is easy to see that there are not many dependencies between different features. Only _Articles_ and _PageLists_, _Start_ and _Contacts_ and _Start_ and _Common.Blocks_ have one-way dependencies which mean that namespaces within _Features_ namespace have low coupling.

It is also visible that _Business_, _Base_, _Layout_, and _Media_ are used by all features. There are few cyclic dependencies (in black). One is the shared layout and _IPageViewModel_ used in _Alloy Tech_. I wrote about it [before](http://marisks.net/2015/05/18/episerver-strongly-typed-layout-model-without-ipageview/). And second is template render which defines custom views for some models.

Now lets look at _Tech folders_.

<img src="/img/2016-02/tech-folders-namespace-dsm.png" alt="Tech folders' namespace dependency matrix." class="img-responsive">

While dependency matrix seems simpler, it shows heavy coupling between namespaces. From this view, it is possible to see that _Controllers_ and _Business_ are heavily dependent on _Models_. It is impossible to see which application's feature is dependent on other feature. But you can see that _Models_ has [Layered](http://www.ndepend.com/docs/dependency-structure-matrix-dsm#Layer) code structuring. Unfortunately _Controllers_ and _Business_ namespaces are not. Also, _Tech folders_ have cyclic dependencies for same reasons as _Feature folders_ have.

# Type dependencies

Let's look at _Feature folders'_ dependency matrix first.

<img src="/img/2016-02/feature-folders-type-dsm.png" alt="Feature folders' type dependency matrix." class="img-responsive">

Also, here it is easy to see that features within _Features_ namespace are quite independent - most of the dependencies are within namespace itself. You can spot those dependencies as squares on the diagonal. This matches code structure pattern - [High Cohesion - Low Coupling](http://www.ndepend.com/docs/dependency-structure-matrix-dsm#Coupling). As we know our applications should tend to have [high cohesion and low coupling](http://stackoverflow.com/a/14000957/660154).

Unfortunately, _Tech folders_ do not have such pattern.

<img src="/img/2016-02/tech-folders-type-dsm.png" alt="Tech folders' type dependency matrix." class="img-responsive">

From this matrix, you can see that dependencies for a particular feature are spread over different namespaces. This matrix also shows that _Tech folders_ are quite badly [layered](http://www.ndepend.com/docs/dependency-structure-matrix-dsm#Layer). In the layered structure most of the blue cells should be in the lower left triangle but green ones in the upper-right triangle. _Feature folders_ have better-layered structuring.

# Summary

From this _Feature folder_ and _Tech folder_ comparison, it is quite easy to understand the benefits of _Feature folders_ and why _Tech folders_ should be used only for demos or application prototypes. _Feature folders_ provide lower coupling same time grouping related code together. The only disadvantage using _Feature folders_ is that frameworks do not "understand" those by default - you might need to configure those for your needs.
