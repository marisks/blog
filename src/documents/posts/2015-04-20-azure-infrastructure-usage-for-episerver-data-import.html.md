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

# Sample site

Sample CSV structure for import.

    Name,Intro,Content,ImageUrl
    "The Car","The Car was presented today","Today the greatest of cars was presented - <b>The Car</b>.",http://www.publicdomainpictures.net/pictures/100000/velka/vintage-convertible-automobile.jpg

# Solution architecture

# Storage for import data

When running Web application on Azure there is no available file system for storing large amount of data. Also data for import has to be uploaded somehow to the system for processing. In on-premise solution easiest way is to configure FTP. 

In Azure I have to use Azure Storage. There are multiple ways how to upload import data to it. You can create the page for data import and use [Storage API](http://azure.microsoft.com/en-us/documentation/articles/storage-dotnet-how-to-use-blobs/) or use some tool. In this article I am going to use [AzCopy](http://azure.microsoft.com/en-us/documentation/articles/storage-use-azcopy/) tool.

I already have created storage for EPiServer CMS and will use it for import data too, but I will add separate container and will call it _epiimportdata_.

<img src="/img/2015-04/azure_storage_new_container.png" alt="Azure new Storage container view" class="img-responsive">

After container created, I can use AzCopy to upload the file which is located on my computer - _D:\Temp\data\articles.csv_. Provide source directory for AzCopy, destination container URL and destination Storage primary or secondary key.

    PS D:\Temp> AzCopy /Source:D:\Temp\data\ /Dest:https://epinewssite.blob.core.windows.net/epiimportdata /DestKey:{key} /S
    Finished 1 of total 1 file(s).
    [2015-04-15 09:34:14] Transfer summary:
    -----------------
    Total files transferred: 1
    Transfer successfully:   1
    Transfer skipped:        0
    Transfer failed:         0
    Elapsed time:            00.00:00:01

After upload completed you can view files in Azure Portal.

<img src="/img/2015-04/azure_storage_file_view.png" alt="Azure Storage Container file view" class="img-responsive">

# Processing on Worker

## Import data reader Worker

## Image upload Worker

## Import with EPiServer Service API on Worker

### Alternative: Scheduled Job consuming Queue

# Summary


