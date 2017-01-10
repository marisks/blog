---
layout: post
title: "Starting Xamarin Android application development with F#"
description: "I am not a mobile application developer but I needed to build an Android application. As for .NET developer, Xamarin Android was a natural choice."
category:
tags: [F#, Android]
date: 2016-04-19
visible: true
---

# Introduction

Previously I tried to build [Xamarin Android](https://developer.xamarin.com/guides/android/) applications in _F#_ too. I was able to create a simple application, but I had issues creating _PCL_ libraries to be able to reuse common code with other applications. Now I have installed [Visual Studio 2015 Update 2](https://www.visualstudio.com/en-us/news/vs2015-update2-vs.aspx) which includes new project templates for _F#_, including _Android_, _iOS_, and _PCL_.

# Creating a F# Android application

With a new update of _Visual Studio_, _F#_ finally gets _PCL_ library templates which allow building cross-platform libraries. By using _PCL_ library in my _Android_ application, I can keep all application logic separately from UI. And if I would like to build _iOS_ or _Windows Phone_ versions of my application, I could reuse the library.

So let's start with _PCL_ library. I chose _PCL_ library template which has support for _iOS_, _Android_, and _Windows Phone_.

<img src="/img/2016-04/android-fsharp-new-pcl.png" alt="Creating new PCL library for iOS, Android and Windows Phone dialog." class="img-responsive" />

Next, I wanted to create _Android_ application - chose _Blank App (Android)_ template.

<img src="/img/2016-04/android-fsharp-new-android-app.png" alt="Creating new Android application dialog." class="img-responsive" />

But after selecting the template and creating the project, the project fails to load. After some googling found out the I am not the only guy with such [issue](http://stackoverflow.com/q/36349718/660154). Also found that it might be caused by _Android_ template to expect _F# SDK 3.0_ to be installed, but _Visual Studio_ is installed with _F# SDK 3.1_. When I installed _SDK 3.0_ from [here](http://go.microsoft.com/fwlink/?LinkId=261286), the project started to load.

# Deploying an application to an Android Emulator

## Issues with Android Emulator

Previously I successfully deployed an application to a phone, but never got default _Android Emulator_ to run and didn't try other emulators. I tried it again, but still - no success. When deploying an application from _Visual Studio_, _Android Emulator_ starts with a black screen and nothing happens. When I tried to run it from _Android Emulator Manager_, it displayed _Android_ logo and hung. I didn't bother to find out why because there are other options available.

## Issues with Visual Studio Android Emulator

_Visual Studio Android Emulator_ seemed really good, but unfortunately, it doesn't run on my computer. It uses _Hyper-V_ virtual machine. I had _Hyper-V_ enabled, but it didn't work because I have a _Windows 10 Pro_ upgraded from _Windows 10 Home_. And there is an issue with _Windows_ upgrade that it doesn't create _Hyper-V_ administrator group and it is not possible to create it manually.

I could install _Windows 10 Pro_ from the scratch, but _Windows 10 Multiple Editions_ _ISO_ image I have from _MSDN_ doesn't give me a choice to install _Windows 10 Pro_ - it installs _Home_ version by default.

So I had to find another option for _Android_ emulation.

## Genymotion - Android Emulator which works

I found that there is another _Android Emulator_ - [Genymotion](https://www.genymotion.com/). It uses _VirtualBox_ for _Android_ emulation.

After installation tried to run it, but it failed. After some googling found that _Hyper-V_ has to be disabled. As I am not using it (and unable to use it), I turned it off. But there are options to [switch between Hyper-V and VirtualBox](http://www.hanselman.com/blog/SwitchEasilyBetweenVirtualBoxAndHyperVWithABCDEditBootEntryInWindows81.aspx).

Now I am able to run and deploy my _Android_ application from _Visual Studio_ in an emulator:

# Deploying an application to a device

Deployment onto device were simple. First had to enable developer options by opening _Settings -> About phone_ and tapping multiple times on _Build number_. Next, enable _USB debugging_ in _Developer options_, connect the phone to the computer. _Windows 10_ finds required drivers and connects the phone. Then an option to debug an application on the phone appeared in _Visual Studio_. Start debugging and application gets deployed to the phone.

# Summary

After initial _Android_ application project setup and successful deployment to an emulator and device, it is quite easy for .NET developer to start creating applications. But getting started is not smooth and could frighten off some developers. I hope that after _Microsoft_ [acquisition](http://blogs.microsoft.com/blog/2016/02/24/microsoft-to-acquire-xamarin-and-empower-more-developers-to-build-apps-on-any-device/#sm.0001ow17ovl7ydvbwzj26l7705nl5) of _Xamarin_, things will get better.
