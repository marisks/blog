---
layout: post
title: "F# Xaml - event driven MVVM"
description: "I have tried two different approaches to create Xaml application - MVC and MVVM, but did not feel that those are functional enough. In this article I am looking at event driven MVVM using FSharp.ViewModule's EventViewModelBase<'a>."
category: [F#]
tags: [F#, Xaml, WPF]
date: 2015-05-11
visible: true
---

<p class="lead">
I have tried two different approaches to create Xaml application - MVC and MVVM, but did not feel that those are functional enough. In this article I am looking at event driven MVVM using FSharp.ViewModule's EventViewModelBase<'a>.
</p>

# Introduction

In my last article about [F# Xaml application](/2015/04/27/f-sharp-xaml-application-mvvm-vs-mvc/) [Reed Copsey](http://reedcopsey.com/) [pointed out](/2015/04/27/f-sharp-xaml-application-mvvm-vs-mvc/#comment-1990588618) that _FSharp.ViewModule's_ _EventViewModelBase<'a>_ allows handling commands as event stream. In this article I am looking how to rewrite my game score board event driven way using _EventViewModelBase<'a>_.

User interface and _Xaml_ view remains same as in [previous version](/2015/04/27/f-sharp-xaml-application-mvvm-vs-mvc/) and view model requires some changes described in next paragraphs.

# Event driven MVVM

First of all define model. It is simple record type with two score values for two teams. 

    type Score = {
        ScoreA: int
        ScoreB: int
    }

Then define event type which will be used in view model's event stream and should be passed as type parameter to _EventViewModelBase<'a>_. For this purpose define discriminated union with events for increasing, decreasing score and starting new game. Those are similar as in [MVC version](/2015/04/27/f-sharp-xaml-application-mvvm-vs-mvc/) of application.

    type ScoringEvent = IncA | DecA | IncB | DecB | New

Now define view model itself and inherit from _EventViewModelBase&lt;ScoringEvent&gt;_.

    type MainViewModel() as self = 
        inherit EventViewModelBase<ScoringEvent>()

Create mutable field to store score and initialize it with default value. Also create backing fields and properties for fields which will be used to bind score to _Xaml_ view's labels. This is same as in [MVVM version](/2015/04/27/f-sharp-xaml-application-mvvm-vs-mvc/) from previous article.

    let defaultScore = { ScoreA = 0; ScoreB = 0}
    let mutable score = defaultScore

    let scoreA = self.Factory.Backing(<@ self.ScoreA @>, "00")
    let scoreB = self.Factory.Backing(<@ self.ScoreB @>, "00")

    member self.ScoreA with get() = scoreA.Value 
                        and set value = scoreA.Value <- value
    member self.ScoreB with get() = scoreB.Value 
                        and set value = scoreB.Value <- value

_EventViewModelBase<'a>_ has property _EventStream_ of type _IObservable<'a>_ - in our case it is _IObservable&lt;ScoringEvent&gt;_. _EventViewModelBase<'a>_ will trigger all bound events onto this stream that it is possible to use this property to subscribe to the events.

Scoring application has to handle all the events and update the view model. So I created separate functions for both actions - _eventHandler_ and _updateScore_. Then subscribe to _EventStream_ to handle events. As _eventHandler_ returns _unit_ and _updateScore_ has input parameter _unit_, I can easily compose both functions.

    let updateScore () =
        self.ScoreA <- score.ScoreA.ToString("D2")
        self.ScoreB <- score.ScoreB.ToString("D2")

    let eventHandler ev =
        match ev with
        | IncA -> score <- {score with ScoreA = score.ScoreA + 1}
        | DecA -> score <- {score with ScoreA = score.ScoreA - 1}
        | IncB -> score <- {score with ScoreB = score.ScoreB + 1}
        | DecB -> score <- {score with ScoreB = score.ScoreB + 1}
        | New -> score <- defaultScore

    do
        self.EventStream
        |> Observable.subscribe (eventHandler >> updateScore)
        |> ignore

The last task is binding events to commands. _EventViewModelBase<'a>_ has _Factory_ property with method _EventValueCommand_ which helps to bind events. _EventValueCommand_ has several overloads:

- _EventValueCommand():Input.ICommand_ - it creates command without any event bound. Events for such command are bound using _EventArgsConverter<'a, 'b>_ which is useful, for example, for mouse event binding. There is a good example in [_FsXaml_ repository](https://github.com/fsprojects/FsXaml/tree/master/demos/WpfSimpleDrawingApplication).
- _EventValueCommand(valueFactory: 'b -> 'a):Input.ICommand_ - uses factory function to create event of type _'a_ from some value of type _'b_.
- _EventValueCommand(value:'a):Input.ICommand_ - creates command from event of type _'a_.

Scoring application has simple events one per command, so just create command by providing event value.

    member self.IncA = self.Factory.EventValueCommand(IncA)
    member self.DecA = self.Factory.EventValueCommand(DecA)
    member self.IncB = self.Factory.EventValueCommand(IncB)
    member self.DecB = self.Factory.EventValueCommand(DecB)
    member self.NewGame = self.Factory.EventValueCommand(New)

Now everything is ready - run application and verify that it works.

You can find full source code for this version of application on [GitHub](https://github.com/marisks/evented_mvvm/tree/basic).

## Introducing Controller

Current solution is simple enough, but it does not conform well to [Single Responsibility Principle](http://en.wikipedia.org/wiki/Single_responsibility_principle). So I want to show how to refactor it by introducing controller which will handle model changes.

First of all extend model with static member _zero_ which is used to initialize and reset score.

    type Score = {
        ScoreA: int
        ScoreB: int
    } with 
        static member zero = {ScoreA = 0; ScoreB = 0}

Our handler function takes _ScoringEvent_ as a parameter and returns _unit_. It could be possible to extract it as a controller, but I wanted to make my controller a [pure function](http://en.wikipedia.org/wiki/Pure_function). So my controller takes model and event as a parameter and returns new model. Here is controller type - it is just simple function.

    type Controller = Score -> ScoringEvent -> Score

Now inject controller into view model.

    type MainViewModel(controller : Controller) as self = 
        inherit EventViewModelBase<ScoringEvent>()

And rewrite _eventHandler_ function to use newly created controller. Now _eventHandler_ works as an _adapter_ between controller and event stream and handles mutable state change.

    let eventHandler ev =
        score <- controller score ev

Now create controller function. For this purpose I have created separate module.

    module Handling = 

        let controller score ev =
           match ev with
            | IncA -> {score with ScoreA = score.ScoreA + 1}
            | DecA -> {score with ScoreA = score.ScoreA - 1}
            | IncB -> {score with ScoreB = score.ScoreB + 1}
            | DecB -> {score with ScoreB = score.ScoreB - 1}
            | New -> Score.zero 

The last task is composing all parts together. When you have view model without default contsructor, _Xaml_ requires separate type which provides instance of view model. First of all define type _CompositionRoot_ with _ViewModel_ property which returns composed view model.

    type CompositionRoot() =
        member x.ViewModel with get() = MainViewModel(Handling.controller)

Then modify _Xaml_ view to include this type as resource.

    <Controls:MetroWindow.Resources>
        <ResourceDictionary>
            <local:CompositionRoot x:Key="CompositionRoot"/>
        </ResourceDictionary>
    </Controls:MetroWindow.Resources>

And set _DataContext_ by providing _CompositionRoot_ as a source and path to _ViewModel_ property.

    <Controls:MetroWindow.DataContext>
        <Binding Source="{StaticResource CompositionRoot}" Path="ViewModel" />
    </Controls:MetroWindow.DataContext>

Application is ready to run. For this simple example it might be overhead to extract such controller, but for more complex scenarios and for testing purposes it is worth to.

You can find full source code for this version of application on [GitHub](https://github.com/marisks/evented_mvvm/tree/mvc).

# Summary

I like event driven _MVVM_. It makes code easy to extend as you saw in second example. Application's view model is responsible for model and event binding, but controller for model changes _functional_ way. Extracting controller is not the only option to improve your _MVVM_ application - you could inject some event filtering functions, event subscribers, separate controllers for separate events etc. based on your application needs. You can make application to look like _MVC_, but have no enforcement from some framework on how to implement it because _FSharp.ViewModule_ is [library and not a framework](http://tomasp.net/blog/2015/library-frameworks/).