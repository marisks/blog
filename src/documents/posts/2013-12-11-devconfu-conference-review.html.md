---
layout: post
title: "DevConFu conference review"
description: "DevConFu is first DevClub conference in Latvia which was hold 13th – 15th November 2013 in Jurmala. Before conference I was sceptical about it. I was discovering conference program and found only few interesting sessions for me. But ..."
category: 
tags: [Conferences]
date: 2013-12-11
---
Before conference I was sceptical about it. I was discovering conference program and found only few interesting sessions for me. Saw that there were many Agile, Testing, but less development related stuff. I also wanted to get to [Mark Seeman's](https://twitter.com/ploeh) session _Poka-yoke code: APIs for stupid programmers_, but was dissapointed that it didn't happen. And so I was even more sceptical. But ...

##First day

I was not attending to Workshops, but heard satisfied responses from my collegues about AngularJS session...

## Second day

### Let's Help Melly

Keynote _Let's Help Melly_ by Jurgen Apello was great and really inspiring. It changed my mind about _Agile_ sessions completely. 

### The Doctor is In

Next session I chose was workshop with J.B.Rainsberger _The Doctor is In_. In this session we were able to ask questions and get answers from J.B. I didn't ask question - couldn't formulate it, but others asked questions which answers answered my ones too. Also I got some usefult tips about unit testing:
* Name test as behavior you are testing, not as classes you are testing. Because class names, classes might change, but behavior stays as described. Such tests also are easier to understand.
* Start writing test with Assert. It will allow you to understand better behavior you are testing.

J.B. also suggested some resources for inspiring and self improvement. The ones I was interested in is:
* book [Selling the invisible](http://www.amazon.com/Selling-Invisible-Field-Modern-Marketing/dp/0446672319)
* video [Practical Tools for Playing Well with Others](https://vimeo.com/78917211)

### User Stories Don't Help Users

Session _User Stories Don't Help Users_ by William Hudson showed different perspectives how to look on requirements. User stories we are used to does not describe requirements fully and might miss lot of details which are important:
* User stories focuses on user roles which we do not really understand.
* User stories are described from first person perspective, but it might be wrong - author or reader of user story is not system user.
* First person reduces creativity.
* User stories are mostly written by technologists which do not understand user.
* User stories are written too early - before shaping the system.

The solution for this is Persona stories which are just evolved user stories which looks to requirement from specific persona perspective:
* Uses persona instead of roles. For example, Mary buys tickets to theater for herself.
* Written as third persona.
* Written by usability experts.
* Written after shaping system design - after user research and conseptual design.
* The format of persona stories: persona, action, goal.

### Toys are us – Interactive apps with Gadgets (DiY)

In _Toys are us – Interactive apps with Gadgets (DiY)_ by Sascha Wolter we saw some fun stuff - different gadgets, but the main goal is that by playing with such toys we can get inspiration. Also showing clients solutions using gadgets can improve communication between us, find solutions to different problems and innovate.

### What?!? C# Could Do That?!?

Last session in second day I was attending was _What?!? C# Could Do That?!?_ by Shay Friedman. He showed with examples how to use dynamics in C#. How to stay with static typing, but same time reusing code for different types - inputs as dynamics and outputs as generic type. He also show example how to use expando object, elastic object, several help attributes for debugging, FailFast method ;), and explained Roslyn project.

### Summary of the day

After my first conference day (second conference day) I changed my mind completely about this conference. All speakers at was great, they provided as much information as could be provided in conference and inspired for improvement.

## Third day

### How Agile Coaches help us win - The Agile Coach Role @ Spotify

Last day started with keynote _How Agile Coaches help us win - The Agile Coach Role @ Spotify_ by Brendan Marsh and Kristian Lindwall. They shared experience on agile coatching in Spotify, but most interesting part for me was the organization structure - how they organize company in "squads" and "tribes".

## Technical Excellence

James Grenning in his talk _Technical Excellence_ talk about values we should follow - values defined by agile principles, TDD, code quality, motivation. He pushed quite much on TDD and it inspired me to do TDDing. Unfortunately in our company we write tests rarely and are not doing TDD. I know there is no excuse for it!

## Firefox OS

First session after keynotes was about Firefox OS by Raivis Dejus. I expected to hear more about it and it's APIs. Raivis showed us Developer Preview phone with Firefox OS. He didn't explain the main idea behind Firefox OS - one common standardized API for building crossplatform applications which can be implemented not only by Firefox, but also by other browser, device and OS companies. Raivis needs more practicing in speaking, but otherwise session was fine.

## Loving data with F#.

My collegue Valdis Iljuconoks was explaining Type providers in F# in his session _Loving data with F#_. And "loving" is correct word here. F# gives very powerful tool to consume data from different resources - from JSON or XML remote services, also behind authentication, generating strongly typed data structures just by knowing small data example. I see it as powerfull tool to create wrappers in .NET for different APIs. Something to research more ...

## Lessons learned from pentesting and teaching webapp security to developers

Elar Lang in _Lessons learned from pentesting and teaching webapp security to developers_ showed us real example how your site can be "hacked". While examples was simple, those were real world scenarios how it can be done in many sites. It showed that we have to include pentesting in our release process and do it often.

## Integrated Tests Are A Scam

If James Grenning inspired me to do TDD, then J.B. Rainsberger convinced me to do it in his keynote _Integrated Tests Are A Scam_. He also explaned why we should avoid integration tests and were we can apply them. Main points from talk are:
* call unit tests as isolated tests - it describes them better
* start test from entry object (controller, main method etc.)
* test object in isolation - stub dependences
* first do state based tests
* then do contracts test - behavior tests (using mocking) which verifies that your object is using interfaces as expected
* object should rely on interface's expected behavior
* then continue on next layer until reach application boundry
* at application boundry create thin layer which uses 3rd party services
* test this thin layer with integration tests and verify that behaviour matches expectations

## Summary

I did like the conference a lot - have met other people in our industry, got answers to several my questions, was inspired to work better and introduce new practices in my and my company's development process. 




