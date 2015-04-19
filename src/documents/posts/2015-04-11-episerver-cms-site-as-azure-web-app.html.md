---
layout: post
title: "EPiServer CMS site as Azure Web App"
description: "Lately Azure become really popular hosting you web applications and websites. EPiServer also has made their CMS able to run on Azure. In this article I am describing my experience to setup EPiServer CMS on Azure."
category: [EPiServer]
tags: [EPiServer,Azure]
date: 2015-04-11
visible: true
---

<p class="lead">
Lately Azure become really popular hosting you web applications and websites. EPiServer also has made their CMS able to run on Azure. In this article I am describing my experience to setup EPiServer CMS on Azure.
</p>

While _EPiServer_ provides [documentation](http://world.episerver.com/documentation/Items/Developers-Guide/EPiServer-CMS/8/Deployment/Deployment-scenarios/Deploying-to-Azure-webapps/) on how to do deployment to _Azure_ I want to document my experience.

# Creating EPiServer CMS site

So first task is creating new _EPiServer CMS_ site. This is really easy using [Visual Studio Extension for EPiServer CMS](https://visualstudiogallery.msdn.microsoft.com/4ad95160-e72f-4355-b53e-0994d2958d3e). Extension adds _EPiServer_ project template and several item templates to _Visual Studio_.

Start creating project using _EPiServer Web Site_ project template.

<img src="/img/2015-04/new_episerver_project.png" alt="New Project dialog" class="img-responsive">

Then select type of the project. I am creating _Empty_ _MVC_ project. Also uncheck _Add EPiServer Search_. I am not going to use search and it also requires additional configuration steps.

<img src="/img/2015-04/new_episerver_project2.png" alt="Project type dialog" class="img-responsive">

According to documentation I will need _EPiServer.Azure_ _NuGet_ package installed from [EPiServer NuGet Feed](http://nuget.episerver.com/).

<img src="/img/2015-04/episerver_azure_nuget.png" alt="EPiServer.Azure NuGet package dialog" class="img-responsive">

# Setting up Azure Web App for EPiServer

I am going to use new [Azure Portal](https://portal.azure.com/). Documentation describes old [portal](https://manage.windowsazure.com).

## Creating Azure Web App

Start creating new _Web App_ by clicking _New_ button on the left bottom corner. Then select _Web + Mobile_ -> _Web app_. Provide URL of the site and select application service plan. I also can create new application service plan here by clicking _Or create new_. Then check _Add to Startboard_ - this will allow me to easier find site later. After it's done, click _Create_.

<img src="/img/2015-04/new_azure_webapp.png" alt="Create new Web App view" class="img-responsive">

It will take some time while _Web App_ is creating. After it is created, I can open _Web App_ management view from _Startboard_ or by clicking _Browse_ on the left menu.

<img src="/img/2015-04/website_main_view.png" alt="Web App management view" class="img-responsive">

## Creating SQL Database

New portal do not have an option to create _SQL Database_ while creating new _Web App_. So I have to do myself ourselves.

Start creating _SQL Database_ by clicking _New_ button, then select _Data + Storage_ -> _SQL Database_.

<img src="/img/2015-04/new_azure_sql_db.png" alt="Create new SQL Database view" class="img-responsive">

Provide new database name and select or create new server. I am creating new server as I do not have one yet.

<img src="/img/2015-04/new_azure_sql_db2.png" alt="Create new SQL Server view" class="img-responsive">

I will use _Blank database_ as source. Then I can select pricing, provide database collation and select or create resource group, but I will leave default values here. I will also add DB to _Startboard_ by checking _Add to Startboard_. Wait until DB is created and then open _SQL Database_ management view where I can see DB status and _Properties_ like _Connection Strings_.

<img src="/img/2015-04/new_azure_sql_db3.png" alt="SQL Database management view" class="img-responsive">

## Creating Azure Storage

_Azure_ _Web Apps_ do not have filesystem as we used to in _Windows_. Instead I have to create _Azure_ _Storage_ to store files.

Start creating it by clicking on _New_, select _Data + Storage_ -> _Storage_.

<img src="/img/2015-04/new_azure_storage.png" alt="Create new Storage view" class="img-responsive">

Provide name of the _Storage_ (it should be in lowercase as described in documentation), select pricing, select or create resource group, select location and if needed can enable diagnostics. _Storage_ creation also will take some time and after it is created, I can navigate to _Storage_ management view. 

<img src="/img/2015-04/new_azure_storage2.png" alt="Storage management view" class="img-responsive">

## Creating Service Bus

_Service Bus_ in _EPiServer_ is used to handle messages between multiple site instances (if those are created for scaling purposes). _Service Bus_ creation is not available in new _Azure Portal_ at the time of writing this blog post. I have to login into old [portal](https://manage.windowsazure.com) first.

Create _Service Bus_ by selecting _Service Bus_ from left menu and click _Create a  new namespace_.

<img src="/img/2015-04/new_azure_servicebus.png" alt="Create new Service Bus view" class="img-responsive">

Then provide namespace name, select region, type - _MESSAGING_ and messaging tier - _STANDARD_ as it is described in _EPiServer_ documentation.

<img src="/img/2015-04/new_azure_servicebus2.png" alt="Create new Service Bus namespace" class="img-responsive">

# Configuring EPiServer CMS project

First of all I have to provide configuration for _Storage_ and _Service Bus_. Open _Visual Studio_ project and open _Web.config_. In _episerver.framework_ section add _blob_ and _event_ configuration.

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

_container_ and _topic_ are the names for _Storage_ container and _Service Bus_ topic accordingly. Those should be unique per _Web App_ and _Storage_ or _Service Bus_. _connectionStringName_ attribute value is the name of connection string from _connectionStrings_ section.

I have to configure three connection strings - for _SQL Database_, _Storage_ and _Service Bus_. First copy connection string for _SQL Database_ which I can find in new _Azure Portal_ in _Properties_ view for _SQL Database_. 

<img src="/img/2015-04/new_azure_sql_db3.png" alt="SQL Database management view with connection strings" class="img-responsive">

I have to change password in the connection string to my user's password and add _MultipleActiveResultSets=True_ as required by _EPiServer_ documentation.

    <add name="EPiServerDB" 
        connectionString="Server=tcp:episites.database.windows.net,1433;Database=episnewssite;User ID=marisks@episites;Password={your_password_here};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;MultipleActiveResultSets=True" 
        providerName="System.Data.SqlClient" />

Next add connection string for _Storage_ with same name as configured for blobs. I found connection string in _Storage_ management view under _Keys_.

<img src="/img/2015-04/azure_storage_keys.png" alt="Storage management view with keys" class="img-responsive">

Copy primary connection string and add it to _Web.config_.

    <add name="EPiServerAzureBlobs" 
        connectionString="DefaultEndpointsProtocol=https;AccountName=epinewssite;AccountKey={the key}" />

And last connection string is for _Service Bus_. In old _Azure Portal_ select _Service Bus_ in left menu and _Connection information_ on the bottom.

<img src="/img/2015-04/azure_service_bus_connection.png" alt="Service Bus list view" class="img-responsive">

Copy connection information from modal window.

<img src="/img/2015-04/azure_service_bus_connection2.png" alt="Service Bus connection information view" class="img-responsive">

And add copied connection string to _Web.config_.

    <add name="EPiServerAzureEvents" 
        connectionString="Endpoint=sb://epinewssite.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey={the key}" />

# Deploy to Azure

The simplest way to deploy to _Azure_ is with _Visual Studio_ publishing. Right click on project in _Solution Explorer_ and select _Publish_.

<img src="/img/2015-04/vs_publish_to_azure.png" alt="Publishing select publish target dialog" class="img-responsive">

Then select _Microsoft Azure Web Apps_, provide credentials and select the site to deploy. Then it will open the view with connection details and I can verify connection.

<img src="/img/2015-04/vs_publish_to_azure2.png" alt="Publishing connection details dialog" class="img-responsive">

In the next view I can select build configuration to deploy, configure file publishing and databases. For _EPiServerDB_ check _Update database_.

<img src="/img/2015-04/vs_publish_to_azure3.png" alt="Publishing settings dialog" class="img-responsive">

Then click _Configure database updates_ where in modal window uncheck _Auto schema update_ and click _Add SQL Script_ and select CMS sql script from _[SolutionDir]\packages\EPServer.CMS.Core.{version}\tools\EPiServer.Cms.Core.sql_.

<img src="/img/2015-04/vs_publish_to_azure4.png" alt="Publishing database update dialog" class="img-responsive">

Now I am ready to _Publish_.

# Creating admin user

First of all configure _SQL Database_ to allow local computer access it. In new portal click _Browse_ in left menu, select _SQL Servers_ and select the server. Then in server settings select _Firewall_, add rule name and local computer public IP address to both IP address text boxes. Then click _Save_.

<img src="/img/2015-04/sql_server_firewall.png" alt="SQL Database Firewall management view" class="img-responsive">

Now I am able to open _EPiServer CMS_ administration interface locally by logging in with local _Windows_ administrator credentials. Then go to _CMS_ -> _Admin_ -> _Administer Groups_ and create _WebAdmins_ and _WebEditors_ groups. After that got to _CMS_ -> _Admin_ -> _Create User_ and create new user which should be added to both previously created groups.

When it is done I am able to login into _EPiServer CMS_ administration interface with newly created user on deployed _EPiServer_ _Azure_ site. Now I can start creating my site - add page types, controllers, views, create content and configure _EPiServer_ website as needed. 

For additional information and configuration refer to [EPiServer documentation](http://world.episerver.com/documentation/Items/Developers-Guide/EPiServer-CMS/8/Deployment/Deployment-scenarios/Deploying-to-Azure-webapps/).