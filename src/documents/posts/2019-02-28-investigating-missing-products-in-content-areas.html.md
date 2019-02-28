---
layout: post
title: "Investigating missing products in content areas"
description: >
  <t render="markdown">
  Recently I got a message from the customer about missing products in content areas. They added few products but those were gone the next morning.
  </t>
category:
tags: [EPiServer]
date: 2019-02-28
visible: true
---

After research, we found that it was caused by the import changing content GUIDs on products. It caused other issues too. In this article, I do not want to go into the details of that issue but cover how products are linked in content areas.

With a few SQL scripts, you can get all you need. The first thing to find out is the ID of the content area property. You can find it in the `tblPropertyDefinition` by querying it on `fkContentTypeID` column (if you do not know the ID of the content type, find it in the `tblContentType` table).

```sql
SELECT *
  FROM [dbo].[tblPropertyDefinition]
  where fkContentTypeID = 100
```

In the results, find your property and use it's `pkID` value in the next query.

In the `tblContentProperty` table, _Episerver_ stores values of all properties. You can easily get values for all properties by querying by content ID on the `fkContentID` column and property definition ID on the `fkPropertyDefinitionID` column (the value you get in the previous step). The easiest way to get a content ID is by going into the Episerver edit mode and check the ID under the content properties.

<img src="/img/2019-02/content-id-in-edit.jpg" class="img-responsive" alt="Content ID in the edit mode.">

Once you get all IDs, run the query. To get values of a content area, you should look into `LongString` column.

```sql
SELECT [LongString]
  FROM [dbo].[tblContentProperty]
  where fkPropertyDefinitionID = 800 and fkContentID = 9000
```

Episerver stores content area data in an `XML` format which looks like `Html`. Each item in the content area is represented as a `DIV` tag with some attributes. I was interested only in two - `data-contentguid` and `data-contentname`. The first attribute is a GUID which links to the content in the content area and the second helps to identify an item by the name.

```html
<div
    data-classid="36f4349b-8093-492b-b616-05d8964e4c89"
    data-contentgroup=""
    data-contentguid="00000000-0000-1234-0000-000000010000"
    data-contentname="Fancy stuff">{}</div>
```

In our case, product GUIDs were generated in a specific format and those where changing in some cases. In this example, it would be `1234` part. Once we found the issues in IDs, we could easily fix it with a script.

```sql
UPDATE tblContentProperty
SET LongString = REPLACE(LongString, '00000000-0000-1234-0000-', '00000000-0000-0000-0000-')
```

I know that it might be dangerous to modify Episerver DB directly, but we haven't risked much as products in content areas were not visible anyway. Luckily, this fixed our issues.

There is another table which might be useful when researching issues with content areas. It is `tblContentSoftlink` table.

```sql
SELECT *
  FROM [dbo].[tblContentSoftlink]
  where fkReferencedContentGUID = '00000000-0000-1234-0000-000000010000'
```

There is one important column in this table - `ContentLink`. You can find a matching content link for a content GUID in it. In our case, we still saw a content link and it was a valid one - the content existed in the DB. But once we edited content in the edit mode without touching our content area, the content link became empty. The data in the content area still remained (in the `tblContentProperty` table).