---
layout: post
title: "Enabling Commerce content selection"
description: "As EPiServer Commerce nodes, products and variations are EPiServer content, it is possible to create properties with content references to these. But by default EPiServer do not allow commerce content selection in edit mode."
category:
tags: [EPiServer]
date: 2016-07-29
visible: true
---

I needed to create _ContentReference_ property on the page to the _EPiServer Commerce_ category but couldn't find a way how to enable category selection in edit mode. Drag and drop did work but for a user, it would be much simpler to select it from the list.

I remembered that there was some attribute which enabled it but I couldn't find it. So this article describes how to do it.

The solution is simple - just decorate your _ContentReference_ property with _UIHint_ attribute with one of the _EPiServer.Commerce.UIHint_ values:
- _AllContent_ - allows selection of any content,
- _CatalogContent_ - allows selection of any commerce content,
- _CatalogEntry_ - allows selection of product or variation,
- _CatalogNode_ - allows selection of commerce category (node).

Your property then might look like this:

```
[Display(Order = 100)]
[UIHint(UIHint.CatalogNode)]
public virtual ContentReference RootCategory { get; set; }
```

And you can do more - limit selection to specific type with _AllowedTypes_ attribute:

```
[Display(Order = 100)]
[UIHint(UIHint.CatalogNode)]
[AllowedTypes(typeof(FashionCategory))]
public virtual ContentReference RootCategory { get; set; }
```
