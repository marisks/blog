---
layout: post
title: "Registering multiple Dojo modules"
description: "EPiServer provides a way how to initialize Dojo modules in the module.config file. Unfortunately, you can set only one module initializer. In this article, I will describe how to solve this issue."
category:
tags: [EPiServer]
date: 2016-08-08
visible: true
---

I had an issue with registering multiple _Dojo_ modules after installing [MenuPin](https://github.com/davidknipe/MenuPin) package. My modules stopped working. After some investigation, I found the solution.

First of all, create another initializer under _ClientResources_ - for now just a file for the initializer. I called it _Initializer.js_.

<img src="/img/2016-08/dojo-module-initializers.png" alt="Module initializers in the ClientResources" class="img-responsive">

Now register all initializers in the _module.config_.

```
<?xml version="1.0" encoding="utf-8"?>
<module>
  <assemblies>
    <add assembly="MyApp.Web" />
  </assemblies>
  <dojo>
    <paths>
      <add name="app" path="Scripts" />
      <add name="editors" path="Scripts/Editors" />
      <add name="menupin" path="Scripts/MenuPin" />
    </paths>
  </dojo>
  <clientModule initializer="app.Initializer">
    <moduleDependencies>
      <add dependency="CMS" type="RunAfter" />
    </moduleDependencies>
  </clientModule>
</module>
```

First of all, register _Dojo_ modules in the _module.config_ under _dojo/paths_ section. Here I am registering three modules - _app_, _editors_ and _menupin_ with appropriate paths. Next, set default initializer on _clientModule_ tag's _initializer_ attribute. In my case it is initializer under _app_ module - _app.Initializer_.

The last step is creating a default initializer itself in the _Initializer.js_ file.

```
define([
// Dojo
    "dojo",
    "dojo/_base/declare",
//CMS
    "epi/_Module",
    "epi/dependency",
    "epi/routes",
    "app/MyInitializer",
    "menupin/MenuPinInit"
], function (
// Dojo
    dojo,
    declare,
//CMS
    _Module,
    dependency,
    routes,
    MyInitializer,
    MenuPinInit
) {

    return declare("app.Initializer", [_Module], {
        // summary: Module initializer for the default module.

        initialize: function () {

            this.inherited(arguments);

            var myinitializer = new MyInitializer();
            myinitializer.initialize();

            var minitializer = new MenuPinInit();
            minitializer.initialize();
        }
    });
});
```

Basically, it is standard _Dojo_ module with an _initialize_ method. As we need to call other module initializers - _MyInitializer_ under _app_ and _MenuPinInit_ under _menupin_, we have to request those as dependencies. So in the definition of the module add _"app/MyInitializer"_ and _"menupin/MenuPinInit"_ where the first part is module name and second - initializer name. Initializers are module constructors - you can create new initializer objects in the _initialize_ method and call _initialize_ methods on these objects.
