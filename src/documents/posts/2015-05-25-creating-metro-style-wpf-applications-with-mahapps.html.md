---
layout: post
title: "Creating WPF Metro style applications with MahApps.Metro"
description: "WPF gives you a lot of ways to style your Windows applications, but it might be hard to create beautiful application. I found open source project - MahApps.Metro which helps creating stylish WPF applications easily."
category: [F#]
tags: [F#, Xaml, WPF]
date: 2015-05-25
visible: true
---

<p class="lead">
WPF gives you a lot of ways to style your Windows applications, but it might be hard to create beautiful application. I found open source project - MahApps.Metro which helps creating stylish WPF applications easily.
</p>

When I started my pet project with WPF I didn't want to create my application with default styles. As I am new to WPF and Xaml I also had lot to learn and styling of apps was not my priority, but I still wanted stylish design for my application. 

For Web development there are several UI frameworks like [Bootstrap](http://getbootstrap.com/) or [Zurb Foundation](http://foundation.zurb.com/). So I thought that there should be some for WPF too and found [MahApps.Metro](http://mahapps.com/). Here is a quick tutorial how to begin with it. 

First of all install _MahApps.Metro_ _NuGet_ package into your WPF application project.

    Install-Package MahApps.Metro

Next open _MainWindow.xaml_ file, change _Window_ tag to _Controls:MetroWindow_ and add _xmlns:Controls_ attribute with _Controls_ namespace for _MahApps.Metro_ window.
    
    <Controls:MetroWindow
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:fsx="clr-namespace:FsXaml;assembly=FsXaml.Wpf"
        xmlns:fsxaml="http://github.com/fsprojects/FsXaml"
        xmlns:Controls="clr-namespace:MahApps.Metro.Controls;assembly=MahApps.Metro">

If you want to use resources or bind data context, now you should use _Controls:MetroWindow's_ appropriate tag.

        <Controls:MetroWindow.Resources>
            <ResourceDictionary>
                <local:SomeResource x:Key="ResourceKey"/>
            </ResourceDictionary>
        </Controls:MetroWindow.Resources>
        <Controls:MetroWindow.DataContext>
            <Binding Source="{StaticResource SomeResource}" Path="ThePath" />
        </Controls:MetroWindow.DataContext>

If you are using [FsXaml](https://github.com/fsprojects/FsXaml), then new window type should be automatically detected.

<img src="/img/2015-05/metro-window-fsxaml.png" alt="MetroWindow with FsXaml" class="img-responsive">

If you run your application now it will look awful :) Last step to define style resources in _App.xaml_. After that application will be ready to run.

    <Application.Resources>
      <ResourceDictionary>
        <ResourceDictionary.MergedDictionaries>
          <ResourceDictionary 
            Source="pack://application:,,,/MahApps.Metro;component/Styles/Controls.xaml" />
          <ResourceDictionary 
            Source="pack://application:,,,/MahApps.Metro;component/Styles/Fonts.xaml" />
          <ResourceDictionary 
            Source="pack://application:,,,/MahApps.Metro;component/Styles/Colors.xaml" />
          <ResourceDictionary 
            Source="pack://application:,,,/MahApps.Metro;component/Styles/Accents/Blue.xaml" />
          <ResourceDictionary 
            Source="pack://application:,,,/MahApps.Metro;component/Styles/Accents/BaseLight.xaml" />
        </ResourceDictionary.MergedDictionaries>
      </ResourceDictionary>
    </Application.Resources>

Default styles for application are light blue. Here is my application with this style applied.

<img src="/img/2015-05/gasby-light-blue.png" alt="Application with light blue style" class="img-responsive">

To change styles you have to change last two resources. First is for color and second for light (_BaseLight.xaml_) or dark (_BaseDark.xaml_) base. There are available quite a lot of colors: Amber, BaseDark, BaseLight, Blue, Brown, Cobalt, Crimson, Cyan, Emerald, Green, Indigo, Lime, Magenta, Mauve, Olive, Orange, Pink, Purple, Red, Sienna, Steel, Taupe, Teal, Violet, Yellow. Actual list of all colors can be found [here](https://github.com/MahApps/MahApps.Metro/tree/master/MahApps.Metro/Styles/Accents).

Below is my application with dark steel style.

<img src="/img/2015-05/gasby-dark-steel.png" alt="Application with dark steel style" class="img-responsive">

For more information on how to start check [introduction tutorial](http://mahapps.com/guides/quick-start.html).

_MahApps.Metro_ also has different styles for different [controls](http://mahapps.com/controls/) and it can customize your [titlebar](http://mahapps.com/guides/quick-start.html#customization).


