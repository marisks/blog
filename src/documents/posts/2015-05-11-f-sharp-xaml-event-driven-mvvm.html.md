---
layout: post
title: "F# Xaml - event driven MVVM"
description: "I have tried two different approaches to create Xaml application - MVC and MVVM, but did not feel that those are functional enough. In this article I am looking at event driven MVVM using FSharp.ViewModule's EventViewModelBase."
category: [F#]
tags: [F#, Xaml, WPF]
date: 2015-05-11
visible: true
---

<p class="lead">
I have tried two different approaches to create Xaml application - MVC and MVVM, but did not feel that those are functional enough. In this article I am looking at event driven MVVM using FSharp.ViewModule's EventViewModelBase.
</p>

# Introduction

In my last article about [F# Xaml application](/2015/04/27/f-sharp-xaml-application-mvvm-vs-mvc/) [Reed Copsey](http://reedcopsey.com/) pointed out in [comment](/2015/04/27/f-sharp-xaml-application-mvvm-vs-mvc/#comment-1990588618) that _FSharp.ViewModule's_ _EventViewModelBase_ allows handling commands as event stream. In this article I am looking how to rewrite my game score board event driven way using _EventViewModelBase_.

User interface remains same as in [previous version](/2015/04/27/f-sharp-xaml-application-mvvm-vs-mvc/) and _Xaml_ view is almost same.

-- Describe that require installing FSharp.ViewModule and FsXaml

# Event driven MVVM

First of all define model. It is simple record type with two values for score for two teams. 

    type Score = {
        ScoreA: int
        ScoreB: int
    }

Then define events the view model will handle and pass as type parameter to _EventViewModelBase<'a>_. For this purpose define discriminated union with events for increasing, decreasing score and starting new game. Those are similar as in [MVC version](/2015/04/27/f-sharp-xaml-application-mvvm-vs-mvc/) of application.

    type ScoringEvent = IncA | DecA | IncB | DecB | New

Now define view model itself and inherit from _EventViewModelBase<ScoringEvent>_.

    type MainViewModel() as self = 
        inherit EventViewModelBase<ScoringEvent>()

Create member to store score in mutable field and initialize it with default value. Also create backing fields and properties for these fields which will be used to bind score to _Xaml_ view's labels. This is same as in [MVVM version](/2015/04/27/f-sharp-xaml-application-mvvm-vs-mvc/) from previous article.

    let defaultScore = { ScoreA = 0; ScoreB = 0}
    let mutable score = defaultScore

    let scoreA = self.Factory.Backing(<@ self.ScoreA @>, "00")
    let scoreB = self.Factory.Backing(<@ self.ScoreB @>, "00")

    member self.ScoreA with get() = scoreA.Value 
                        and set value = scoreA.Value <- value
    member self.ScoreB with get() = scoreB.Value 
                        and set value = scoreB.Value <- value

_EventViewModelBase<'a>_ has property _EventStream_ of type _IObservable<'a>_ - in our case it is _IObservable<ScoringEvent>_. _EventViewModelBase<'a>_ will trigger all bound events on this stream, so use this property to subscribe to the events.

Scoring application has to handle all the events accordingly and update the view model. So I created separate functions for both - _eventHandler_ and _updateScore_. Then subscribe to _EventStream_ to handle events. As _eventHandler_ returns _unit_ and _updateScore_ input parameters _unit_ I can easily compose both functions.

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

The last thing is binding of events to commands. _EventViewModelBase<'a>_ has _Factory_ property with method _EventValueCommand_ which helps to bind events. _EventValueCommand_ has several overloads:

- _EventValueCommand():Input.ICommand_ - it creates command without any even bound. Events for such command are bound using _EventArgsConverter<'a, 'b>_ which is useful for mouse event binding. There is a good example in [_FsXaml_ repository](https://github.com/fsprojects/FsXaml/tree/master/demos/WpfSimpleDrawingApplication).
- _EventValueCommand(valueFactory: 'b -> 'a):Input.ICommand_ - uses factory function to create event of type _'a_ from some value of type _'b_.
- _EventValueCommand(value:'a):Input.ICommand_ - creates command from event of type _'a_.

Scoring application has simple events one per command, so just create command by providing event value.

    member self.IncA = self.Factory.EventValueCommand(IncA)
    member self.DecA = self.Factory.EventValueCommand(DecA)
    member self.IncB = self.Factory.EventValueCommand(IncB)
    member self.DecB = self.Factory.EventValueCommand(DecB)
    member self.NewGame = self.Factory.EventValueCommand(New)

Now everything is ready - run application and verify that everything works.

You can find full source code for this version of application on [GitHub](https://github.com/marisks/evented_mvvm/tree/basic).

## Introducing Controller

I also defined static member _zero_ which is used to initialize or reset score.

-- Describe version with controller

## Pros

-- More functional, event driven etc. 

## Cons

-- Still has some mutable state etc, model not embedded into events

# Summary

-- Describe how it became more functional and easier to work with etc. But i don't know about larger apps. Describe how extracting controller could be aslo extracted event filtering and handlin etc. Also that it is easy to use your way.