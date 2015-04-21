---
layout: post
title: "F# Xaml application - MVVM vs MVC"
description: "Most popular approach for creating Xaml applications is MVVM - Model View ViewModel. But there is an alternative - MVC (Model View Controller). So what are advantages of using one or another in your F# projects?"
category: [F#]
tags: [F#, Xaml]
date: 2015-04-27
visible: true
---

<p class="lead">
Most popular approach for creating Xaml applications is MVVM - Model View ViewModel. But there is an alternative - MVC (Model View Controller). So what are advantages of using one or another in your F# projects?
</p>

# Introduction

I am mainly Web developer and haven't created much desktop applications. I started some toy project and wanted to try creating desktop application in WPF. I wanted to follow best practices and started to look what approaches are used to build Xaml apps. Most common choice is [MVVM](http://en.wikipedia.org/wiki/Model_View_ViewModel), but recently I was reading the book [F# Deep Dives](http://www.manning.com/petricek2/) where [Dmitry Morozov](https://twitter.com/mitekm) described [MVC](http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) way. Thanks to the [FsXaml type provider](https://github.com/fsprojects/FsXaml) implementing both approaches now is really easy.

Sample project described in this article is simple game score board. You can increase/decrease score for each team and reset score to zero when starting new game.

Creating new WPF project in F# is easy. You just have to install Visual Studio extension - [F# Empty Windows App](https://visualstudiogallery.msdn.microsoft.com/e0907c99-bb04-4eb8-9692-9333d5ff4399). Then create new project using _F# Empty Windows App_ template.

<img src="/img/2015-02/new-fsharp-wpf-project.png" alt="New Project dialog" class="img-responsive">

After creating new project you will have basic WPF project structure.

<img src="/img/2015-02/wpf-project-structure.png" alt="Project structure" class="img-responsive">

Project template also installs few NuGet packages which will help you to work with Xaml and ViewModel for MVVM.

<img src="/img/2015-02/wpf-nuget-dependences.png" alt="NuGet dependences" class="img-responsive">

Now you can start building your application. First of all let's create Xaml view for our application. The view will be same for both MVVM and MVC application with minimal differences. It should display score for both teams, there should be the buttons to increase and decrease (to fix mistaken increase) score and there should be the button to start new game. 

<img src="/img/2015-02/gasby_main_window.png" alt="Game score board main window" class="img-responsive">

For application styling I am using [mahapps.metro](http://mahapps.com/) UI toolkit for WPF.

# MVVM

First of all create model for score - record type to hold score for team A and team B.

    type Score = {
        ScoreA: int
        ScoreB: int
    }

Then define view model which will handle all UI logic. Inherit view model from ViewModelBase (you have to open FSharp.ViewModule for it).

    type MainViewModel() as self = 
        inherit ViewModelBase()

Next in Xaml view import local and model namespaces of Window control (I am using MahApps MetroWindow control). Namespace should contain also assembly name.

    <Controls:MetroWindow
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            xmlns:local="clr-namespace:ViewModels;assembly=gasby.Wpf"
            xmlns:model="clr-namespace:ViewModels;assembly=gasby.Wpf"
            xmlns:fsxaml="http://github.com/fsprojects/FsXaml"
            xmlns:Controls="clr-namespace:MahApps.Metro.Controls;assembly=MahApps.Metro"
            Title="gasby" Height="750" Width="1200">

Also add model to resource dictionary and set it as data context.

    <Controls:MetroWindow.Resources>
        <ResourceDictionary>
            <model:MainViewModel x:Key="model" />
        </ResourceDictionary>
    </Controls:MetroWindow.Resources>
    <Controls:MetroWindow.DataContext>
        <Binding Source="{StaticResource model}" />
    </Controls:MetroWindow.DataContext>

Next in view model create mutable field to store current score value and initialize it with default value. Also create two backing fields and member properties which uses these backing fields. Backing fields are created using FSharp.ViewModule factory.

    let defaultScore = { ScoreA = 0; ScoreB = 0}
    let mutable score = defaultScore

    let scoreA = self.Factory.Backing(<@ self.ScoreA @>, "00")
    let scoreB = self.Factory.Backing(<@ self.ScoreB @>, "00")

    // ...

    member self.ScoreA with get() = scoreA.Value 
                        and set value = scoreA.Value <- value
    member self.ScoreB with get() = scoreB.Value 
                        and set value = scoreB.Value <- value

Bind those properties in Xaml view to labels. Those should be bound to label's content.

    <Label Content="{Binding ScoreA}"></Label>

Now it's time for behavior. Create functions for score property update, increase/decrease of score for each team and creating new game. Score property update function - _updateScore_, just sets and formats property values from current score.

    let updateScore() =
        self.ScoreA <- score.ScoreA.ToString("D2")
        self.ScoreB <- score.ScoreB.ToString("D2")

Increase/decrease functions adds or substracts score for each team and sets new current score. _newGame_ function just sets current score to default value.

    let incA() = score <- { score with ScoreA = score.ScoreA + 1 }
    let decA() = score <- { score with ScoreA = score.ScoreA - 1 }
    let incB() = score <- { score with ScoreB = score.ScoreB + 1 }
    let decB() = score <- { score with ScoreB = score.ScoreB - 1 }
    let newGame() = score <- defaultScore

All these actions should be bound to buttons on Xaml view and also each action should update score labels. It would be possible to call _updateScore_ function in each previously create functions after state gets mutated, but there is also more functional way. State mutation functions returns _unit_ and _updateScore_ function has _unit_ as input parameter, so those can be composed like:

    let newIncA = incA >> updateScore

Then I created helper function to compose all defined functions with _updateScore_ function and pattern match on resulting tuple to extract new composed functions.

    let buildCommands (incA, decA, incB, decB, newGame) =
        let commands = [incA; decA; incB; decB; newGame] 
                        |> List.map (fun f -> f >> updateScore)
        match commands with
        | [A; B; C; D; E] -> A, B, C, D, E
        | _ -> failwith "Error"

    let (incACommand, decACommand, incBCommand, decBCommand, newGameCommand) = 
        buildCommands(incA, decA, incB, decB, newGame)

Probably manually composing each new function would be easier, but this was good excercise to do :).

Now create view model methods for each command using FSharp.ViewModule factory. I am creating sync version of commands, but it is possible to use also async version only then backing functions should also be async.

    member self.IncA = self.Factory.CommandSync(incACommand)
    member self.DecA = self.Factory.CommandSync(decACommand)
    member self.IncB = self.Factory.CommandSync(incBCommand)
    member self.DecB = self.Factory.CommandSync(decBCommand)
    member self.NewGame = self.Factory.CommandSync(newGameCommand)

Bind these commands to Xaml view like in code below. Commands are bound to Command attribute.

    <Button Command="{Binding NewGame}"></Button> 

## Pros

MVVM pattern looks quite simple. It is also popular in WPF community. It is command driven and supports two way binding.

## Cons

UI logic and view model is coupled in one view model class. It is not event-driven by default. 

# MVC

## Pros

## Cons

# Summary