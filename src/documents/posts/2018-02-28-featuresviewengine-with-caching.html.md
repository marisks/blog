---
layout: post
title: "FeaturesViewEngine with caching"
description: >
  <t render="markdown">
  Last December I have published a library - FeaturesViewEngine which enables feature folder support. It had one drawback - it did not use caching. Now I have released a new version with caching enabled.
  </t>
category:
tags: [EPiServer]
date: 2018-02-28
visible: true
---

# Short release info

Thanks to my colleague's - [Kaspars Ozols](https://getadigital.com/people/kaspars-ozols/) suggestions, I have made changes to the _FeaturesViewEngine_. [The blog post](/2017/12/17/better-feature-folders/) about its configuration is still up to date, and there are no breaking changes. The changes improve view resolution performance.

You can install the new version from NuGet:

```powershell
Install-Package FeaturesViewEngine -Version 1.1.0
```

You can find the source code on [GitHub](https://github.com/marisks/FeaturesViewEngine).

# Some technical stuff

Previously, I overrode a _CreateView_ method of the base _RazorViewEngine_. When a cache was enabled, the _CreateView_ method was called only once for a particular view name. As controllers can have similar view names, it always resolved the first view. The cache didn't use controller data for cache key - only view name. So cache had to be disabled.

In the latest version, I overrode a _FindView_ (and _FindPartialView_) method instead. This method is always called and uses caching internally. I also had to pass the full virtual path to the base method. For that, I had to check for the first existing view matching particular controller and view location format. Once the view's full path is resolved, it is cached.