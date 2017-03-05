---
layout: post
title: "Configuring Razor view support for Episerver modules"
description: >
  <t render="markdown">
  I have not created an Episerver module before. When I started on one last week, I found that there are no examples with Razor views. After looking and trying to create a module, concluded that it even doesn't support Razor views by default. But I figured out one way which works.
  </t>
category:
tags: [EPiServer]
date: 2017-03-05
visible: true
---

At first, I have created one view for my controller, layout and required configuration for Razor views as in usual ASP.NET MVC application. Such structure looks like in the image below.

<img src="/img/2017-03/module_structure.png" class="img-responsive" alt="Episerver module structure in the Visual Studio's Solution Explorer">

And here is the controller I used.

```
public class CustomerController : Controller
{
    public ActionResult Index()
    {
        return View();
    }
}
```

In the beginning, I could not understand why it can't resolve the view. I looked into the configured view locations and found that _Episerver_ looks for the view in the correct module but by virtual path.

```
/cms/Customer/Views/Customer/
```

I missed that the paths supported only _.aspx_ and _.ascx_ files. After I had noticed it, I tried to set the view path explicitly in the controller.

```
return View("~/cms/Customer/Views/Customer/Index.cshtml");
```

Now I got a different exception which said that my view doesn't inherit from _WebViewPage_ or _WebViewPage&lt;TModel&gt;_.

Then I tried to use an explicit path to the module, and it did work.

```
return View("~/modules/_protected/Customer/Views/Customer/Index.cshtml");
```

While it works, I didn't want to write "hardcoded" paths in the controller.

# Solution

The solution is registering additional view template paths for _Episerver_ shell modules. _Episerver_ has _ShellWebFormViewEngine_ which does view resolving. So we have to create one for _Razor_ views. It should inherit from _RazorViewEngine_ instead of _WebFormViewEngine_. The rest of the code is same as for the _ShellWebFormViewEngine_.

```
public class ShellRazorViewEngine : RazorViewEngine
{
    private readonly ConcurrentDictionary<string, bool> _cache = new ConcurrentDictionary<string, bool>();

    public ShellRazorViewEngine()
    {
        ViewLocationCache = new DefaultViewLocationCache();
    }

    protected override bool FileExists(
        ControllerContext controllerContext, string virtualPath)
    {
        if (controllerContext.HttpContext != null 
            && !controllerContext.HttpContext.IsDebuggingEnabled)
            return _cache.GetOrAdd(
                virtualPath, 
                p => HostingEnvironment.VirtualPathProvider.FileExists(virtualPath));
        return HostingEnvironment.VirtualPathProvider.FileExists(virtualPath);
    }
}
```

The view engine doesn't register paths for modules. A module initializer does it. There is a particular module initializer for _Web Forms_, so we have to create one also for _Razor_. The module initializer looks for a registered module view engine collection in the _MVC_ view engine collection. As there could be only one type of such module engine collection registered, we have to create another one by inheriting from the original.

```
public class RazorModuleViewEngineCollection : ModuleViewEngineCollection
{
}
```

Now, we are ready to implement our module initializer.

```
public class RazorModuleInitializer
{
    private readonly ViewEngineCollection _viewEngines;

    public RazorModuleInitializer(ViewEngineCollection viewEngines)
    {
        _viewEngines = viewEngines;
    }

    public void RegisterModules(IEnumerable<ShellModule> modules)
    {
        var aggregatingViewEngine = GetOrCreateAggregatingViewEngine();
        foreach (var module in modules)
        {
            var viewEngine = GetViewEngine(module);
            aggregatingViewEngine.Add(module.Name, viewEngine);
        }
    }

    private ModuleViewEngineCollection GetOrCreateAggregatingViewEngine()
    {
        var engineCollection = _viewEngines
            .OfType<RazorModuleViewEngineCollection>()
            .FirstOrDefault();
        if (engineCollection != null) return engineCollection;

        var moduleEngineCollection = 
            _viewEngines.OfType<ModuleViewEngineCollection>().First();
        var index =
            _viewEngines.IndexOf(moduleEngineCollection);
        engineCollection = new RazorModuleViewEngineCollection();
        _viewEngines.Insert(index + 1, engineCollection);
        return engineCollection;
    }

    private static IViewEngine GetViewEngine(ShellModule module)
    {
        var webFormViewEngine = new ShellRazorViewEngine
        {
            MasterLocationFormats = new[]
            {
                $"~/modules/_protected/{module.Name}/Views/{{1}}/{{0}}.cshtml",
                $"~/modules/_protected/{module.Name}/Views/Shared/{{0}}.cshtml",
            },
            ViewLocationFormats = new[]
            {
                $"~/modules/_protected/{module.Name}/Views/{{1}}/{{0}}.cshtml",
                $"~/modules/_protected/{module.Name}/Views/Shared/{{0}}.cshtml"
            }
        };
        webFormViewEngine.PartialViewLocationFormats = 
            webFormViewEngine.ViewLocationFormats;
        webFormViewEngine.ViewLocationCache =
            new ModulesViewLocationCache(module.Name);
        return webFormViewEngine;
    }
}
```

At first, this module initializer tries to get our _Razor-specific_ module view engine collection from the _MVC_ registered view engines. If it is not yet registered, it creates new one and registers next to the _WebForms_ module view engine collection. Once it retrieves the module view engine collection, it registers view engine for each module. Here we use our _ShellRazorViewEngine_ and set it's view location paths.

The last step is initialization. We should create an initialization module which has a dependency on _ShellInitialization_ that we should be sure that the main module initialization already happened. Then retrieve all modules and register _Razor_ view locations for those using _RazorModuleInitializer_.

```
[InitializableModule]
[ModuleDependency(typeof(ShellInitialization))]
public class ShellRazorSupportInitialization : IInitializableModule
{
    private IServiceLocator _locator;

    public void Initialize(InitializationEngine context)
    {
        _locator = context.Locate.Advanced;
        var list = GetConfiguredModules(_locator).ToList();
        var initializer = _locator.GetInstance<RazorModuleInitializer>();
        initializer.RegisterModules(list);
    }

    public void Uninitialize(InitializationEngine context)
    {
    }

    private static IEnumerable<ShellModule> GetConfiguredModules(
        IServiceLocator locator)
    {
        return ShellModule
            .MergeDuplicateModules(
                locator.GetAllInstances<IModuleProvider>()
                .SelectMany(p => p.GetModules()));
    }
}
```

Now we are ready to implement our _Episerver_ modules with _Razor_ views.
