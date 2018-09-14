---
layout: post
title: "Fluent configuration API for your Episerver library"
description: >
  <t render="markdown">
  Last time I wrote an article how to configure Episerver libraries .NET Core way. In this article, I will show you how to improve it with fluent APIs.
  </t>
category:
tags: [EPiServer]
date: 2018-09-14
visible: tru
---

In the [previous article](/2018/08/28/configuring-your-epsiserver-libraries-net-core-way/), I have created an extension method for _InitializationEngine_ to be able to pass configuration settings to my library:

```csharp
public void Initialize(InitializationEngine context)
{
  context.UseMyLibrary(settings => {
    settings.MyProperty = 20;
    return settings;
  });
}
```

The extension method expects a function parameter which will return configured settings. This could be simplified by passing an action method (`Action<MySettings>`) instead, but the function was used on purpose. It gives us an option of creating a fluent API. The usage of such API could look like this:

```csharp
public void Initialize(InitializationEngine context)
{
  context.UseMyLibrary(settings =>
    settings
      .WithMyProperty(20)
      .WithAnotherProperty("Hello"));
}
```

There are two ways how we can build this - with mutable and immutable settings class. There are several benefits of using one over another.

## Mutable fluent API

A mutable option is simple. You have to create methods which manipulate the internal state of the object and returns it as a result:

```csharp
public class MySettings
{
  public int MyProperty { get; }
  public string AnotherProperty { get; }

  public MySettings()
  {
    MyProperty = 10;
    AnotherProperty = string.Empty;
  }

  public MySettings WithMyProperty(int value)
  {
    MyProperty = value;
    return this;
  }

  public MySettings WithAnotherProperty(string value)
  {
    AnotherProperty = value;
    return this;
  }
}
```

## Immutable fluent API

An immutable fluent API is harder to implement, but it allows for sharing the settings and modifying those independently. It would enable pre-build settings and then create different configurations based on the pre-built.

```csharp
var settings =
  new MySettings()
    .WithMyProperty(10);

var settings1 = settings.WithAnotherProperty("Hello");
var settings2 = settings.WithAnotherProperty("world!");
```

Here _settings1_ and _settings2_ are two different objects with different values. Such a scenario is not possible with mutable settings - there would be only one object which would hold the last value;

The most straightforward implementation would require you to copy all unchanged values to the new object in each method:

```csharp
public class MySettings
{
  public int MyProperty { get; private set; }
  public string AnotherProperty { get; private set; }

  public MySettings()
  {
    MyProperty = 10;
    AnotherProperty = string.Empty;
  }

  public MySettings WithMyProperty(int value)
  {
    return new MySettings { MyProperty = value, AnotherProperty = AnotherProperty };
  }

  public MySettings WithAnotherProperty(string value)
  {
    return new MySettings { MyProperty = MyProperty, AnotherProperty = value };
  }
}
```

This works, but with lots of properties, it would be annoying to do copying manually in each method. In F# there is a copy-and-update record expression (_with_) for record types (immutable classes).

```fsharp
let settings = {myProperty=10; anotherProperty=""}
let settings1 = {settings with anotherProperty="Hello"}
let settings2 = {settings with anotherProperty="world!"}
```

In C#, you can create a method which internally could mutate the new object. Then there would be only one place where you should modify copying logic:

```csharp
public class MySettings
{
  public int MyProperty { get; private set; }
  public string AnotherProperty { get; private set; }

  public MySettings()
  {
    MyProperty = 10;
    AnotherProperty = string.Empty;
  }

  public MySettings WithMyProperty(int value)
  {
    return With(settings => settings.MyProperty = value);
  }

  public MySettings WithAnotherProperty(string value)
  {
    return With(settings => settings.AnotherProperty = value);
  }

  private MySettings With(Action<MySettings> mutate)
  {
    var settings = new MySettings
    {
      MyProperty = MyProperty,
      AnotherProperty = AnotherProperty
    };
    mutate(settings);
    return settings;
  }
}
```

## Summary

Fluent APIs give us simple, easy discoverable APIs. Those can be useful when configuring your application or library. You can implement those as mutable or immutable. Mutable APIs are simpler to implement but has trouble with sharing. Immutable APIs are a little bit harder to implement but are more flexible.

So for simple scenarios with few settings, it would be okay to use a mutable API. When you have lots of properties which you need to share and create different configurations for different cases, use immutable solution.