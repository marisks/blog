---
layout: post
title: "Common issues when setting up EPiServer Service API"
description: "Recently I had to setup Service API for one project and got some issues configuring it. Here are the list of those issues and solution to them."
category:
tags: [EPiServer]
date: 2016-03-17
visible: true
---
<p class="lead">
Recently I had to setup Service API for one project and got some issues configuring it. Here are the list of those issues and solution to them.
</p>

# Access rights

[EPiServer Documentation](http://world.episerver.com/documentation/Items/Episerver-Service-API/Configuration-and-overview/Setting-up-EPiServerServiceApi/) says that access rights are automatically added for _Administrators_ group, but it is good to verify it. Also, you might need other roles to access _Service API_. It is better to add a separate role for each of you partners accessing _Service API_. So you can remove partner access by removing roles when not needed.

Using this script you can see which roles have access to the Service API:

```
select * from tblUserPermission where GroupName = 'EPiServerServiceApi'
```

And with this script you can give read/write access:

```
insert into tblUserPermission (Name, IsRole, Permission, GroupName)
values ('Administrators', 1, 'ReadAccess', 'EPiServerServiceApi')
     , ('Administrators', 1, 'WriteAccess', 'EPiServerServiceApi')
```

For other roles, just replace _Administrators_ to other role name.

# Multiple Owin Startup classes

Sometimes you already have _Startup_ class or another library also has it's own _Startup_ and you are using it. At first, it is not obvious why authentication doesn't work. Token route (/episerverapi/token) returns _404_ code and it looks like some routing doesn't work. And that's true - _Service API_ authentication has its own routing configured. This is not a _Web API_ route, but route added to _Owin_ in _Service API_ _Startup_ class. It confused me at the beginning - I tried to find an issue with _Web API_ configuration.

The solution is simple and [documented](http://world.episerver.com/documentation/Items/Episerver-Service-API/Configuration-and-overview/Setting-up-EPiServerServiceApi/) - create another _Startup_ class in your code and configure it as a default _Startup_ class.

```
namespace Web
{
  public class Startup
  {
     public void Configuration(IAppBuilder app)
     {
         new EPiServer.ServiceApi.Startup().Configuration(app);
         new SomeLibrary.Startup().Configuration(app);
     }
  }
}
```

And configure it as default in _Web.config_:

```
<add key="owin:AppStartup" value="Web.Startup, Web" />
<add key="owin:AutomaticAppStartup" value="true" />
```

# Web API attribute routing

I mentioned previously that authentication routes are managed by _Owin_, but _Service API_ functional routes use _Web API_ - when you get _404_ for some _functional_ route (for example, /episerverapi/commerce/entries/{startPage}/{pageSize}), then _Web API_ routing is not configured properly. As described in [the documentation](http://world.episerver.com/documentation/Items/Episerver-Service-API/Configuration-and-overview/Setting-up-EPiServerServiceApi/), if you have your own _Web API_ routing configured, disable _Service API_ attribute routing configuration in _Web.config_.

```
<add key="episerver:serviceapi:maphttpattributeroutes" value="false" />
```

# Testing Service API

It is highly recommended to create integration tests before starting _Service API_ configuration. It will allow to verifying that your service API works step by step.

I have created sample test class as a [gist - EPiServer Service API smoke tests](https://gist.github.com/marisks/29f0d4b197908006ae98). It is a _XUnit_ test class. The test class verifies that authentication works and basic CRUD operations can be done.

# Summary

While _EPiServer Service API_ [documentation](http://world.episerver.com/documentation/Items/Episerver-Service-API/Configuration-and-overview/Setting-up-EPiServerServiceApi/) covers most of the needed configuration, it is quite easy to miss something.
