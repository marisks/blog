---
layout: post
title: "Maintaining private ASP.NET and EPiServer configuration"
description: >
  <t render="markdown">
  Maintaining local development or private (secret) configuration in .NET always was hard. There is no single path how to do it. Two days ago Scott Hanselman wrote an article about <a href="http://www.hanselman.com/blog/BestPracticesForPrivateConfigDataAndConnectionStringsInConfigurationInASPNETAndAzure.aspx">best practices for private config data</a>. He describes existing way how to put configuration into an external file (which already existed since <a href="http://stackoverflow.com/a/6940086">.NET 1.1 and 2.0</a> :) ), but there are still some open questions. In this article, I am going to show one way how to solve these configuration issues.
  </t>
category:
tags: [EPiServer, .NET]
date: 2016-01-08
visible: true
---

.NET configuration system has two options to include configuration from external file into _Web.config_ or _App.config_:
- _appSettings'_ _file_ attribute where selected configuration file merges with _appSettings_ section in _Web.config_,
- _configSource_ attribute on any section where selected configuration file replaces the whole section.

Usually, you want to have a different configuration for _connectionStrings_ and _episerver.find_ sections and some _appSettings_ values for different environments (including developer computer). As [Scott Hanselman describes](http://stackoverflow.com/a/6940086), you can put those configurations into a separate file and add this file to _.gitignore_ that local configuration is not committed into the repository.

This works fine for _appSettings_ and it's _file_ attribute where missing configuration file from _file_ attribute is ignored. But it doesn't work for sections with _configSection_ attribute as it requires the configuration file. Also, sometimes it is fine to commit environment specific configuration transformation files, but if you do not have the main file, transformations cannot be applied. For example, you have _connectionStrings.PROD.config_, but do not commit _connectionStrings.config_, then transformations will fail on deployment or CI server. Developers also like to have default values setup in configuration files, so they just have to replace those with own values.

So the goals for this article is to show how to solve these issues:
- private developer configuration which never gets committed into the repository,
- default configuration values which are committed into the repository,
- support for environment specific transformation configuration files.

# Solution

In this sample, I will show how to setup _connectionStrings_, _episerver.find_ and _appSettings_ sections. First of all, in the _Web.config_ define external configuration files for all three sections and point those to developer's local configuration files as here:

```
<connectionStrings configSource="connectionStrings.dev.config" />

<appSettings file="appSettings.dev.config">
    <add key="webpages:Version" value="3.0.0.0" />
    <add key="webpages:Enabled" value="false" />
</appSettings>

<episerver.find configSource="EPiServerFind.dev.config" />
```

Then add those developer's configurations in _.gitignore_:

```
*.dev.config
```

Next create developer configuration files - _connectionStrings.dev.config_, _appSettings.dev.config_, _EPiServerFind.dev.config_ and default configuration files - _connectionStrings.config_, _appSettings.config_, _EPiServerFind.config_.

When this is done, create transformation file for _Web.config_ which will run transformations for all other environments on you CI or deployment server. This transformation file should change paths from development configuration files to default ones. We at [Geta](http://geta.no) are using [Octopus Deploy](https://octopus.com/) for deployment and by default, it always runs _Web.Release.config_ transformation before deployment. So let's create it:

```
<?xml version="1.0" encoding="utf-8"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <system.web>
    <compilation xdt:Transform="RemoveAttributes(debug)" />
  </system.web>
  <connectionStrings configSource="connectionStrings.config"
                    xdt:Transform="SetAttributes(configSource)" />
  <appSettings file="appSettings.config"
                    xdt:Transform="SetAttributes(file)" />
  <episerver.find configSource="EPiServerFind.config"
                    xdt:Transform="SetAttributes(configSource)" />
</configuration>
```

Now if you need, you can provide configuration transformations for _connectionStrings.config_, _appSettings.config_ and _EPiServerFind.config_ files too.

That's all!

# Benefits

This solution solves several issues and gives such benefits:
- developers can not accidentally commit local development configuration,
- developers have good defaults for their local configuration,
- environment specific configuration can remain in the repository,
- default configuration files are committed and are available for deployment tools to do required transformations (for example, for Octopus Deploy).
