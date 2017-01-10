---
layout: post
title: "Simple check if block is in edit mode"
description: "When working with EPiServer page views there is a useful property - PageEditing.PageIsInEditMode, which allows checking if the page is open in edit mode. But when working with block views, there is no such property."
category:
tags: [EPiServer]
date: 2016-07-21
visible: true
---

I found one solution on [EPiServer Forum](http://world.episerver.com/forum/developer-forum/EPiServer-7-CMS/Thread-Container/2014/2/Check-if-Block-is-in-editmode/) but I do not like it because it uses _ViewBag_ or developer should check if the current page is a _PreviewPage_.

Instead, I have created extension method _BlockIsInEditMode_ for the _ViewContext_.

```
public static class ViewContextExtensions
{
	public static bool BlockIsInEditMode(this ViewContext context)
	{
		return IsPageController(context, "BlockPreview");
	}

	public static bool IsPageController(this ViewContext context, string controllerName)
	{
		var pageController = context.RequestContext.RouteData.Values["pagecontroller"]
                          ?? context.RequestContext.RouteData.Values["controller"];
		return pageController != null
            && pageController.ToString().Equals(controllerName, StringComparison.InvariantCultureIgnoreCase);
	}
}

```

This method checks if current controller is block preview controller. If so, then block is in the edit mode.

As the _ViewContext_ is available in the view, you can use it like this:

```
@if(ViewContext.BlockIsInEditMode())
{
  @* Do some stuff here *@
}
```
