---
layout: post
title: "How to save (not publish) catalog content properly"
description: >
  <t render="markdown">
  Usually, when importing or updating categories, products or variations I have published those immediately and never had any issues. But recently had an issue when a customer wanted to publish updated products manually. I had to save those without publishing but didn't get anything saved - at least no info was visible in the UI.
  </t>
category:
tags: [EPiServer]
date: 2017-02-19
visible: true
---

The reason why this happened was simple. When saving any versionable content without publishing, Episerver creates a new version. If it is a new item, then it creates a new one and everything is fine. But when updating and existing item which is retrieved by _IContentRepository's_ _Get_ method, it creates new version with status _CheckedOut_. Same time, UI displays only content version which is default draft but our new _CheckedOut_ version is not a default draft.

Here is the code which seems correct to update a product:

```
var productLink = _referenceConverter.GetContentLink(productCode);
var product = _contentRepository.Get<Product>(productLink).CreateWritableClone<Product>();

// Update the product

_contentRepository.Save(product, SaveAction.Default, AccessLevel.NoAccess);
```

The correct way to update a product would be to load draft version instead of using _IContentRepository's_ _Get_ method with default content link which loads published version.

First of all, retrieve the content link of the draft version using _IContentVersionRepository's_ _LoadCommonDraft_ method. Then use the draft's link to load draft content using _IContentRepository's_ _Get_ method.

```
var productLink = _referenceConverter.GetContentLink(productCode);
var lang = LanguageSelector.MasterLanguage().Language;
var draft = _contentVersionRepository.LoadCommonDraft(productLink, lang.Name);
var product = _contentRepository.Get<Product>(draft.ContentLink).CreateWritableClone<Product>();

// Update the product

_contentRepository.Save(product, SaveAction.Default, AccessLevel.NoAccess);
```

This way a draft version which is visible in the UI will always be up to date.
