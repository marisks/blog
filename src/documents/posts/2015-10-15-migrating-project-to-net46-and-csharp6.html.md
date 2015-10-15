---
layout: post
title: "Migrating project to .NET 4.6 and C# 6"
description: "Migration process of the project to .NET 4.6 and C# 6 is quite simple, but still requires some steps to do."
category: [.NET]
tags: [.NET, C#]
date: 2015-10-15
visible: true
---

<p class="lead">
Migration process of the project to .NET 4.6 and C# 6 is quite simple but still requires some steps to do.
</p>

# .NET 4.6

First check if your Continuous Integration server supports project build for .NET 4.6. For example, _Team City_ starting version 9 supports it.

Next check if your target servers have [.NET 4.6 installed](https://msdn.microsoft.com/en-us/library/hh925568).

Now change project's target framework to .NET 4.6, rebuild, commit, push.

# C# 6

If you are using VS 2015, then C# 6 should be working out of the box, but it will not work in VS 2013. To be able to compile project in VS 2013 with C# 6 features, install Microsoft.Net.Compilers NuGet package to your project:

    Install-Package Microsoft.Net.Compilers

Also, if you are using _ReSharper_ (version 9 and up), you have to configure it to use C# 6 syntax. Select project in _Solution Explorer_ and open _Properties_ pane. Under _ReSharper_ section change _C# Language Level_ to C# 6.0.

<img src="/img/2015-10/resharper-csharp-6.png" alt="ReSharper C# 6.0 settings" class="img-responsive">

Now C# 6 features should be available and the project should compile. 

There was one issue after the first build - _Visual Studio_ displayed me C# 6 features as errors. Deletion of _.suo_ file and restarting _Visual Studio_ helped to solve it.