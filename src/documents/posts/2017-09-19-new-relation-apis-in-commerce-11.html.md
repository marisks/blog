---
layout: post
title: "New relation APIs in Episerver Commerce 11"
description: >
  <t render="markdown">
  Recently, Episerver has changed relation APIs. Now those are easier to understand and use.
  </t>
category:
tags: [EPiServer]
date: 2017-09-19
visible: true
---

The first change you will notice when working with new relations is that now it uses Parent/Child properties instead of Source/Target ones. It makes the code easier to understand. Here is how it looks like for different relations:

- _ProductVariation_ - the parent property has a reference to a product and the child property has a reference to a variation of this product.
- _PackageEntry_ and _BundleEntry_ - the parent property has a reference to a package or a bundle and the child property has a reference to a product which is within the package or the bundle.
- _NodeRelation_ - the parent property has a reference to a category and the child property has a reference to a product or a sub-category which are under the _parent_ category.

In _Commerce 11_, _Episerver_ had made more internal changes to the relations. One important change is related to URL creation for catalog contents. Previously _Episerver_ used _ParentLink_ on the catalog item to find all parents of it and build URL like http://mysite.com/root/parent1/parent2/product. But now it uses relations instead. Now category/product (node) relation is used to build URLs. But as there might be multiple category/product relations for each item, there is a special relation - the primary relation. Until the _Commerce 11.2_, there was no easy way to find out which relation is primary. It was created automatically on catalog item creation or moving. **While it was a special relation, you could find it with _IRelationRepository.GetParents&lt;NodeRelation&gt;(ContentReference link)_ or _IRelationRepository.GetChildren&lt;NodeRelation&gt;(ContentReference link)_ and delete it with _IRelationRepository.RemoveRelation(NodeRelation relation)_. And there was no way how to get it back.**

_Episerver_ has added a new relation type in _Commerce 11.2_ which solves this issue - _NodeEntryRelation_. This relation has a property _IsPrimary_ which allows you to distinguish primary relations from other ones. You should not use the old _NodeRelation_ now but use _NodeEntryRelation_ instead. Now you can find relations which are and are not primary and even if you remove the primary relation, you can get it back by creating the new one.

Now you can get children of the parent category like this:

```charp
var children = _relationRepository.GetChildren<NodeEntryRelation>(parentLink);
```

And if you want to remove all related categories except the primary category for the item:

```charp
var parents =
    _relationRepository
        .GetParents<NodeEntryRelation>(childLink)
        .Where(x => !x.IsPrimary);
_relationRepository.RemoveRelations(parents);
```

Another improvement all relation types have is sorting. Now each relation has a _SortOrder_ property. You can use it to order the items as you want. You can set this property from the code, or you can sort products from the UI (category sorting not supported yet), and it will be updated.

# Summary

I think that the issue with _NodeRelation_ and primary categories could be omitted if primary node relations would not be listed in _GetParents_ or _GetChildren_ methods. This way it would remain as an internal API. And if the developer would want to change the primary category, he could still use the _ParentLink_ property of an item.

Anyway, _Episerver_ has done a lot of useful improvements in the relation APIs. While there were some issues with it in early _Commerce 11_ versions, now those are fixed with new _NodeEntryRelation_.

