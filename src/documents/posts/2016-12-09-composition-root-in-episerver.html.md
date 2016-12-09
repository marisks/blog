---
layout: post
title: "Composition root in EPiServer"
description: "In the previous article, I described different dependency injection aspects and how those are applied in EPiServer. This article shows how composition root can be created for EPiServer MVC controllers."
category:
tags: [EPiServer]
date: 2016-12-09
visible: true
---

<p class="lead">
In the previous article, I described different dependency injection aspects and how those are applied in EPiServer. This article shows how composition root can be created for EPiServer MVC controllers.
</p>

A composition root in the _MVC_ application is implemented with custom _IControllerFactory_. An implementation of this interface from scratch might be too complicated but it is possible to inherit from _DefaultControllerFactory_ and override _GetControllerInstance_ method.

In _EPiServer_ there is a custom implementation of _IControllerFactory_ - _ControllerTypeControllerFactory_ which adds _EPiServer_ specific controller type detection. So when implementing your own composition root it is wise to inherit from _ControllerTypeControllerFactory_. As with _DefaultControllerFactory_, override _GetControllerInstance_ method.

```
public class CompositionRoot : ControllerTypeControllerFactory
{
    protected override IController GetControllerInstance(
      RequestContext requestContext, Type controllerType)
    {
        if (controllerType == null)
            throw new HttpException(
                404,
                string.Format(
                    CultureInfo.CurrentCulture,
                    "No controller found for path: {0}",
                    requestContext.HttpContext.Request.Path as object));
        if (!typeof(IController).IsAssignableFrom(controllerType))
            throw new ArgumentException(
                string.Format(
                    CultureInfo.CurrentCulture,
                    "Type {0} does not subclass controller base",
                    (object) controllerType),
                nameof(controllerType));

        // Resolve controller here
        var controller = ...

        return controller;
    }
}
```

I added few validations (copied from _DefaultControllerFactory_) here to make sure that _Not Found_ page gets returned when no controller found and guard against controllers which don't implement _IController_ interface.

Now it is possible to construct your controllers in this method. Theoretically, you can build everything as a [Pure DI](http://blog.ploeh.dk/2014/06/10/pure-di/). Then you should new up your controllers manually and pass all dependencies to manually. But you would still have to request instances of _EPiServer_ class instances from the container.

```
public class CompositionRoot : ControllerTypeControllerFactory
{
    private readonly IContainer _container;

    public CompositionRoot(IContainer container)
    {
        if (container == null) throw new ArgumentNullException(nameof(container));
        _container = container;
    }

    protected override IController GetControllerInstance(
      RequestContext requestContext, Type controllerType)
    {
        if (controllerType == null)
            throw new HttpException(
                404,
                string.Format(
                    CultureInfo.CurrentCulture,
                    "No controller found for path: {0}",
                    requestContext.HttpContext.Request.Path as object));
        if (!typeof(IController).IsAssignableFrom(controllerType))
            throw new ArgumentException(
                string.Format(
                    CultureInfo.CurrentCulture,
                    "Type {0} does not subclass controller base",
                    (object) controllerType),
                nameof(controllerType));

        var contentLoader = _container.GetInstance<IContentLoader>();

        var contactRepository = new ContactRepository(Settings.ConnectionString);

        if (typeof(ContactBlockController) == controllerType)
        {
            return new ContactBlockController(contentLoader, contactRepository);
        }

        throw new HttpException(
            404,
            string.Format(
                CultureInfo.CurrentCulture,
                "No controller found for path: {0}",
                requestContext.HttpContext.Request.Path as object));
    }
}
```

In this example, _EPiServer_ specific dependency is resolved using container but our custom one created manually.

As the container is already used, there is no point to resolve part of the dependencies manually. It is better to resolve controllers using the container.

```
public class CompositionRoot : ControllerTypeControllerFactory
{
    private readonly IContainer _container;

    public CompositionRoot(IContainer container)
    {
        if (container == null) throw new ArgumentNullException(nameof(container));
        _container = container;
    }

    protected override IController GetControllerInstance(
      RequestContext requestContext, Type controllerType)
    {
        if (controllerType == null)
            throw new HttpException(
                404,
                string.Format(
                    CultureInfo.CurrentCulture,
                    "No controller found for path: {0}",
                    requestContext.HttpContext.Request.Path as object));
        if (!typeof(IController).IsAssignableFrom(controllerType))
            throw new ArgumentException(
                string.Format(
                    CultureInfo.CurrentCulture,
                    "Type {0} does not subclass controller base",
                    (object) controllerType),
                nameof(controllerType));

        return (IController) _container.GetInstance(controllerType);
    }
}
```

After composition root gets created, it should be registered so that framework picks it up. There two ways to configure it.

Start with creating a configurable module (_IConfigurableModule_). _EPiServer_ template has a sample implementation - _DependencyResolverInitialization_ which I will use as a reference.

First of all, register your composition root in the container. _DependencyResolverInitialization_ has a private method _ConfigureContainer_ where you can achieve it.

```
private static void ConfigureContainer(ConfigurationExpression container)
{
    // Other registration code here

    container.For<IControllerFactory>().Use<CompositionRoot>();
}
```

Now there are two options - use dependency resolver or only composition root. To use dependency resolver, register it in the public method _ConfigureContainer_.

```
public void ConfigureContainer(ServiceConfigurationContext context)
{
    context.Container.Configure(ConfigureContainer);

    DependencyResolver.SetResolver(new StructureMapDependencyResolver(context.Container));
}
```

In this example, I am registering _StructureMap_ specific implementation of dependency resolver. This is most common configuration you will see in _EPiServer_ projects even without custom composition root.

Another option is registering controller factory so that _MVC_ can pick it up. It also can be done in the public method _ConfigureContainer_ but dependency resolver should not be registered in this case.

```
public void ConfigureContainer(ServiceConfigurationContext context)
{
    context.Container.Configure(ConfigureContainer);

    ControllerBuilder.Current.SetControllerFactory(new CompositionRoot(context.Container));
}
```

In this case, you do not need a dependency resolver. But while I have tested this configuration I am not sure if everything will work without the dependency resolver. There might be some cases when the framework uses dependency resolver as a service locator to get dependencies. So I suggest sticking to the first configuration.

# Summary

While it is possible to create your own composition root for _EPiServer_ and _MVC_ controllers I do not see a big gain. The most appropriate way to configure dependency injection in _EPiServer_ projects is implementing a dependency resolver. While it is [a service locator and an anti-pattern](http://blog.ploeh.dk/2012/09/28/DependencyInjectionandLifetimeManagementwithASP.NETWebAPI/) it is the safest way. The only case when I would implement my own custom composition root is when I would need to pass a request context (see _RequestContext requestContext_ parameter of _GetControllerInstance_ method) or data from it into my controllers.
