---
layout: post
title: "EPiServer: strongly typed layout model without IPageViewModel"
description: "EPiServer provides Alloy sample which uses IPageViewModel&lt;T&gt; interface to provide strongly typed model for layout, but this approach has several issues. In this article I am going to show alternative way for strongly typed layout models."
category: [EPiServer]
tags: [EPiServer, MVC]
date: 2015-05-18
visible: true
---

<p class="lead">
EPiServer provides Alloy sample which uses IPageViewModel&lt;T&gt; interface to provide strongly typed model for layout, but this approach has several issues. In this article I am going to show alternative way for strongly typed layout models.
</p>

# Problem 

Lot of _ASP.NET MVC_ examples show data sharing between controllers and layouts using _dynamic_ _ViewBag_ or _ViewData_ dictionary. This approach works fine for small application where you do not have a lot of data in a layout, but in a more complex application you want strongly typed model for layout.

_EPiServer_ provided sample site - [Alloy](https://github.com/marisks/cms_layout/tree/master/src/Alloy) which uses [IPageViewModel&lt;T&gt;](https://github.com/marisks/cms_layout/blob/master/src/Alloy/Alloy/Models/ViewModels/IPageViewModel.cs) interface which has property _Layout_ of type [LayoutModel](https://github.com/marisks/cms_layout/blob/master/src/Alloy/Alloy/Models/ViewModels/LayoutModel.cs).

    public interface IPageViewModel<out T> where T : SitePageData
    {
        T CurrentPage { get; }
        LayoutModel Layout { get; set; }
        IContent Section { get; set; }
    }

Then there is a base class for view models - [PageViewModel&lt;T&gt;](https://github.com/marisks/cms_layout/blob/master/src/Alloy/Alloy/Models/ViewModels/PageViewModel.cs) which implements this interface. All your view models now should implement _IPageViewModel&lt;T&gt;_ or inherit from _PageViewModel&lt;T&gt;_.

Developer usually modifies _LayoutModel_ to add required data to site's layout and then in [PageViewContextFactory](https://github.com/marisks/cms_layout/blob/master/src/Alloy/Alloy/Business/PageViewContextFactory.cs) loads all necessary data into this layout model.

Sometimes it is also required to update layout model from page's controller. In this case sample provides [IModifyLayout](https://github.com/marisks/cms_layout/blob/master/src/Alloy/Alloy/Business/IModifyLayout.cs) interface which you use to decorate controller and [implement ModifyLayout](https://github.com/marisks/cms_layout/blob/master/src/Alloy/Alloy/Controllers/PageControllerBase.cs#L32) method which takes layout model as parameter. Then in this method it is possible to update the model. Layout model is injected into controller using [PageContextActionFilter](https://github.com/marisks/cms_layout/blob/master/src/Alloy/Alloy/Business/PageContextActionFilter.cs) global filter which watches for controllers implementing _ModifyLayout_.

So there are two tasks _IPageViewModel&lt;T&gt;_ does:
- provides stringly typed layout model,
- shares data between page controller and layout.

Then why bother and try something else if it solves these tasks? Because this approach has several important issues.

## 1. Issue: form posting

When you are creating form and post to controller's action, _MVC_ automatically binds form data to your model. This is great. But it is more complicated when your view model inherits from _PageViewModel&lt;T&gt;_. Model binder can't bind your model because _PageViewModel&lt;T&gt;_ requires _currentPage_ injected into contructor. So you have to create separate model for posting with same fields and same validation annotations as in view model.

## 2. Issue: coupling

While project is small this might not be an issue - just inherit all views from _PageViewModel&lt;T&gt;_ and it's fine. 

When your project starts to grow and you split your project in separate libraries by features, then all should share some common library with layout model even if feature library does not use it.

Or you might start creating reusable UI libraries with own controllers and view models, then dependency on _IPageViewModel&lt;T&gt;_ becomes important issue. Not all projects share same layout model so it can't be common for all your projects. 

And if you want to use some 3rd party UI library, you are stuck. Because 3rd party library is not going to use your layout model.

# Solution

_ASP.NET MVC_ has a way to inject objects into your views. You just have to create base class for your views and this base class should [inherit from _WebViewPage&lt;T&gt;_](http://bradwilson.typepad.com/blog/2010/07/service-location-pt3-views.html). 

    public class MyBaseWebViewPage : WebViewPage
    {
        public string MyProperty { get { return "Injected property"; } }

        public override void Execute() { }
    }

Then use _@inherits_ keyword in your layouts and/or pages to use newly created base class. All properties and methods in this base class will be available in the view.

    @inherits MyBaseWebViewPage

    @MyProperty

You are not forced to use the base class in pages. You can use this base view only in layout. So your pages are not coupled to this view base implementation.

## EPiServer example

### Creating layout model

_EPiServer_ is not much different from raw _ASP.NET MVC_. So first create layout model for your site and base class for your layout view. You can use _EPiServer's_ _Injected_ class to inject your objects into the view.

    public class LayoutModel
    {
        public string Constant
        {
            get { return "Layout: constant value"; }
        }
    }

    public class BaseViewPage : WebViewPage
    {
        public Injected<LayoutModel> LayoutModel { get; set; }

        public override void Execute() { }
    }

Then inherit your site's layout from _BaseViewPage_ and use layout model's property.

    @inherits CmsLayout.Models.Pages.BaseViewPage

    <!DOCTYPE html>
    <html>
    <head>
        <title>Cms Layout sample</title>
    </head>
    <body>
        <div>
            @LayoutModel.Service.Constant <br />
            @RenderBody()
        </div>
    </body>
    </html>

When you run the project, you should see _"Layout: constant value"_ on the page.

### Modifying layout from page's controller

First of all let's create mutable property in layout model which we want to modify in the page's controller.

    public class LayoutModel
    {
        public string Constant
        {
            get { return "Layout: constant value"; }
        }

        public string Mutable { get; set; }
    }

We can inject this model into controller now and change the value of _Mutable_ property.

    public class StartPageController : PageController<StartPage>
    {
        Injected<LayoutModel> LayoutModel { get; set; }

        public ActionResult Index(StartPage currentPage)
        {
            LayoutModel.Service.Mutable = "Layout: mutated from controller";
            return View(currentPage);
        }
    }

And render this property in the layout.

    @inherits CmsLayout.Models.Pages.BaseViewPage

    <!DOCTYPE html>
    <html>
    <head>
        <title>Cms Layout sample</title>
    </head>
    <body>
        <div>
            @LayoutModel.Service.Constant <br />
            @LayoutModel.Service.Mutable <br />
            @RenderBody()
        </div>
    </body>
    </html>

Also notice that _StartPage's_ view does not depend on anything than _StartPage's_ page type.

    @model  CmsLayout.Models.Pages.StartPage

Unfortunately after running the application, only constant value get's rendered. The issue is with _LayoutModel_ lifetime in _StructureMap_ container. By default it uses _Transient_ lifetime that it creates new instance each time someone requests it. To fix this issue we have to add _StructureMap_ configuration into project (which should be in each project anyway :) ) and configure _LayoutModel's_ lifetime to _HybridHttpOrThreadLocalScoped_ that it will live for whole request.

    For<LayoutModel>()
        .HybridHttpOrThreadLocalScoped()
        .Use<LayoutModel>();

**NOTE** This example uses _StructureMap 2_, but _StructureMap 3_ requires different [configuration](http://structuremap.github.io/the-container/nested-containers/).

Now after running application, you should see two messages - _"Layout: constant value"_ and _"Layout: mutated from controller"_.

Full source code for sample is [here](https://github.com/marisks/cms_layout/tree/master/src/CmsLayout).

# Summary

Creating strongly typed layout model is simple task. You do not need to have lot of infrastructure code to make it work and you can make it decoupled from your pages.
