---
layout: post
title: "Automating Episerver website configuration"
description: >
  <t render="markdown">
  When you have multiple environments - for production, staging, and testing, there is a need to copy over production environment data to staging and testing environments. In Episerver this is quite easy - just copy over database and blobs. But you have to update Episerver website configuration to match your staging/test environment setup. You have to change website URL and add hostnames for your new environment. This can be done in a user interface, but it is better to automate.
  </t>
category:
tags: [EPiServer]
date: 2017-05-31
visible: true
---

While it is not recommended to modify _Episerver_ database directly, the easiest way to automate website configuration is by using a _SQL_.

There might be multiple sites configured in a single database. For this reason, you have to update URLs for each website.

```sql
UPDATE tblSiteDefinition SET SiteUrl = 'http://mysite.localtest.me/' WHERE Name = 'MySite'
UPDATE tblSiteDefinition SET SiteUrl = 'http://mysite2.localtest.me/' WHERE Name = 'MySite2'
```

Website URL is set in the _tblSiteDefinition_ table. There is one record for each site. You can update URL for it by site name.

Next, you have to update hostnames. There can be only one primary hostname. So at first, we have to remove a primary type of any of actual hostnames.

```sql
UPDATE tblHostDefinition SET [Type] = 0 WHERE [Type] = 1
```

Hostnames are stored in the _tblHostDefinition_ table. There is a _Type_ column which holds a type of the hostname. A primary hostname type value is _1_ and _0_ means that there is no type set.

The last step is adding hostnames for the new website configuration.

```sql
INSERT INTO tblHostDefinition ([fkSiteID], [Name], [Type], [Language], [Https])
SELECT [pkID], REPLACE(REPLACE(REPLACE([SiteUrl], 'http://', ''), 'https://', ''), '/', ''), 1, NULL, NULL
FROM tblSiteDefinition
```

Here I am adding hostnames into _tblHostDefinition_ table for each site which is configured in the _tblSiteDefinition_ table. Hostnames should have only a domain name, so I had to remove a protocol and a trailing slash. Then I had to set primary type. You can also set language and if a hostname is HTTPS. I left those as empty.

Below is a full script.

```sql
UPDATE tblSiteDefinition SET SiteUrl = 'http://mysite.localtest.me/' WHERE Name = 'MySite'
UPDATE tblSiteDefinition SET SiteUrl = 'http://mysite2.localtest.me/' WHERE Name = 'MySite2'

UPDATE tblHostDefinition SET [Type] = 0 WHERE [Type] = 1

INSERT INTO tblHostDefinition ([fkSiteID], [Name], [Type], [Language], [Https])
SELECT [pkID], REPLACE(REPLACE(REPLACE([SiteUrl], 'http://', ''), 'https://', ''), '/', ''), 1, NULL, NULL
FROM tblSiteDefinition
```

Of course, this script will not work in all scenarios, but it works well if you just need to change your website's URL and set one matching hostname for it.