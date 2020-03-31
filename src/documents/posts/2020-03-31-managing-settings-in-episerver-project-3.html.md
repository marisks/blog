---
layout: post
title: "Managing settings in Episerver project - part 3"
description: >
  <t render="markdown">
  In the larger projects, you might have a lot of settings, multiple sites that each have their settings, and also settings that apply for all sites. Adding settings to the start page will make things hard to manage. In this article, I will show you how to improve that.
  </t>
category:
tags: [EPiServer]
date: 2020-03-31
visible: true
---

# Settings page

If we look at the single responsibility principle, a start page with settings is doing too much. It has start page related content and also site-wide settings. When you have a large site, the start page becomes a settings page - the primary purpose of it is settings management. But that is not a good approach. The start page should contain only the page related stuff.

To solve the issue, create a separate page type that has only one purpose - storing settings. You can group settings properties or add local blocks to this page type, as I described in my previous [article](/2020/02/28/managing-settings-in-episerver-project-2/).

```csharp
[ContentType(GUID = "16BA6D0E-49D1-4A49-95A9-88B7FAE65E63")]
public class SettingsPage : PageData
{
  [Display(GroupName = GroupNames.Header, Order = 10)]
  [UIHint(UIHint.Image)]
  [AllowedTypes(typeof(ImageFile))]
  public virtual ContentReference CompanyLogo { get; set; }

  [Display(GroupName = GroupNames.Footer, Order = 10)]
  public virtual LinkBlock Links { get; set; }
}
```

Now you can create a page in the root of the site and set required settings. To load and use the page in your code, you can use an extension method from the [`Geta.EPi.Extensions` package](https://github.com/Geta/EPi.Extensions) `GetFirstChild` or create one:

```csharp
public static T GetFirstChild<T>
  this IContentLoader contentLoader, ContentReference contentReference)
    where T : IContentData
{
  return contentLoader.GetChildren<T>(contentReference).FirstOrDefault();
}
```

Then in your code, use this extension to load settings from the site root.

```csharp
var settings = _contentLoader.GetFirstChild<SettingsPage>(ContentReference.StartPage);
```

# Multiple sites

As you have the settings page type already created, you need to create new settings pages on each site. Then when you load the settings by using `ContentReference.StartPage` in your code, it will load the correct settings page for each of your sites.

# Global settings

You can use the same approach for global settings. Create a separate page type that will contain global settings. Then create this page in the root of the _Episerver_ instance.

To load global settings, use `ContentReference.RootPage` as the settings page parent in `GetFirstChild` method.

```csharp
var settings = _contentLoader.GetFirstChild<GlobalSettingsPage>(ContentReference.RootPage);
```

# Summary

A custom page type is an excellent tool when you have to separate settings from other site data. You can create a site-specific settings page type, a settings page type that is used in multiple sites, or a page type that is used globally in the whole _Episerver_ instance.