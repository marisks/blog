---
layout: post
title: "A more flexible way to hide category property in Episerver"
description: >
  <t render="markdown">
  Some time ago, Joel Abrahamsson wrote an article about how to hide [Episerver's category property](http://joelabrahamsson.com/hiding-episervers-standard-category-property/). But sometimes you need to hide it only for specific content types. You can filter by `OwnerContent`, but then you have to add all content types you want to filter, to the descriptor class. It is not a flexible solution.
  </t>
category:
tags: [EPiServer]
date: 2019-08-02
visible: true
---

In _Episerver_ you can hide properties in edit mode using a `ScaffoldColumn` attribute by using it like this:

```csharp
[ScaffoldColumn(false)]
```

This does not work for the `Category` property though. To fix it, you can add an editor descriptor similar to _Joel's_ but instead of filtering on content types, filter on `ScaffoldColumn` and use its `Scaffold` value:

```csharp
[EditorDescriptorRegistration(TargetType = typeof (CategoryList))]
public class HideCategoryEditorDescriptor : EditorDescriptor
{
    public override void ModifyMetadata(
        ExtendedMetadata metadata,
        IEnumerable<Attribute> attributes)
    {
        var attrs = attributes as Attribute[] ?? attributes.ToArray();
        base.ModifyMetadata(metadata,  attrs);

        if (metadata.PropertyName != "icategorizable_category") return;

        var scaffoldAttribute =
            attrs
            .SafeOfType<ScaffoldColumnAttribute>()
            .FirstOrDefault();
        if (scaffoldAttribute == null) return;

        metadata.ShowForEdit = scaffoldAttribute.Scaffold;
    }
}
```

_NOTE: I am using `SafeOfType` extension method from the [Geta.Net.Extensions](https://nuget.episerver.com/package/?id=Geta.Net.Extensions) library._

Now you can use `ScaffoldColumn` to control the visibility of the `Category` property.

```csharp
[ScaffoldColumn(false)]
public override CategoryList Category { get; set; }
```

Here I am overriding a category property from the base class and applying the attribute.