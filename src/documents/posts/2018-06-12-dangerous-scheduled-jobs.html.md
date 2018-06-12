---
layout: post
title: "Dangerous scheduled jobs"
description: >
  <t render="markdown">
  For several months we have noticed many exceptions during the product import in one of our projects. It is a custom import which is running in a scheduled job, and we didn't think that it could be the cause for those exceptions.
  </t>
category:
tags: [EPiServer]
date: 2018-06-12
visible: true
---

Our project was throwing exceptions related to database deadlocks and other concurrency issues. However, this was occasionally happening during the import.

The first thing I thought, that maybe there is an issue with multiple Azure website instances. I checked if two instances are running the same job in parallel. However, it seemed that those weren't.

Recently, we were migrating the project to the DXC and were copying blobs to the DXC. We have stopped all scheduled jobs which could update blobs. Then we have noticed that blobs were still changing as if import job is running. I have checked the jobs, and all were disabled in admin UI. Then checked those in a database and found that there are multiple records with the same jobs. The only difference was a display name.

As I understand, it happened when we have changed the display name of the scheduled job. _Episerver_ created a new record and didn't remove the old one. I have checked with other colleagues that they also have this issue in _Episerver CMS 11_, but it doesn't appear in _CMS 10_.

You can omit this issue if you set _GUID_ of your scheduled job:

```csharp
[ScheduledPlugIn(DisplayName = "ScheduledJobExample", GUID = "d6619008-3e76-4886-b3c7-9a025a0c2603")]
public class ScheduledJobExample : ScheduledJobBase
{
}
```

You also should check if in your current database there are job duplicates. The easiest way is to sort the jobs by the type name in a SQL query:

```sql
SELECT *
  FROM [dbo].[tblScheduledItem]
  ORDER BY TypeName
```

I have noticed that even _Episerver_ scheduled jobs are duplicated.

Once you found all your duplicated jobs, you can remove those with a script:

```sql
DECLARE @id AS uniqueidentifier = '3134D210-6971-4DF4-8662-FB4E67E41B80'

DELETE [dbo].[tblScheduledItemLog] WHERE [fkScheduledItemId] = @id
DELETE [dbo].[tblScheduledItem] WHERE [pkID] = @id
```

## Summary

This was a nasty issue we haven't noticed for a long time. It could be omitted if _GUID_ field would be made mandatory by _Episerver_. Also, _Episerver_ should handle duplicate jobs - remove which doesn't match the job definition in code.