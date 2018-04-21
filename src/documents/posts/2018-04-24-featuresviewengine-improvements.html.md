---
layout: post
title: "FeaturesViewEngine improvements"
description: >
  <t render="markdown">
  Lately, FeaturesViewEngine has received several significant improvements.
  </t>
category:
tags: [EPiServer]
date: 2018-04-24
visible: true
---

Previous versions of _FeaturesViewEngine_ had issues with performance. It was caused because the library didn't cache view paths which it was not able to resolve. In the latest version, this is fixed.

I also added filtering for requests without a controller. So now it passes such requests further without trying to handle those.

Another addition is support for display modes. Thanks to my colleagues [Klāvs](https://getadigital.com/people/klavs-prieditis/) and [Kaspars](https://getadigital.com/people/kaspars-ozols/). They made a pull request which fixes a missing feature.

They also added integration tests. Now it is much easier to refactor and improve the library without breaking anything.

I have created proper documentation for FeaturesViewEngine. You can view it on [GitHub](https://github.com/marisks/FeaturesViewEngine).