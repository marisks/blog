---
layout: post
title: "Finding content type conflict reasons with Episerver Developer tools"
description: >
  <t render="markdown">
  A few months ago I wrote [an article about how to find content type conflict reasons](/2018/05/14/finding-content-type-conflict-reasons/). Now the described functionality is implemented in [Episerver Developer tools](https://github.com/episerver/DeveloperTools).
  </t>
category:
tags: [EPiServer]
date: 2018-07-16
visible: true
---

After writing the previous article about this topic, I have created a pull request to _Episerver Developer Tools_ with the changes required to solve this issue. I have made some changes though. I have added support for ACL conflicts. Now when using _Episerver Developer Tools_,  you will be able to see those too.

You can see content type conflicts in the _Developer tools_ under _Content Type Analyzer_ section. There is a separate column - _Conflicts_ where you will find conflict details.

Here is an example of how those will be displayed.

<img src="/img/2018-07/content-type-conflicts.png" class="img-responsive" alt="Content type conflicts">

_Field order_ here is a conflicted property name. Then you will see the value defined in the code and a database.

Below is a list of conflicts it displays.

For content types:

- Model type
- Name
- Description
- Display name
- Sort order
- GUID
- Availability
- ACL

For property types:

- Tab name
- Name
- Description (help text)
- Display name (edit caption)
- Culture specific (language specific)
- Required
- Searchable
- Available in edit mode (display edit UI)
- Field order