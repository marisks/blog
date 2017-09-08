---
layout: post
title: "Category sorting in Episerver Commerce"
description: >
  <t render="markdown">
  Recently Episerver released Commerce 11. It contains a new feature - [a product sorting](http://world.episerver.com/documentation/Release-Notes/ReleaseNote/?releaseNoteId=COM-13). But unfortunately, there is [no way to sort categories](http://world.episerver.com/forum/developer-forum/Episerver-Commerce/Thread-Container/2017/8/category-sorting-in-commerce-11/).
  </t>
category:
tags: [EPiServer]
date: 2017-09-07
visible: true
---

It is quite a standard requirement to sort product categories in a certain order. Customers might want to promote some categories more than others and display those on the top in the navigation or category listing. While _Episerver_ doesn't have support for this yet, there is a solution.

At first, add a content area on your category type (or category base type if you have it). Limit content area items to catalog nodes, that only categories can be added to this content area.

```csharp
[Display("Sub-category order")]
[UIHint(UIHintCommerce.CatalogNode)]
public virtual ContentArea SubCategoryOrder { get; set; }
```

Then create a method which loads categories in proper order.

```csharp
public virtual IEnumerable<CategoryContent> GetSubCategories(CategoryContent parentCategory)
{
    var children = _contentLoader
        .GetChildren<CategoryContent>(parentCategory.ContentLink);

    var orderedCategories = parentCategory
        .SubCategoryOrder
        ?.Items
        .Select(x => x.ContentLink)
        .Select(
            link => children.FirstOrDefault(c => c.ContentLink.Equals(link, ignoreVersion: false)))
        .Where(x => x != null)
        .ToList() ?? new List<CategoryContent>();

    var restCategories = children.Except(orderedCategories);

    return orderedCategories.Union(restCategories);
}
```

Here I am loading all child categories of the parent category. Then extract content links from the content area items and retrieve corresponding child categories by these links. Also, ignore the links which do not have a matching child category by filtering items which are _null_. The loaded child categories should be in the same order as added to the content area.

Next, retrieve the unordered categories from the all child category list. And finally, create a common list by placing ordered categories in the front and unordered one at the end.

With this solution, editors now can add categories which they want on the top in the new content area. They can add these categories in a certain order. They also can add all categories and order those as needed.

While you can use this solution, it would be better to have a native _Episerver_ support for this. I hope that _Episerver_ will add it soon :).