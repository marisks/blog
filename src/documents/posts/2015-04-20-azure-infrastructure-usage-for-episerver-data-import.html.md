---
layout: post
title: "Azure infrastructure usage for EPiServer data import"
description: ""
category: [EPiServer]
tags: [EPiServer,Azure]
date: 2015-04-20
visible: true
---

<p class="lead">
I was working in EPiServer Commerce project on product import and thought that it would be great to use Azure infrastructure to make import process more reliable and consume less resources. 
</p>

In my current EPiServer Commerce solution import was done using custom Scheduled Jobs which were resource intensive. Also on failure those should start from beginning. Jobs has to be run at night to not decrease performance of Web servers and on failure those should run only next night. It is not good solution in global world where applications should run 24/7 and should perform well any time. Udi Dahan describes this issue well in article [Status fields on entoties - HARMFUL?](http://particular.net/blog/status-fields-on-entities-harmful). So I created sample CMS site with page import to verify my thoughts.

# Solution architecture

# Sample site

# Storage for import data

# Processing on Worker

## Import data reader Worker

## Image upload Worker

## Import with EPiServer Service API on Worker

### Alternative: Scheduled Job consuming Queue

# Summary


