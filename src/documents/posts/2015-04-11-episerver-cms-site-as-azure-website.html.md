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

