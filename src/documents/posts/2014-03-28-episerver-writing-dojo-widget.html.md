---
layout: post
title: "# EPiServer: writing Dojo widget"
description: ""
category: [# EPiServer]
tags: [EPiServer, Dojo]
date: 2014-03-28
---

<p class="lead">
I was working on open source library <a href="https://github.com/Geta/Tags">Geta Tags</a> and wanted to improve editor user experience. Starting from EPiServer 7, EPiServer uses Dojo for administrative interface. Googling for articles on how to create Dojo widgets for EPiServer didn't get expected results that I had to get through all the Dojo creation process through trial and errors. In this article I will try to describe how to create simple and more advanced Dojo widgets for EPiServer.
</p>

# Problem
Dojo provides lot of "UI controls" which is used by EPiServer, but there are times when you need more advanced user experience. In my case I had to create user friendly tag selection. I found several articles ([here](http://world.episerver.com/Blogs/Linus-Ekstrom/Dates/2012/10/Creating-a-Dojo-based-component/) and [here](http://world.episerver.com/Blogs/Linus-Ekstrom/Dates/2013/12/Auto-suggest-editor-in-EPiServer-75/)) how to create and extend Dojo widgets - those did not explain much why and how those work, but was good starting point.

For Geta Tags I started with simple widget which extended [Dojo MultiComboBox](http://dojotoolkit.org/reference-guide/1.9/dojox/form/MultiComboBox.html). While it work, it didn't provide user firiendly interface. So I started to look for solutions. I Googled for ready widgets for Dojo and found nothing, but found a lot of jQuery/jQuery UI plugins. So the only task left was how to make jQuery plugin to work with Dojo in EPiServer.

# Dojo widgets
There is a great book about Dojo - [Mastering Dojo: JavaScript and Ajax Tools for Great Web Experiences](http://pragprog.com/book/rgdojo/mastering-dojo). This book describes how to work, setup Dojo and also how to extend it.

Here is widget lifetime described by the book:
- widget constructor is called
- mixin parameters applied
- postMixinProperties() method called
- id assignment, if not provided
- buildRendering() method called
- copy attribute map
- postCreate() method called
- expand child widgets
- startup() method called

Extensibility points are these for methods:
- _postMixinProperties_: it is called after the properties have been initialized. Override default properties or add custom properties in this method.
- _buildRendering_: it gets the template and fills in the details. Usually you will not need to override this method. Default implementation is provided by [dijit._Templated](https://dojotoolkit.org/reference-guide/1.9/dijit/_Templated.html#dijit-templated). If you want to handle rendering yourself, then override this method.
- _postCreate_: this is the main extensibility point. Widget has been rendered, but not it's child widgets and [containerNode](https://dojotoolkit.org/documentation/tutorials/1.7/templated/#containerNode). You can set custom attributes, access _this.domNode_ (reference to parent node of the widget itself) and maipulate it here.
- _startup_: this is called when widget and all child widgets have been created. This is the place where to access child widgets.

For more information on widget lifetime see these articles:
- [Understanding _Widget](http://dojotoolkit.org/documentation/tutorials/1.6/understanding_widget/)
- [Chapter 12. Dijit Anatomy and Lifecycle](http://chimera.labs.oreilly.com/books/1234000001819/ch12.html)
- [_WidgetBase](https://dojotoolkit.org/reference-guide/1.9/dijit/_WidgetBase.html)

There are two ways how to build your widget - extend existing one or build new widget from scratch. I will explain how to extend existing widget, because it is the easier way to get something done. For creating new widget see article [Writing Your Own Widget](https://dojotoolkit.org/reference-guide/1.9/quickstart/writingWidgets.html).

# Minimal implementation
To create new widget for EPiServer you will need:
- Dojo widget JavaScript implementation
- EPiServer editor descriptor class for your widget
- configure module.config properly

## Dojo widget
Let's start with simple Dojo widget. First version of [Dojo widget for Geta Tags](https://github.com/Geta/Tags/blob/v0.9.8/ClientResources/Scripts/Editors/TagsSelection.js) extends Dojo [MultiComboBox](http://dojotoolkit.org/reference-guide/1.9/dojox/form/MultiComboBox.html). It allows to select multiple values from autosuggestion and adds them as comma separated string to the input.

    define([
        "dojo/_base/declare",
        "dojo/store/JsonRest",
        "dojox/form/MultiComboBox"
    ],
    function (
        declare,
        JsonRest,
        MultiComboBox) {

        return declare([MultiComboBox], {
            postMixInProperties: function () {
                var store = new JsonRest({ target: '/getatags' });
                this.set("store", store);
                // call base implementation            
                this.inherited(arguments);
            },
            _setValueAttr: function (value) {
                value = value || '';
                if (this.delimiter && value.length != 0) {
                    value = value + this.delimiter + " ";
                    arguments[0] = this._addPreviousMatches(value);
                }
                this.inherited(arguments);
            }
        });
    });

Dojo uses AMD for structuring the application. First step is to call _define_ function and define what are your dependencies. In this case I am defining _declare_, _JsonRest_ and _MultiComboBox_ as my dependencies. All three are included in Dojo package and available in EPiServer. You can find all available Dojo modules in EPiServer VPP/appData folder: _Modules\Shell\3.0.1209\ClientResources_. Dojo module dependencies are passed in as a first parameter of _define_ function. Those are defined as an array of string paths to the modules. Second parameter of _define_ function is function which defines the module. The function has arguments with dependencies defined previously.

This function then should call _declare_ function which declares your widget. As a first parameter it takes an array of objects which will be mixed in to your new widget. You can think about this as extending the object you pass in. In this case we will use _MultiComboBox_. The second argument is object which defines your widget. Here you can override methods and properties of your base widget.

For Geta Tags I needed to set _store_ property for _MultiComboBox_. The right method to override in this case is _postMixInProperties_. _store_ property defines the source for autosuggestion. To use some server side API as a source you have to define [_JsonRest_](http://dojotoolkit.org/reference-guide/1.9/dojo/store/JsonRest.html) object by passing in options object which should contain property - _target_ with URL to the resource. Then use _set_ method of base widget to set the _store_ property. The last step is to call [base implementation](http://dojotoolkit.org/reference-guide/1.9/dojo/_base/declare.html#calling-superclass-methods) of _postMixiInProperties_ by calling [_inherited(arguments)_](http://dojotoolkit.org/reference-guide/1.9/dojo/_base/declare.html#inherited) method that base widget can do it's stuff.

_MultiComboBox_ has one issue that it do not handle the case when value provided to it is not defined. EPiServer usually do not provide initial value for the field and so _MultiComboBox_ can't handle it. To solve the issue I redefined __setValueAttr_ function of _MultiComboBox_ to set empty value if it is not defined. You can redefine your base widget methods if needed similar way, but be careful - those methods are _internal_ and might change in future versions of Dojo.

The last (or first) step is to place the JavaScript file in correct folder. Alls client scripts for EPiServer modules should be placed in _ClientResources_ folder. I would suggest to create new folder with the name of your module and place JavaScript implementation there. For example, _ClientResources/Simple.Module/_ folder. First versions of Geta Tags used _ClientResources/Scripts/Editors_ folder, but it might collide with other modules. After placing JavaScript module in the correct place, you should configure it to be found. First step is to add path to module in _module.config_.

## <a name="module_config"></a>module.config

_module.config_ is configuration file for modules used in your project and should be placed in the root of your project (for shell modules in the root folder of [shell module](http://world.episerver.com/Documentation/Items/Developers-Guide/EPiServer-Framework/75/Modules/Modules/)). For more information see [module.config documentation](http://world.episerver.com/Documentation/Items/Developers-Guide/EPiServer-Framework/75/Configuration/Configuring-moduleconfig/).

Basic configuration for Dojo module is simple - you have to register assembly of the project which defines [editor descriptor](#editor_descriptor) and register dojo module path. First version of Geta Tags module.config looked like this:

    <?xml version="1.0" encoding="utf-8"?>
    <module>
      <assemblies>
        <add assembly="Geta.Tags" />
      </assemblies>

      <dojoModules>
        <add name="geta" path="Scripts" />
      </dojoModules>
    </module>

First of all I am defining Geta.Tags assembly and then dojo module - setting name of the module and path to the folder which contains dojo module scripts. The folder is relative to _ClientResources_ folder. In this case folder path is - _ClientResources/Scripts/_.

## <a name="editor_descriptor"></a>Editor descriptor

Last step is creating editor descriptor. This class _connects_ EPiServer content type property with your Dojo module.

Here is the Geta Tags editor descriptor:

    [EditorDescriptorRegistration(TargetType = typeof(string), UIHint = "Tags")]
    public class TagsEditorSelectionEditorDescriptor : EditorDescriptor
    {
        public TagsEditorSelectionEditorDescriptor()
        {
            ClientEditingClass = "geta.editors.TagsSelection";
        }
    }

First of all create the class which derives from EditorDescriptor class. Decorate class with EditorDescriptorRegistration attribute and provide the type of the property and UIHint which will be used for properties which will use your custom Dojo module.

Then in the constructor of the class set _ClientEditingClass_ which is in form of _module name_._path relative to module root_._Dojo module file name_. For Geta Tags this is _geta.editors.TagsSelection_:
- _geta_ is the module name we defined in [_module.config_](#module_config)
- _editors_ is the folder relative to _Scripts_ folder which is defined as the root folder for module in [_module.config_](#module_config)
- _TagsSelection_ is Dojo module file name without extension

After defining editor descriptor you can use your custom property in some content type:

    [UIHint("Tags")]
    public virtual string Tags { get; set; }

Just decorate your property with _UIHint_ attribute with value you defined in editor descriptor. Now custom Dojo widget will be used when you start editing the field.

# Advanced implementation
Describe how to reference scripts and styles, how to use jQuery plugin with Dojo, describe referencing Dojo AMD libraries.

# Packaging
Describe nuget package creation - what is needed, command line call and also automating with TeamCity.

Link: [link](https://github.com)
Bold: **bold**
Italic: _italic_
Heading: # Heading


