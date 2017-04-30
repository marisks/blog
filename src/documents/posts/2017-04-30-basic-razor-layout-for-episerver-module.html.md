---
layout: post
title: "Basic Razor layout for Episerver module"
description: >
  <t render="markdown">
  When creating Episerver modules, you need a common layout for your pages. You can find different examples of Web Forms layout for Episerver modules, but as now with [Geta's shell razor support package](http://marisks.net/2017/03/19/enable-razor-views-in-episerver-modules-with-shellrazorsupport-package/) it is possible to create Razor views, you need a Razor layout.
  </t>
category:
tags: [EPiServer]
date: 2017-04-30
visible: true
---

I took a _Web Forms_ page from the [Valdis' LocalizationProvider project](https://github.com/valdisiljuconoks/LocalizationProvider/blob/162666398d9deea377492b462248c04ced739489/src/DbLocalizationProvider.AdminUI.EPiServer/modules/_protected/DbLocalizationProvider.AdminUI.EPiServer/Views/LocalizationResources/Index.aspx) as a base for my _Razor_ layout but simplified it.

```
@using EPiServer.Framework.Web.Resources
@using EPiServer.Shell
@using EPiServer.Shell.Navigation

<!DOCTYPE html>

<html>
<head runat="server">
    <meta name="viewport" content="width=device-width" />
    <title>@ViewBag.Title</title>

    @Html.Raw(ClientResources.RenderResources("ShellCore"))
    @Html.Raw(ClientResources.RenderResources("ShellWidgets"))
    @Html.Raw(ClientResources.RenderResources("ShellCoreLightTheme"))
    @Html.Raw(ClientResources.RenderResources("ShellWidgetsLightTheme"))
    @Html.Raw(ClientResources.RenderResources("Navigation"))
    @Html.CssLink(
        UriSupport.ResolveUrlFromUIBySettings("App_Themes/Default/Styles/system.css"))
    @Html.CssLink(
        UriSupport.ResolveUrlFromUIBySettings("App_Themes/Default/Styles/ToolButton.css"))
</head>
<body class="claro">
    @Html.Raw(Html.GlobalMenu())
    <div class="epi-contentContainer epi-padding">
        @RenderBody()
    </div>
</body>
</html>
```

Here I am including all required resources for Episerver shell and additionally adding some styles for buttons, form fields etc. by including _system.css_ and _ToolButton.css_. If you are creating your own styling, you do not need these _CSS_ files. You can include your own resources like this:

```
@Html.CssLink(
    Paths.ToClientResource(typeof(MyModuleClass), "ClientResources/css/styles.css"))
@Html.Raw(
    Html.ScriptResource(
        Paths.ToClientResource(typeof(MyModuleClass), "ClientResources/js/scripts.js")))
```

On the first line, I am including a _CSS_ file which is located relatively to my module's root. You have to provide a type of some class in your module as a first parameter to the _Paths.ToClientResource_ method that it can detect the correct path. There are some overloads which accept string module name and assembly instance, but I find it easier and more maintainable to pass a type of the class. On the second line, I am doing same, but for the script file.

