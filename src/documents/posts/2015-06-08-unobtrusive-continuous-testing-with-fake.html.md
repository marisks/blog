---
layout: post
title: "Unobtrusive continuous testing with FAKE"
description: >
  <t render="markdown">
  When unit testing I want to get feedback from my tests fast - usually on build. The technique is called [Continuous test-driven development](http://en.wikipedia.org/wiki/Continuous_test-driven_development) or just 'Continuous testing'. There are available several tools for it, but I wanted to try FAKE.
  </t>
category: [F#]
tags: [F#, FAKE]
date: 2015-06-08
visible: true
---

Previously I have tried different tools for continuous testing. Probably most advanced one is [NCrunch](http://www.ncrunch.net/), but it is also quite expensive. I also tried [ContinuousTests](http://www.continuoustests.com/), but it had several bugs running my builds and tests. There is also [Giles](http://codereflection.github.io/Giles/) I haven't tried.

For long period I have used _Visual Studio Ultimate_ _Test Explorer's_ feature running tests on build (see image below), but unfortunately it is not available in _Visual Studio Professional_ I have now.

<img src="/img/2015-06/test_explorer.png" alt="Visual Studio Ultimate 2013/2015 Test Explorer with run tests on build button." class="img-responsive">

So as I am learning _F#_ I decided to try [FAKE](http://fsharp.github.io/FAKE/).

I did not want to install _FAKE_ in my team's project to not bother other team members who might not want to use _FAKE_ to run tests. One way is to add _FAKE_ project's folder into ignore list of your repository, but it will require to change _.gitignore_ file for the project, so it is not a solution. Another way is to put your _FAKE_ project beside team's project.

The easiest way to start with _FAKE_ is just creating new _F#_ library or console application project and install _FAKE_ _NuGet_ package.

    Install-Package FAKE

I am using _xUnit 2_ and I need test runner for it, so install console runner.

    Install-Package xunit.runner.console -Version 2.0.0

Following [Getting started tutorial](http://fsharp.github.io/FAKE/gettingstarted.html) create _build.bat_ file for running _FAKE_ script. Just use proper _FAKE_ version in the path.

    @echo off
    cls
    "..\packages\FAKE.3.34.7\tools\Fake.exe" build.fsx
    pause

And then create _build.fsx_ script which references _FAKE_ library and opens _FAKE_ namespaces. For _xUnit 2_ I had to include _Fake.Testing_ namespace.

    #r @"../packages/FAKE.3.34.7/tools/FakeLib.dll"
    open Fake
    open Fake.Testing

Then create function which will run tests.

    let testDir  = "../../TeamProject/TeamProject.Tests/bin/Debug/"

    let runTests () =
        tracefn "Running tests..."
        !! (testDir @@ "*.Tests.dll")
        |> xUnit2 (fun p -> {
                            p with HtmlOutputPath = Some(testDir @@ "xunit.html");
                                   ToolPath = @"../packages/xunit.runner.console.2.0.0/tools/xunit.console.exe"
                            })

By convention it will run all tests in _.Tests.dll_ libraries. _testDir_ is relative directory to the test project's build output. I also had to provide test runner path in _XUnit2Params_.

Next I had to define _Watch_ task which will look for changes in test project's build output and run tests. Unfortunately there is an [issue](https://github.com/fsharp/FAKE/issues/780) with _FAKE's_ _Watch_ that it works only with absolute paths. To get the full path from relative one I had to cuse _System.IO.Path.GetFullPath_ function.

    let fullDir = System.IO.Path.GetFullPath testDir
    Target "Watch" (fun _ ->
        use watcher = !! (fullDir @@ "*.*") |> WatchChanges (fun changes ->
            runTests()
        )
        System.Console.ReadLine() |> ignore
        watcher.Dispose()
    )

It is also good to run tests in the beginning, so create separate task for it.

    Target "Test" (fun _ ->
        runTests()
    )

And the last step - create default target, configure order of targets and run.

    // Default target
    Target "Default" (fun _ ->
        trace "The end."
    )

    "Test"
    ==> "Watch"
    ==> "Default"

    RunTargetOrDefault "Default"

Script should be run from directory it relies. After running script first it will run tests and then it will start watching for test _dll_ changes. After you change your tests and build the project, _FAKE_ will run tests again.
