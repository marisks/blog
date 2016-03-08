---
layout: post
title: "Fixing Dojo id conflict"
description: "Recently I got an error related to Dojo widget about conflicting id on the HTML element. While it is possible to work with Dojo without ids, those are necessary for field labels to work properly."
category:
tags: [EPiServer, JavaScript]
date: 2016-03-08
visible: true
---
<p class="lead">
Recently I got an error related to Dojo widget about conflicting "id" on the HTML element. While it is possible to work with Dojo without "ids", those are necessary for field labels to work properly.
</p>

Here is the error I got:

<img src="/img/2016-03/dojo-widget-id-error.png" alt="Dojo widget conflicting id error." class="img-responsive" />

And the widget code which caused the conflict:

```
<label for="maxParticipants">Max participants</label>
<div class="dijit dijitReset"
      id="maxParticipants"
      data-dojo-attach-point="maxParticipants"
      data-dojo-type="dijit.form.NumberSpinner"
      data-dojo-props="constraints: { min: 1 }"></div>
```

It is clear that there could be only one HTML element with the same _id_ on the page and multiple _Dojo_ widgets might be added dynamically on the page. So it might cause the error. In my case, I had only one widget on the page, but I still got an error after publishing page content. Seems that _EPiServer_ creates another instance of the widget at some point.

[Stack Overflow](http://stackoverflow.com/questions/11182103/how-do-i-create-unique-ids-in-a-dojo-widget-template) to the rescue and I got the solution:

```
<label for="${id}maxParticipants">Max participants</label>
          <div class="dijit dijitReset" id="${id}maxParticipants" data-dojo-attach-point="maxParticipants" data-dojo-type="dijit.form.NumberSpinner" data-dojo-props="constraints: { min: 1 }"></div>
```

Each _Dojo_ widget has an _id_ property. And _Dojo_ templates works so that replaces _${property}_ kind of values with appropriate widget class property's values. So _${id}_ gets replaced by widget class' property _id's_ value.
