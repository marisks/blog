---
layout: post
title: "New version of FeaturesViewEngine"
description: >
  <t render="markdown">
  I just released a new version of FeaturesViewEngine. It includes some bug fixes and improvements.
  </t>
category:
tags: [EPiServer]
date: 2018-03-19
visible: true
---

After talking with my colleague [Mattias Olsson](https://getadigital.com/people/mattias-olsson/), I have added the ability to override view path formatting. Now the base class has the _FormatViewPath_ method as protected. It allows you to create your custom path formatting. One such case could be - multi-site setup. You might want to add current site's name in the path.

The changes also include two bug fixes:

- Previously, it was able to insert a null value into the cache, and now it is fixed.
- There was a bug if you have a namespace which doesn't match assembly name. It formatted path incorrectly.

You can install the new version from NuGet:

```powershell
Install-Package FeaturesViewEngine -Version 1.1.2
```

You can find the source code on [GitHub](https://github.com/marisks/FeaturesViewEngine).