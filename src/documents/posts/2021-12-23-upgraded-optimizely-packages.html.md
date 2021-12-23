---
layout: post
title: "Upgraded Geta Optimizely packages"
description: >
  <t render="markdown">
  We have released several packages that are upgraded for Optimizely 12.
  </t>
category:
tags: [EPiServer, Optimizely]
date: 2021-12-23
visible: true
---

# Geta.Optimizely.Extensions

The old package *Geta.EPi.Extensions* has been renamed to *Geta.Optimizely.Extensions*. Install it using Nuget package manager or from the command line:

```
Install-Package Geta.Optimizely.Extensions
```

The package has almost the same functionality as the previous version. The only change is that we have removed `XForms` related functionality as it is not supported in *Optimizely 12* anymore.

For more information check the [Github page](https://github.com/Geta/geta-optimizely-extensions).


# Sitemaps and Sitemaps.Commerce

The old packages *Geta.SEO.Sitemaps* and *Geta.SEO.Sitemaps.Commerce* has been renamed to *Geta.Optimizely.Sitemaps* and *Geta.Optimizely.Sitemaps.Commerce*. Install those using Nuget package manager or from the command line:

```
Install-Package Geta.Optimizely.Sitemaps
Install-Package Geta.Optimizely.Sitemaps.Commerce
```

After installation, you have to configure it. Register the *Sitemaps* and/or *Sitemaps Commerce* in the service collection first:

```
services.AddSitemaps(x =>
{
  x.EnableLanguageDropDownInAdmin = false;
  x.EnableRealtimeCaching = true;
  x.EnableRealtimeSitemap = false;
});
services.AddSitemapsCommerce();
```

Then make sure that you have razor pages mapped:

```
app.UseEndpoints(endpoints =>
{
    endpoints.MapRazorPages();
});
```

After that, you will see a new top menu item for the *Sitemaps* in the *Optimizely* administration UI. There is a new administration user interface, but it has the same functionality as the old one.

For more information check the [Github page](https://github.com/Geta/geta-optimizely-sitemaps).

# Geta.Optimizely.GoogleProductFeed

The package *Geta.GoogleProductFeed* has been renamed to *Geta.Optimizely.GoogleProductFeed* so that all the naming is consistent with other *Optimizely* packages. Install it using Nuget package manager or from the command line:

```
Install-Package Geta.Optimizely.GoogleProductFeed
```

After installation, you have to configure it. Register the *GoogleProductFeed* in the service collection first:

```
services.AddGoogleProductFeed(x =>
{
    x.ConnectionString = _configuration.GetConnectionString("EPiServerDB");
});
```

Then you have to create your `FeedBuilder`. See the [documentation](https://github.com/Geta/geta-optimizely-googleproductfeed).

Once, it is created register it in the service collection:

```
services.AddTransient<FeedBuilder, MyFeedBuilder>();
```

For more information check the [Github page](https://github.com/Geta/geta-optimizely-googleproductfeed).

# Geta.Optimizely.ContentTypeIcons

We had a package *Geta.Epi.FontThumbnail* for the older Episerver/Optimizely versions. The package name did not describe what it was. So we renamed it to *Geta.Optimizely.ContentTypeIcons*. Install it using Nuget package manager or from the command line:

```
Install-Package Geta.Optimizely.ContentTypeIcons
```

After installation, you have to configure it. Register the *ContentTypeIcons* in the service collection first:

```
services.AddContentTypeIcons(x =>
{
    x.EnableTreeIcons = true;
    x.ForegroundColor = "#ffffff";
    x.BackgroundColor = "#02423F";
    x.FontSize = 40;
    x.CachePath = "[appDataPath]\\thumb_cache\\";
    x.CustomFontPath = "[appDataPath]\\fonts\\";
});
```

Now you can start using it by adding the `ContentTypeIcon` attribute to your content types. For example:

```
[ContentTypeIcon(FontAwesome5Brands.Github)]
```

This attribute on a page type will show you a *Github* icon when you will create a new page of this page type. Also, if you have the `EnableTreeIcons` setting enabled, you will see the icon in the content tree.

You can also use the `TreeIcon` attribute to override the behavior for the content tree. You can set a different icon or ignore the icon completely:

```
[TreeIcon(Ignore = true)]
[TreeIcon(FontAwesome5Solid.CheckDouble)]
```

For more information check the [Github page](https://github.com/Geta/geta-optimizely-contenttypeicons).