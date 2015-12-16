---
layout: post
title: "Custom EPiServer Forms field"
description: "EPiServer recently released new add-on - EPiServer Forms. It is a new way how to work with the forms in EPiServer. Forms have different form elements available - Text (input), Text area, Number etc., but it misses basic label, heading and text elements to display static information for form users. Also, quite often there are requirements to provide additional information based on page's context - for example, on the product page, it might be required to post product code and name. This article describes basic steps to create custom EPiServer Forms field."
category: [EPiServer]
tags: [EPiServer]
date: 2015-12-14
visible: true
---

<p class="lead">
_EPiServer_ recently released new add-on - <a href="http://webhelp.episerver.com/15-5/EN/addons/episerver-forms/episerver-forms.htm">_EPiServer Forms_</a>. It is a new way how to work with the forms in _EPiServer_. _Forms_ have different form elements available - _Text (input)_, _Text area_, _Number_ etc., but it misses basic label, heading and text elements to display static information for form users. Also, quite often there are requirements to provide additional information based on page's context - for example, on the product page, it might be required to post product code and name. This article describes basic steps to create custom _EPiServer Forms_ field.
</p>

First of all, you have to install _EPiServer Forms_ add-on into your project using _NuGet_:

    Install-Package EPiServer.Forms

After installing it, you should be able to create forms in _EPiServer's_ administrative interface.

Now create new form element type by creating a new class which inherits from _ElementBlockBase_ and add _ContentType_ attribute as for other content types. In the example below, I am creating new form element which has current page's name as a property.

    [ContentType(GUID = "9AD6588C-A85A-4FD2-A20E-2B1778552648")]
    public class PageNameFieldBlock : ElementBlockBase
    {
        public string PageName
        {
            get
            {
                var pageHandler = ServiceLocator.Current.GetInstance<PageRouteHelper>();
                return pageHandler.Page.PageName;
            }
        }
    }

If you require extending existing element, then you can inherit from existing element's type and implement your custom functionality.

Next step is defining the view. When using default _Alloy Tech_ site's view engine, the view should be placed in the _~/Views/Shared/Blocks_ folder with the same name as field element's class name. For the _PageNameFieldBlock_ element the view should be called _PageNameFieldBlock.cshtml_.

    @model EPiFormsTesting.Models.PageNameFieldBlock

    <h1>@Model.PageName</h1>

    <input name="@Model.FormElement.Code" id="@Model.FormElement.Guid" type="hidden"
           value="@Model.PageName"
           class="Form__Element FormHidden FormHideInSummarized" @Html.Raw(Model.FormElement.AttributesString) />

Here I am displaying the page name and also creating a hidden element to post it. For _EPiServer Forms_ to correctly handle form data, HTML element's name should have a value of the model property _FormElement.Code_ and HTML element's id should have a value of the model property _FormElement.Guid_. Also, you should render additional attributes from the model property _FormElement.AttributesString_. You can find more examples in the _~/modules/_protected/EPiServer.Forms/Views/Blocks_ folder. The views in this folder are _.ascx_ files but are quite easy to understand and translate to _Razor_ files.

Now the new field element should be available when creating new forms. I have created sample form with several fields including a field from a newly created element.

<img src="/img/2015-12/episerver-form-with-page-name.png" class="img-responsive" alt="EPiServer Form with page name element">

After posting the form, posted page name appears in form submissions.

<img src="/img/2015-12/episerver-form-page-name-submissions.png" class="img-responsive" alt="EPiServer Form page name submissions">
