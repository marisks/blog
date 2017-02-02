---
layout: post
title: "Razor view engine for feature folders"
description: >
  <t render="markdown">
  There are some resources available which explain how to configure razor view engine to support feature folders. But most of these resources describe how to do it in an ordinary _MVC_ project. Episerver projects have some limitations which I took into account in this article. This article also covers a sub-folder support.
  </t>
category:
tags: [EPiServer]
date: 2017-02-03
visible: true
---

For an _MVC_ application to find views, it uses _RazorViewEngine_. The default implementation looks for views in the _Views_ folder in the root of the project or within _MVC_ _Area_. But there is a way to create an own _RazorViewEngine_ implementation.

The easiest way is to inherit your custom view engine from _RazorViewEngine_ and set _ViewLocationFormats_, _MasterLocationFormats_, _PartialViewLocationFormats_ properties (there are also other properties for _Areas_)  in the constructor with your view location formats. The location format has two format items: {0} - action name (also content type name in Episerver) and {1} - controller name.

```
public class CustomViewEngine : RazorViewEngine
{
    public CustomViewEngine()
    {
        ViewLocationFormats = "~/Views/{1}/{0}.cshtml";
        MasterLocationFormats = "~/Views/{1}/{0}.cshtml";
        PartialViewLocationFormats = "~/Views/{1}/{0}.cshtml";
    }
}
```

Then register your view engine in the _Global.asax_ on the _Application__Start_ event.

```
protected void Application_Start()
{
    ViewEngines.Engines.Insert(0, new CustomViewEngine());
}
```

# Basic feature folder support

A basic support for feature folders is simple. In this example, I registered several different ways how views can be resolved under the _Features_ folder. _ViewLocationFormats_, _MasterLocationFormats_ and _PartialViewLocationFormats_ share same view location formats. I also append these to the default ones.

```
public class FeatureViewEngine : RazorViewEngine
{
    public FeatureViewEngine()
    {
        var featureFolderViewLocationFormats = new[]
        {
            "~/Features/{0}.cshtml",
            "~/Features/{1}/{0}.cshtml",
            "~/Features/{1}/{1}.cshtml",
            "~/Features/{1}/Views/{0}.cshtml",
            "~/Features/{1}/Views/{1}.cshtml",
            "~/Features/Shared/{0}.cshtml",
            "~/Features/Shared/Views/{0}.cshtml"
        }
        .ToArray();

        ViewLocationFormats =
          ViewLocationFormats.Union(featureFolderViewLocationFormats).ToArray();
        MasterLocationFormats =
          MasterLocationFormats.Union(featureFolderViewLocationFormats).ToArray();
        PartialViewLocationFormats =
          PartialViewLocationFormats.Union(featureFolderViewLocationFormats).ToArray();
    }
}
```

This configuration supports these view locations:
- _"~/Features/{0}.cshtml"_ - looks for views which match action name or content type name in the root of the _Features_ folder.
- _"~/Features/{1}/{0}.cshtml"_ - looks for views in the folder which matches controller name and the view matches action name.
- _"~/Features/{1}/{1}.cshtml"_ - looks for views in the folder which matches controller name and the view matches controller name.
- _"~/Features/{1}/Views/{0}.cshtml"_ - looks for views in the folder which matches controller name and the view matches action name in the _Views_ folder.
- _"~/Features/{1}/Views/{1}.cshtml"_ - looks for views in the folder which matches controller name and the view matches controller name in the _Views_ folder.
- _"~/Features/Shared/{0}.cshtml"_ - looks for views in the _Shared_ folder and the view matches action name or content type name in the root of the _Shared_ folder.
- _"~/Features/Shared/Views/{0}.cshtml"_ - looks for views in the _Shared_ folder and the view matches action name or content type name in the _Views_ folder.

> NOTE: There is one "bug" in _Episerver_ (at least I perceive it like that) that if you call your view same as a content type, then it will not pick content type's controller but will try to render view directly by matching content type name to the view name. Initially, it was only for blocks but it caused also pages to render incorrectly and throw exceptions.

Now it looks quite good. But there are some issues.

First of all, when working with _Episerver_ it is common to name controller as a content type plus _Controller_ postfix. For example, _ArticlePage_ content type with _ArticlePageController_. This way feature folder has to be called _ArticlePage_ but it would be nicer to call it _Articles_. Also, namespace with the same name as the content type will have naming conflicts.

This configuration also doesn't support sub-features.

# Advanced feature folder support

To be able to add feature folders with any name, a view engine should scan all folders in the _Features_ folder and register view location format for each of it. It should include all possible view location formats you might need for a single folder. Below is a method which does that.

