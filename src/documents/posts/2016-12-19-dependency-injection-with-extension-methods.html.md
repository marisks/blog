---
layout: post
title: "Dependency injection in extension methods"
description: "Extension methods are a great way to extend the functionality of objects. Sometimes, when extending an object, it is required to use some service and here comes a dependency injection. Developers use different approaches how to inject dependencies into an extension method. Some are better than others but some popular ones actually are anti-patterns."
category:
tags: [EPiServer]
date: 2016-12-19
visible: true
---

<p class="lead">
Extension methods are a great way to extend the functionality of objects. Sometimes, when extending an object, it is required to use some service and here comes a dependency injection. Developers use different approaches how to inject dependencies into an extension method. Some are better than others but some popular ones actually are anti-patterns.
</p>

The most common dependency injection pattern - constructor injection is not available in extension methods as there is no object to construct. So there are several options left:
* method injection,
* service locator,
* property injection (kind of).

Let's see how each of these can be used.

# Method injection

A method injection is the simplest option but it is not commonly used. The reason for it is that a caller of an extension method should pass the dependency into the method and it doesn't feel nice. So let's see how does it look like.

```
public static string FirstChildName(
    this ContentReference link, IContentLoader loader)
{
    var item = loader.GetChildren<IContent>(link).FirstOrDefault();
    return item == null ? string.Empty : item.Name;
}
```

In this example, _IContentLoader_ gets injected into the _FirstChildName_ extension method and used to retrieve required data. So far it looks good. But when we look at the usage of this extension method it seems "ugly".

```
public class MethodUsage
{
    private readonly IContentLoader _contentLoader;

    public MethodUsage(IContentLoader contentLoader)
    {
        _contentLoader = contentLoader;
    }

    public void Use(ContentReference link)
    {
        var name = link.FirstChildName(_contentLoader);

        // Use the name here
    }
}
```

When calling the _FirstChildName_ it requires passing an _IContentLoader_ too. It feels that it would be nicer if we could just call _FirstChildName_ without passing in anything and then comes the desire to use service locator or property injection.

# Service locator

Service locator is easy to use - just retrieve your dependency from it just before its usage.

```
public static string FirstChildName(
    this ContentReference link)
{
    var loader = ServiceLocator.Current.GetInstance<IContentLoader>();
    var item = loader.GetChildren<IContent>(link).FirstOrDefault();
    return item == null ? string.Empty : item.Name;
}
```

And now you are able to call this extension method without passing anything to it.

```
var name = link.FirstChildName();
```

Looks great, no? But as we remember, [service locator is an anti-pattern](http://blog.ploeh.dk/2010/02/03/ServiceLocatorisanAnti-Pattern/). It hides dependencies from us and it is impossible to replace those easily. When you would need to replace an _IContentLoader_ implementation in a unit test, it would be impossible. So, if service locator should not be used, maybe property injection could help.

# Property injection

_EPiServer_ gives you an option to use a static property with a wrapper - _Injected_ which allows lazily load your dependency.

```
public static Injected<IContentLoader> Loader { get; set; }

public static string FirstChildName(
    this ContentReference link)
{
    var item = Loader.Service.GetChildren<IContent>(link).FirstOrDefault();
    return item == null ? string.Empty : item.Name;
}
```

Now it looks better - it is possible to replace injected _IContentLoader_ with stub instance in the test.

```
[Fact]
public void Test()
{
    ExtensionMethods.Loader = new Injected<IContentLoader>(new StubContentLoader());

    // Rest of the test
}

public class StubContentLoader : IContentLoader
{
    // Implementation
}
```

While it looks like a good solution, it has several issues. One issue is related to making _Injected_ property private. Developers tend to hide _Injected_ properties to outside probably because _Intellisense_ displays those and developers won't see or give access to those. In this case, it has same issues as service locator - it is impossible to replace a dependency.

Another issue is that it is not proper property injection. It is just hidden service locator. As there is no class to instantiate when calling extension method, no property gets set. Instead, when _Injected_ wrapper sees that there is no value set, it uses a service locator to resolve a service.

So property injection can be used but only when properties are public. But maybe there still is a better way? What if property injection could be used as a default service accessor and a method injection for proper dependency injection? Then we could hide a service accessor property and still inject services.

# Property injection + method injection

So how does it look like? Let's create two methods - one is same as in the method injection sample and another calling it and passing in a service from a property.

```
public static string FirstChildName(
    this ContentReference link, IContentLoader loader)
{
    var item = loader.GetChildren<IContent>(link).FirstOrDefault();
    return item == null ? string.Empty : item.Name;
}

private static Injected<IContentLoader> Loader { get; set; }

public static string FirstChildName(
    this ContentReference link)
{
    return FirstChildName(link, Loader.Service);
}
```

I have seen this solution in multiple places and initially I did like it but it has one serious drawback. A dependency injection just doesn't work here. Yes, you have a method injection. But let's see the common usage.

```
public void Use(ContentReference link)
{
    var name = link.FirstChildName();

    // Use the name here
}
```

There is no dependency injected. Usually, developers call these extension methods without passing the dependency. And when writing the test, it is impossible to replace it.

```
public void Test()
{
    // Should set stub dependency here but no way to do it

    Use(link); // Call the method under test

    // Rest of the test
}
```

So while the calling code is not using a version of a method with explicit dependency injection, it is impossible to replace a dependency with another implementation.

# Solution

Based on the previous, there is only one solution - a method injection. But it didn't "feel" right. You had to pass in the dependency in your nice extension method. For example, the usage of the previous extension method with method injection.

```
var name = ContentReference.StartPage.FirstChildName(_contentLoader);
```

The issue with this "feeling" is that we are passing in wrong first parameter. Instead of passing the model (_ContentReference_ in the example), pass in a service.

```
public static string FirstChildName(
    this IContentLoader loader, ContentReference link)
{
    var item = loader.GetChildren<IContent>(link).FirstOrDefault();
    return item == null ? string.Empty : item.Name;
}
```

And the usage now feels more natural. It even looks like a native service method. For example, _IContentLoader's_ _GetChildren_ method.

```
var name = _contentLoader.FirstChildName(ContentReference.StartPage);
var children = _contentLoader.GetChildren<IContent>(ContentReference.StartPage);
```

But what if I have multiple services to pass in? When working with _EPiServer Commerce_ it is quite common. So let's take this example.

```
public static T GetByCode<T>(
    this string code, ReferenceConverter converter, IContentLoader loader)
    where T : CatalogContentBase
{
    var link = converter.GetContentLink(code);
    return loader.Get<T>(link);
}

// And the usage:
var product = "ABC-123".GetByCode<ProductContent>(_referenceConverter, _contentLoader);
```
As you see, I tried to pass in a model (in this case a product code) as the first parameter. When using it, it doesn't look right. But which one of the services I would put as a first parameter for this extension method? None.

Instead, new interface and class should be created which provides required service.

```
public interface IProductLoader
{
    T GetByCode<T>(string code) where T : CatalogContentBase;
}

public class ProductLoader : IProductLoader
{
    private readonly ReferenceConverter _converter;
    private readonly IContentLoader _loader;

    public ProductLoader(
        ReferenceConverter converter, IContentLoader loader)
    {
        _converter = converter;
        _loader = loader;
    }

    public T GetByCode<T>(string code)
        where T : CatalogContentBase
    {
        var link = _converter.GetContentLink(code);
        return _loader.Get<T>(link);
    }
}

// And the usage:
var product = _productLoader.GetByCode("ABC-123");
```

And make sure that your interface follows [interface segregation principle](Interface segregation principle).
