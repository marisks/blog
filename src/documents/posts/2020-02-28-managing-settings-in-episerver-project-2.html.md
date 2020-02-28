---
layout: post
title: "Managing settings in Episerver project - part 2"
description: >
  <t render="markdown">
  When you have a big Episerver project, you need to maintain a lot of settings. The approaches described in the previous article does not scale well. In this article, I will show you how to improve Episerver specific settings.
  </t>
category:
tags: [EPiServer]
date: 2020-02-28
visible: true
---

# Grouping settings in tabs

The easiest way to improve the way how settings are displayed for the users (administrators), is by grouping those in tabs. For example, you have several setting properties on the start page, and those are mixed now with other properties.

```csharp
[ContentType(GUID = "6C709414-18C6-4E97-9B83-7220FA87D05A", Order = 10, AvailableInEditMode = true)]
public class StartPage : PageData
{
	[CultureSpecific]
	public virtual string Header { get; set; }

	public virtual Url FacebookUrl { get; set; }
}
```

The `Header` property, in this example, is displayed on the start page, but `FacebookUrl` is used for the whole site. So the last one is a setting we would not like to see mixed with start page related stuff in UI.

By adding the `Display` attribute and setting `GroupName` property on it, we will move the setting property to the separate tab in UI.

```csharp
[ContentType(GUID = "6C709414-18C6-4E97-9B83-7220FA87D05A", Order = 10, AvailableInEditMode = true)]
public class StartPage : PageData
{
	[CultureSpecific]
	public virtual string Header { get; set; }

	[Display(GroupName = "Site Settings")]
	public virtual Url FacebookUrl { get; set; }
}
```

It is also a good approach to extract group name constants into a separate class and add `GroupDefinitions` attribute so that _Episerver_ will pick it up. For more info, read [_Episerver_ documentation](https://world.episerver.com/documentation/developer-guides/CMS/Content/grouping-content-types-and-properties/).

```csharp
[GroupDefinitions]
public static class GroupNames
{
	[Display(GroupName = "Site settings", Order = 10)]
	public const string SiteSettings = "SiteSettings";
}
```

# Grouping settings with local blocks

While grouping with a `Display` attribute allows separating settings in UI, in code, the setting properties are kept together with content properties. One way to work around this issue is by creating blocks and adding those as properties to the start page.

Create a block first.

```csharp
[ContentType(GUID = "13304E95-B697-444E-B0D4-F8806B70BF20")]
public class SettingsBlock : BlockData
{
	public virtual Url FacebookUrl { get; set; }
}
```

And then add it to the start page.

```csharp
[ContentType(GUID = "6C709414-18C6-4E97-9B83-7220FA87D05A", Order = 10, AvailableInEditMode = true)]
public class StartPage : PageData
{
	[CultureSpecific]
	public virtual string Header { get; set; }

	[Display(GroupName = GroupNames.SiteSettings)]
	public virtual SettingsBlock Settings { get; set; }
}
```

As you see, I have kept the `Display` attribute and set `GroupName` so that the block with settings is still displayed in a separate tab.

Now, when you need to use settings in your code, you can just pass `SettingsBlock` around and do not mess with other start page related settings.

```csharp
var startPage = _contentLoader.Get(ContentReference.StartPage);
var settings = startPage.Settings;

DoSomething(settings);
```

# Summary

As you see, there are some simple ways how to improve settings on your site for both - end-users in UI and developers in code. Though in large projects, it is not enough to add grouping or extract settings into a local block. You might need a more advanced approach. But that's for another time.

P.S. Check out [Alf's blog](https://talk.alfnilsson.se/2014/04/01/creating-modular-settings-with-blocks/) about his approach to managing settings.