```
private IEnumerable<string> FeatureFolders()
{
    var rootFolder = HostingEnvironment.MapPath("~/Features/");
    if (rootFolder == null)
    {
        return Enumerable.Empty<string>();
    }
    var subFolders = Directory.GetDirectories(rootFolder).Select(GetDirectoryName);
    return subFolders
        .SelectMany(
            dir => new[]
            {   
                // No controller, page type = view name
                $"~/Features/{dir}/Views/{{0}}.cshtml",

                // With MVC controller, doesn't work with content types,
                // controller name = view name
                $"~/Features/{dir}/Views/{{1}}.cshtml",

                // With any controller, controller name + action name = view name
                $"~/Features/{dir}/Views/{{1}}{{0}}.cshtml",

                // Sub-feature, controller name = sub-folder name, action = view name
                $"~/Features/{dir}/{{1}}/Views/{{0}}.cshtml",

                // Sub-feature, controller name = sub-folder name,
                // controller name + action name = view name
                $"~/Features/{dir}/{{1}}/Views/{{1}}{{0}}.cshtml"
            });
}

private string GetDirectoryName(string path)
{
    return new DirectoryInfo(path).Name;
}
```

And then append these folders to the other view location formats.

```
public FeatureViewEngine()
{
    var featureFolderViewLocationFormats = new[]
    {
        "~/Features/{0}.cshtml",
        "~/Features/{1}/{0}.cshtml",
        "~/Features/{1}/{1}.cshtml",
        "~/Features/{1}/Views/{0}.cshtml",
        "~/Features/{1}/Views/{1}.cshtml",
        "~/Features/Shared/Views/{0}.cshtml"
    }
    .Union(FeatureViewEngine())
    .ToArray();

    ViewLocationFormats =
      ViewLocationFormats.Union(featureFolderViewLocationFormats).ToArray();
    MasterLocationFormats =
      MasterLocationFormats.Union(featureFolderViewLocationFormats).ToArray();
    PartialViewLocationFormats =
      PartialViewLocationFormats.Union(featureFolderViewLocationFormats).ToArray();
}
```

This approach still has several issues.

The first one is that views for an _Episerver_ content should not be called as _Index_ or has the same name as the content type. That is the reason why there is a location format where view name consists of controller and action name.

Another issue is related to the sub-feature folder naming. Sub-feature folder still should be called with the same name as a controller.

View names also should be unique. That's why _Index_ can't be used as a view name.

_Visual Studio_ will show you warnings that it is unable to resolve views.

As there are a lot of view location formats registered, there might be some performance issues when looking for the right view. I haven't measured that but for now didn't have any issues.

# Summary

Even with all disadvantages, organizing views in the feature folders has one big benefit - maintainability. Now views are close to the code which uses these.

Here is a final version of the view engine:
```
public class FeatureViewEngine : RazorViewEngine
{
    public FeatureViewEngine()
    {
        var featureFolderViewLocationFormats = new[]
        {
            "~/Features/{0}.cshtml",
            "~/Features/{1}/{0}.cshtml",
            "~/Features/{1}/{1}.cshtml",
            "~/Features/{1}/Views/{0}.cshtml",
            "~/Features/{1}/Views/{1}.cshtml",
            "~/Features/Shared/Views/{0}.cshtml"
        }
        .Union(FeatureViewEngine())
        .ToArray();

        ViewLocationFormats =
          ViewLocationFormats.Union(featureFolderViewLocationFormats).ToArray();
        MasterLocationFormats =
          MasterLocationFormats.Union(featureFolderViewLocationFormats).ToArray();
        PartialViewLocationFormats =
          PartialViewLocationFormats.Union(featureFolderViewLocationFormats).ToArray();
    }

    private IEnumerable<string> FeatureFolders()
    {
        var rootFolder = HostingEnvironment.MapPath("~/Features/");
        if (rootFolder == null)
        {
            return Enumerable.Empty<string>();
        }
        var subFolders = Directory.GetDirectories(rootFolder).Select(GetDirectoryName);
        return subFolders
            .SelectMany(
                dir => new[]
                {
                    // No controller, page type = view name
                    $"~/Features/{dir}/Views/{{0}}.cshtml",

                    // With MVC controller, doesn't work with content types,
                    // controller name = view name
                    $"~/Features/{dir}/Views/{{1}}.cshtml",

                    // With any controller, controller name + action name = view name
                    $"~/Features/{dir}/Views/{{1}}{{0}}.cshtml",

                    // Sub-feature, controller name = sub-folder name, action = view name
                    $"~/Features/{dir}/{{1}}/Views/{{0}}.cshtml",

                    // Sub-feature, controller name = sub-folder name,
                    // controller name + action name = view name
                    $"~/Features/{dir}/{{1}}/Views/{{1}}{{0}}.cshtml"
                });
    }

    private string GetDirectoryName(string path)
    {
        return new DirectoryInfo(path).Name;
    }
}
```
