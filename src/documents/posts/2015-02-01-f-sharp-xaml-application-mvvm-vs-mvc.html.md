---
layout: post
title: "F# Xaml application - MVVM vs MVC"
description: "Most popular approach for creating Xaml applications is MVVM - Model View ViewModel. But there is an alternative - MVC (Model View Controller). So what are advantages of using one or another in your F# projects?"
category: [F#]
tags: [F#, Xaml]
date: 2015-02-01
visible: true
---

<p class="lead">
Most popular approach for creating Xaml applications is MVVM - Model View ViewModel. But there is an alternative - MVC (Model View Controller). So what are advantages of using one or another in your F# projects?
</p>

# Introduction
I am mainly Web developer and haven't created much desktop applications. I started some toy project and wanted to try creating desktop application in WPF. I wanted to follow best practices and started to look what approaches are used to build Xaml apps. Most common choice is [MVVM](http://en.wikipedia.org/wiki/Model_View_ViewModel), but recently I was reading the book [F# Deep Dives](http://www.manning.com/petricek2/) where [Dmitry Morozov](https://twitter.com/mitekm) described [MVC](http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) approach. Thanks to the [FsXaml type provider](https://github.com/fsprojects/FsXaml) implementing both approaches now is really easy.

Sample project described in this article is simple game score board. You can increase/decrease score for each team and reset score to zero when starting new game.

Creating new WPF project in F# is easy. You just have to install Visual Studio extension - [F# Empty Windows App](https://visualstudiogallery.msdn.microsoft.com/e0907c99-bb04-4eb8-9692-9333d5ff4399). Then create new project using _F# Empty Windows App_ template.

<img src="/img/2015-02/new-fsharp-wpf-project.png" alt="New Project dialog" class="img-responsive">

After creating new project you will have basic WPF project structure.

<img src="/img/2015-02/wpf-project-structure.png" alt="Project structure" class="img-responsive">

Project template also installs few NuGet packages which will help you to work with Xaml and ViewModel for MVVM.

<img src="/img/2015-02/wpf-nuget-dependences.png" alt="NuGet dependences" class="img-responsive">

Now you can start building your application.

# MVVM



## Pros

## Cons

# MVC

## Pros

## Cons

# Summary