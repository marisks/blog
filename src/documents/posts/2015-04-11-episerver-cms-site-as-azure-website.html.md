---
layout: post
title: "EPiServer CMS site as Azure Webapp"
description: "Lately Azure become really popular to host you web applications and websites. EPiServer also has made their CMS able to run on Azure. In this article I am describing my experience to setup EPiServer CMS on Azure."
category: [EPiServer]
tags: [EPiServer,Azure]
date: 2015-04-11
visible: true
---

<p class="lead">
Lately Azure become really popular to host you web applications and websites. EPiServer also has made their CMS able to run on Azure. In this article I am describing my experience to setup EPiServer CMS on Azure.
</p>

While EPiServer provides [documentation](http://world.episerver.com/documentation/Items/Developers-Guide/EPiServer-CMS/8/Deployment/Deployment-scenarios/Deploying-to-Azure-webapps/) on how to do deployment to Azure I want to document my experience too.

# Creating EPiServer CMS site

So first task is creating new EPiServer CMS site. This is really easy using [Visual Studio Extension for EPiServer CMS](https://visualstudiogallery.msdn.microsoft.com/4ad95160-e72f-4355-b53e-0994d2958d3e). Extension adds project template and several item templates to Visual Studio.

Start creating project using _EPiServer Web Site_ project template.

<img src="/img/2015-04/new_episerver_project.png" alt="New Project dialog" class="img-responsive">

Then select type of the project. I am creating Empty MVC project. Also uncheck _Add EPiServer Search_. I am not going to use search and it also requires additional configuration steps.

<img src="/img/2015-04/new_episerver_project2.png" alt="New Project dialog" class="img-responsive">

According to documentation I will need _EPiServer.Azure_ NuGet package installed from [EPiServer NuGet Feed](http://nuget.episerver.com/).

<img src="/img/2015-04/episerver_azure_nuget.png" alt="New Project dialog" class="img-responsive">

# Setting up Azure Webapp

I am going to use [New Azure Portal](https://portal.azure.com/). Documentation describes [Old portal](https://manage.windowsazure.com).

## Creating Azure Website

Start creating new Azure Website by clicking _New_ button on the left bottom corner. Then select _Web + Mobile_ -> _Web app_. Provide URL of your site and select application service plan. You also can create new application service plan here by clicking _Or create new_. Then check _Add to Startboard_ - this will allow to easier find your site later. After it's done, click _Create_.

<img src="/img/2015-04/new_azure_webapp.png" alt="New Project dialog" class="img-responsive">

It will take some time while Website is creating. After Website is created, you can open Website view from _Startboard_ (if you added it to _Startboard_) or by clicking _Browse_ on the left menu.

<img src="/img/2015-04/website_main_view.png" alt="New Project dialog" class="img-responsive">

## Creating SQL database

New portal do not have an option to create SQL database while creating new Azure Website. So we have to do it ourselves.

Start creating SQL database by clicking _New_ button, then select _Data + Storage_ -> SQL Database.

<img src="/img/2015-04/new_azure_sql_db.png" alt="New Project dialog" class="img-responsive">

Provide new database name and select or create new server.

<img src="/img/2015-04/new_azure_sql_db2.png" alt="New Project dialog" class="img-responsive">

We will use _Blank database_ as source, then select pricing you want to use, provide database collation and select or create resource group. If you want, can add DB to _Startboard_ by checking _Add to Startboard_. Wait until DB is created and then you can open DB view where you can see DB status and _Properties_ like _Connection Strings_.

<img src="/img/2015-04/new_azure_sql_db3.png" alt="New Project dialog" class="img-responsive">

## Creating Azure Storage

Azure Websites do not have filesystem as we used to in Windows. Instead you can create Azure Storage to store files.

Start creating it by clicking on _New_, select _Data + Storage_ -> _Storage_.

<img src="/img/2015-04/new_azure_storage.png" alt="New Project dialog" class="img-responsive">

Provide name of the storage (it should be in lowercase as described in documentation), select pricing, select or create resource group, select location and if you want can enable diagnostics. Storage creation also will take some time and after it is created, you can navigate to storage management view. 

<img src="/img/2015-04/new_azure_storage2.png" alt="New Project dialog" class="img-responsive">

## Creating Service Bus

_Service Bus_ in EPiServer is used to handle messages between multiple site instances (if those are created for scaling purposes). _Service Bus_ creation is not available in new Azure Portal at the time of writing this blog post. You have to login into old [portal](https://manage.windowsazure.com) first.

Create _Service Bus_ by selecting _Service Bus_ from left menu and click _Create a  new namespace_.

<img src="/img/2015-04/new_azure_servicebus.png" alt="New Project dialog" class="img-responsive">

Then provide namespace name, select region, type - _MESSAGING_ and messaging tier - _STANDARD_ as it is described in EPiServer documentation.

<img src="/img/2015-04/new_azure_servicebus2.png" alt="New Project dialog" class="img-responsive">

# Configuring EPiServer CMS project

First of all you have to provide configuration for _Azure Storage_ and _Service Bus_. Open Visual Studio project and open _Web.config_. In _episerver.framework_ section add _blob_ and _event_ configuration.

    <blob defaultProvider="azureblobs">
      <providers>
        <add name="azureblobs" type="EPiServer.Azure.Blobs.AzureBlobProvider,EPiServer.Azure"
              connectionStringName="EPiServerAzureBlobs" container="epinewssitemedia"/>
      </providers>
    </blob>
    <event defaultProvider="azureevents">
      <providers>
        <add name="azureevents" type="EPiServer.Azure.Events.AzureEventProvider,EPiServer.Azure"
              connectionStringName="EPiServerAzureEvents" topic="epinewssiteevents"/>
      </providers>
    </event>

_container_ and _topic_ are the names of storage container and _Service Bus_ topic accordingly. Those should be unique per Web application and _Azure Storage_ or _Service Bus_. _connectionStringName_ attribute value is the name of connection string from _connectionStrings_ section.

You have to configure three connection strings - for SQL database, Azure Storage and Service Bus. First copy connection string for SQL database which you can find in new Azure Portal in _Properties_ view for SQL database. 

<img src="/img/2015-04/new_azure_sql_db3.png" alt="New Project dialog" class="img-responsive">

You only have to change password in the connection string to you user's password and add _MultipleActiveResultSets=True_ as required by EPiServer documentation.

    <add name="EPiServerDB" 
        connectionString="Server=tcp:episites.database.windows.net,1433;Database=episnewssite;User ID=marisks@episites;Password={your_password_here};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;MultipleActiveResultSets=True" 
        providerName="System.Data.SqlClient" />

Next add connection string for _Azure Storage_ with same name as configured for blobs. You can find connection string in _Storage_ management view under _Keys_.

<img src="/img/2015-04/azure_storage_keys.png" alt="New Project dialog" class="img-responsive">

Copy primary connection string and add it to _Web.config_.

    <add name="EPiServerAzureBlobs" 
        connectionString="DefaultEndpointsProtocol=https;AccountName=epinewssite;AccountKey={the key}" />

And last connection string is for _Service Bus_. In old Azure Portal select _Service Bus_ in left menu and _Connection information_ on the bottom.

<img src="/img/2015-04/azure_service_bus_connection.png" alt="New Project dialog" class="img-responsive">

Copy connection information from modal window.

<img src="/img/2015-04/azure_service_bus_connection.png" alt="New Project dialog" class="img-responsive">

And add copied connection string to _Web.config_.

    <add name="EPiServerAzureEvents" 
        connectionString="Endpoint=sb://epinewssite.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey={the key}" />

# Deploy to Azure

The simplest way to deploy to Azure is with Visual Studio publishing. Right click on project in _Solution Explorer_ and select _Publish_.

<img src="/img/2015-04/vs_publish_to_azure.png" alt="New Project dialog" class="img-responsive">

Then select _Microsoft Azure Web Apps_, connect with your credentials and select the site to deploy. Then you will get to the view with connection details and you can verify connection.

<img src="/img/2015-04/vs_publish_to_azure2.png" alt="New Project dialog" class="img-responsive">

In the next view you can select build configuration to deploy, configure file publishing and databases. For _EPiServerDB_ check _Update database_.

<img src="/img/2015-04/vs_publish_to_azure3.png" alt="New Project dialog" class="img-responsive">

Then click _Configure database updates_ where in modal window uncheck _Auto schema update_ and click _Add SQL Script_ and select CMS sql script from _[SolutionDir]\packages\EPServer.CMS.Core.7.6.0\tools\EPiServer.Cms.Core.sql_.

<img src="/img/2015-04/vs_publish_to_azure4.png" alt="New Project dialog" class="img-responsive">

Now you are ready to _Publish_.

# Creating admin user

First of all configure Azure SQL Database to allow your local computer access it. In new portal click _Browse_ in left menu, select _SQL Servers_ and select your server. Then in server settings select _Firewall_, add rule name and your public IP address to both IP address text boxes. Then click _Save_.

<img src="/img/2015-04/sql_server_firewall.png" alt="New Project dialog" class="img-responsive">

Now you should be able to open EPiServer CMS administration interface locally by logging in with your local Windows administrator credentials. Then go to _CMS_ -> _Admin_ -> _Administer Groups_ and create _WebAdmins_ and _WebEditors_ groups. After that got to _CMS_ -> _Admin_ -> _Create User_ and create new user which should be added to both previously created groups.

You should be able to login into EPiServer CMS administration interface with newly created user.

Now you are ready to start creating your site - add page types, controllers, views, create content and configure EPiServer Website as you need. For additional information and configuration refer to [EPiServer documentation](http://world.episerver.com/documentation/Items/Developers-Guide/EPiServer-CMS/8/Deployment/Deployment-scenarios/Deploying-to-Azure-webapps/).