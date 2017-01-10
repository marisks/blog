---
layout: post
title: "F# Xaml application - MVVM vs MVC"
description: "Most popular approach for creating Xaml applications is MVVM - Model View ViewModel. But there is an alternative - MVC (Model View Controller). So what are advantages of using one or another in your F# projects?"
category: [F#]
tags: [F#, Xaml, WPF]
date: 2015-04-27
visible: true
---

# Introduction

I am mainly Web developer and haven't created much desktop applications. I started some toy project and wanted to try creating desktop application in _WPF_. I wanted to follow best practices and started to look what approaches are used to build _Xaml_ apps. Most common choice is [MVVM](http://en.wikipedia.org/wiki/Model_View_ViewModel), but recently I was reading the book [F# Deep Dives](http://www.manning.com/petricek2/) where [Dmitry Morozov](https://twitter.com/mitekm) described [MVC](http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller). Thanks to the [FsXaml type provider](https://github.com/fsprojects/FsXaml) implementing both approaches now is really easy.

Sample project described in this article is simple game score board. You can increase/decrease score for each team and reset score to zero when starting new game.

Creating new _WPF_ project in _F#__ is easy - just install _Visual Studio_ extension - [F# Empty Windows App](https://visualstudiogallery.msdn.microsoft.com/e0907c99-bb04-4eb8-9692-9333d5ff4399). Then create new project using _F# Empty Windows App_ template.

<img src="/img/2015-02/new-fsharp-wpf-project.png" alt="New Project dialog" class="img-responsive">

After creating new project you will have basic _WPF_ project structure.

<img src="/img/2015-02/wpf-project-structure.png" alt="Project structure" class="img-responsive">

Project template also installs few _NuGet_ packages which will help you to work with _Xaml_ and _ViewModel_ for _MVVM_.

<img src="/img/2015-02/wpf-nuget-dependences.png" alt="NuGet dependences" class="img-responsive">

Now you can start building your application. First of all let's create _Xaml_ view for our application. The view will be same for both _MVVM_ and _MVC_ application with minimal differences. It should display score for both teams, there should be the buttons to increase and decrease (to fix mistaken increase) score and there should be the button to start new game.

<img src="/img/2015-02/gasby_main_window.png" alt="Game score board main window" class="img-responsive">

For application styling I am using [mahapps.metro](http://mahapps.com/) UI toolkit for _WPF_.

# MVVM

First of all create model for score - record type to hold score for team A and team B.

    type Score = {
        ScoreA: int
        ScoreB: int
    }

Then define view model which will handle all UI logic. Inherit view model from _ViewModelBase_ (you have to open _FSharp.ViewModule_ for it).

    type MainViewModel() as self =
        inherit ViewModelBase()

Next in _Xaml_ view import local and model namespaces of _Window_ control (I am using _MahApps_ _MetroWindow_ control). Namespace should contain also assembly name.

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

Next in view model create mutable field to store current score value and initialize it with default value. Also create two backing fields and member properties which uses these backing fields. Backing fields are created using _FSharp.ViewModule_ factory.

    let defaultScore = { ScoreA = 0; ScoreB = 0}
    let mutable score = defaultScore

    let scoreA = self.Factory.Backing(<@ self.ScoreA @>, "00")
    let scoreB = self.Factory.Backing(<@ self.ScoreB @>, "00")

    // ...

    member self.ScoreA with get() = scoreA.Value
                        and set value = scoreA.Value <- value
    member self.ScoreB with get() = scoreB.Value
                        and set value = scoreB.Value <- value

Bind those properties in _Xaml_ view to labels. Those should be bound to label's _Content_ attribute.

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

All these actions should be bound to buttons on _Xaml_ view and also each action should update score labels. It would be possible to call _updateScore_ function in each previously created functions after state gets mutated, but there is also more functional way. State mutation functions returns _unit_ and _updateScore_ function has _unit_ as input parameter, so those can be composed like:

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

Now create view model methods for each command using _FSharp.ViewModule_ factory. I am creating sync version of commands, but it is possible to use also async version, only then backing functions should also be async.

    member self.IncA = self.Factory.CommandSync(incACommand)
    member self.DecA = self.Factory.CommandSync(decACommand)
    member self.IncB = self.Factory.CommandSync(incBCommand)
    member self.DecB = self.Factory.CommandSync(decBCommand)
    member self.NewGame = self.Factory.CommandSync(newGameCommand)

Bind these commands to _Xaml_ view like in code below. Commands are bound to _Command_ attribute.

    <Button Command="{Binding NewGame}"></Button>

## Pros

_MVVM_ pattern looks quite simple in this application. It is also popular in _WPF_ community. It is command driven and supports two way binding.

## Cons

UI logic and view model is coupled in one view model class. It is not event-driven by default.

# MVC

Start _MVC_ project with same view as _MVVM_, but without any binding attributes for controls. Instead add name for each control wich has to be updated or which will trigger some event. For example, label code below.

    <Label x:Name="ScoreALabel"></Label>

Next in _MainWindow.xaml.fs_ create model, view and controller. All should inherit from _FSharp.Desktop.UI_ base classes.

Model should be abstract class, so should add _AbstractClass_ attribute and all it's properties should be abstract too. Score board's model will keep two values for score of teams A and B.

    [<AbstractClass>]
    type ScoreModel() =
        inherit Model()

        abstract ScoreA: int with get, set
        abstract ScoreB: int with get, set

Now it's time to define view and it's events. Events are just discriminated union of all possible events we would want to handle. For game score board those are increasing/decreasing score for each team and creating new game.

    type ScoringEvents = IncA | DecA | IncB | DecB | New

The view wires model, events and _Xaml_ window together.

    type MainView(root : MainWindow) as x =
        inherit View<ScoringEvents, ScoreModel, MetroWindow>(root.Root)

Then map control events to our model events - _ScoringEvents_ by overriding _EventStreams_ property. It should return event stream (_IObservable_) of our _ScoringEvents_.

    override x.EventStreams =
        [
            let buttonClicks =
                [
                    root.IncAButton, IncA
                    root.DecAButton, DecA
                    root.IncBButton, IncB
                    root.DecBButton, DecB
                    root.NewGameButton, New
                ]
                |> List.map (fun (btn, evt) -> btn.Click
                                            |> Observable.mapTo evt)
            yield! buttonClicks
        ]

In this example I have only buttons and only _Click_ event for each. So the easiest way is to create list of button/model event tuples and then map each click event of the button to matching model event. Then use _yield!_ to return stream of events.

Next bind model to label controls by overriding _SetBindings_ method. _SetBindings_ method has model as a parameter. Binding is defined using _Binding_ class method _OfExpression_ and providing it expression with binding between controls' properties and model properties.

    override x.SetBindings model =
        let root = MainWindow(x.Root)
        let scoreFormat (s:int) = s.ToString("D2") :> obj
        Binding.OfExpression
            <@
                root.ScoreALabel.Content <- scoreFormat model.ScoreA
                root.ScoreBLabel.Content <- scoreFormat model.ScoreB
            @>

Here I used helper function - _scoreFormat_ to format model values as numbers with two digits. As label's attribute _Content_ is of type _obj_, then I had to cast result of formatted string to _obj_ too.

Now define controller. It should implement interface - _IController_ by providing model and model's events. There are two methods to implement - _InitModel_ where we set initial model values and _Dispatcher_ witch maps events with event handlers. In this example event handlers are just methods of controller class. To map events with these methods _Sync_ function is used.

    type MainController() =

        interface IController<ScoringEvents, ScoreModel> with

            member x.InitModel model =
                model.ScoreA <- 0
                model.ScoreB <- 0

            member x.Dispatcher = function
                | IncA -> Sync x.IncA
                | DecA -> Sync x.DecA
                | IncB -> Sync x.IncB
                | DecB -> Sync x.DecB
                | New -> Sync x.NewGame

        member x.IncA(model : ScoreModel) =
            model.ScoreA <- model.ScoreA + 1
        member x.IncB(model : ScoreModel) =
            model.ScoreB <- model.ScoreB + 1
        member x.DecA(model : ScoreModel) =
            model.ScoreA <- model.ScoreA - 1
        member x.DecB(model : ScoreModel) =
            model.ScoreB <- model.ScoreB - 1
        member x.NewGame(model : ScoreModel) =
            model.ScoreA <- 0
            model.ScoreB <- 0

All methods just mutates state of each score field on the model.

The last step is to wire model, view and controller together and it is done in _App.fs_. I have to instantiate model, view (by providing instance of the window) and controller and then instantiate _MVC_ class and start the application.

    [<STAThread>]
    [<EntryPoint>]
    let main argv =
        let app = App().Root

        let model = ScoreModel.Create()
        let view = MainView(MainWindow())
        let controller = MainController()
        let mvc = Mvc(model, view, controller)
        use __ = mvc.Start()

        app.Run(view.Root)

## Pros

I like that _MVC_ version uses event streams and that it separates data binding from UI logic.

## Cons

While it provides event streams there is no way to manipulate the event stream based on current view model values (at least I couldn't find a way). I also do not like mutable model, but as I understand we have to live with it also in _MVVM_ version. It also has lot more gluing code to write than _MVVM_ version.

# Summary

Both approaches seems to have diffrenet usages. _MVC_ style application is more event driven, so it would fit more for applications which produces lot of events. On the other side _MVVM_ style application is more data driven and would fit more for applications with lot of data forms and simple commands.

But I feel that non of these _Xaml_ application styles benefit much from functional programming. I imagine that ideal application should consist of the view which produces events and event holds current view state. All application logic should be handled by filtering and manipulating events and view model, and in the output it should produce new view model which is bound back to the view. For now I haven't discovered such solution.

The source code for both versions can be found on [GitHub](https://github.com/marisks/mvvm_mvc).
