---
layout: post
title: "Translating EPiServer Category Description for EPiServer Find indexing"
description: "I had a requirement when I needed to translate EPiServer Category Description within product content's property. While it did work fine when viewing the product's page, EPiServer Find did not index it properly - it was using default language's value for each language."
category:
tags: [EPiServer]
date: 2016-06-20
visible: true
---

<p class="lead">
I had a requirement when I needed to translate EPiServer Category Description within product content's property. While it did work fine when viewing the product's page, EPiServer Find did not index it properly - it was using default language's value for each language.
</p>

After some investigation, I found that _Category's LocalizedDescription_ property uses default behavior of _LocalizationService_. By default _LocalizationService_ uses _CultureInfo.CurrentUICulture_ to detect the current language for translation. Same time, _EPiServer Find_ uses _ContentLanguage.PreferredCulture_ but _CultureInfo.CurrentUICulture_ is set to the default language.

The solution is quite simple - translate your property by providing your _CultureInfo_ for _LocalizationService_. For _EPiServer Find_ to be able to index localized version of it, use _ContentLanguage.PreferredCulture_.

```
public static class CategoryHelper
{
    public static string Translate(Category category)
    {
        var localizationService = ServiceLocator.Current.GetInstance<LocalizationService>();
        return localizationService.GetStringByCulture(
            $"/categories/category[@name=\"{category.Name}\"]/description",
            category.Description,
            ContentLanguage.PreferredCulture);
    }
}
```

Now you can use it in your page, product or other content.

```
public class MyProduct : ProductContent
{
    public virtual string CategoryName { get; set; }

    public string CategoryDescription => GetTranslatedCategoryDescription();

    public string GetTranslatedCategoryDescription()
    {
        var contentLoader = ServiceLocator.Current.GetInstance<IContentLoader>();
        var category = categoryRepository.Get(CategoryName);
        return CategoryHelper.Translate(category);
    }
}
```
