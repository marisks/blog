---
layout: post
title: "Episerver Razor view support in Shell modules"
description: >
  <t render="markdown">
  A few months ago I created a [library](/2017/03/19/enable-razor-views-in-episerver-modules-with-shellrazorsupport-package/) which enabled Razor views in Episerver Shell modules. Now Episerver has built [support for it by default](http://world.episerver.com/documentation/Release-Notes/ReleaseNote/?releaseNoteId=CMS-1506).
  </t>
category:
tags: [EPiServer]
date: 2017-07-31
visible: true
---

In the [Episerver.CMS.UI 10.10.0](http://world.episerver.com/documentation/Release-Notes/?versionFilter=10.10.0&packageFilter=EPiServer.CMS.UI&typeFilter=All), _Episerver_ has added support for _Razor_ modules. Initially, it did not work as expected but starting with the version [Episerver.CMS.UI 10.10.2](http://world.episerver.com/documentation/Release-Notes/?versionFilter=10.10.2&packageFilter=EPiServer.CMS.UI&typeFilter=All&packageGroup=CMS) it is working correctly.

If you were using _Geta.EPi.ShellRazorSupport_ library, uninstall it and upgrade your module project to the latest version (Episerver.CMS.UI 10.10.2 or later). Then open your _module.config_ file and an attribute _viewEngine_ on the _module_ tag. There are three available values for the _viewEngine_ attribute - _None_, _Razor_, and _WebForm_.

_module.config_ for _Razor_ support would look like this:

```xml
<?xml version="1.0" encoding="utf-8"?>
<module viewEngine="Razor">
  <assemblies>
    <add assembly="MyModule" />
  </assemblies>
</module>
```

If you were using _Geta.EPi.ShellRazorSupport_ you also should notify your module users to uninstall it. Add some upgrade notes to your package _readme.txt_ or do it differently.