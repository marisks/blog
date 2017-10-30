---
layout: post
title: "Episerver UI tests with canopy"
description: >
  <t render="markdown">
  Several months ago I wrote an article about [UI testing basics in Episerver](/2017/03/12/ui-testing-basics-in-episerver/). This is more practical article how to implement these basic principles using [canopy](https://lefthandedgoat.github.io/canopy/) testing framework.
  </t>
category:
tags: [EPiServer, F#]
date: 2017-10-30
visible: true
---

# Installation

The first step starting with [canopy](https://lefthandedgoat.github.io/canopy/) is creating a F# project - F# console application. And then installing canopy:

```powershell
Install-Package canopy
```

For more installation instructions check [the documentation](https://lefthandedgoat.github.io/canopy/).

After canopy installation, make sure that _Selenium.WebDriver_ and _FSharp.Core_ packages are updated to the latest version. This will help you avoid unexpected behavior.

# Configuration

With canopy, you can use different browsers for testing. I prefer _Firefox_ which is the default choice, but you can use _Chrome_ or even headless browser - _[PhantomJS](http://phantomjs.org/)_.

When you choose the _Firefox_, you have to add _geckodriver.exe_ to the project like in [the canopy starter pack](https://github.com/lefthandedgoat/canopyStarterKit/tree/master/canopyStarterKit). Or download it into some folder on your system and add it to the _Path_ environment variable. You can download latest _geckodriver.exe_ here: [https://github.com/mozilla/geckodriver/releases](https://github.com/mozilla/geckodriver/releases).

Now, you can start with a basic UI testing program. Open _Program.fs_ and replace the code there with this:

```fsharp
open canopy
open runner

start firefox

// Write yout UI tests here

run()

printfn "press [enter] to exit"
System.Console.ReadLine() |> ignore

quit()
```

This code starts a new _Firefox_ instance and runs tests you defined between `start firefox` and `run()`. You can try to run this application and will see that a new _Firefox_ instance gets opened.

There is one more thing I would make configurable - the root URL of your website. For this purpose, I have created a module in a new file - _Common.fs_. Add this file before _Program.fs_.

```fsharp
module Common

open canopy

let mutable rootUrl = ""

let goto path = url (rootUrl + path)
```

Here I have created a mutable variable which I will set in the _Program.fs_. I also added a helper method - _goto_, which I will use later to navigate to a specific relative URL in a website. The method is calling _canopy's_ _url_ method and combines root UR with a relative path.

Now you can set the root URL in the _Program.fs_ before the `start firefox` call.

```fsharp
open canopy
open runner
open Common

rootUrl <- "http://localhost:50356"

start firefox

run()

printfn "press [enter] to exit"
System.Console.ReadLine() |> ignore

quit()
```

# Test structuring

While I could write my tests directly in the _Program.fs_, it is not practical. Instead, I am organizing tests in different scenarios files. For this purpose, I have created a folder - _Scenarios_ directly above the _Program.fs_ file. In this folder, I am adding separate scenarios I want to test. Mostly those scenarios match a single page or a feature. For example, I might have home page scenarios or search scenarios - here the home page scenarios match tests against the home page, but the search scenarios might execute a search query in the page header and then assert on results.

As an example, I will test an _Alloy_ site.

## Scenarios

Let's look at the home page scenarios. The home page looks like this:

<img src="/img/2017-10/alloy.png" class="img-responsive" alt="Alloy website">

The page has header and footer which are common functionality for the whole site. So those are not a part of our home page scenarios. We care only about specific home page functionality - a jumbotron block on the top and three teaser blocks below.

<img src="/img/2017-10/alloy_home.png" class="img-responsive" alt="Alloy website home page">

For the home page, we can verify that all blocks are in place. But we should not test the content which can change often. In our case, the jumbotron texts might often change while we know that our teaser block titles will likely not change. An editor might also add/remove blocks. In this case, we will have to modify our tests when it happens.

So let's create a scenario.

```fsharp
module HomePageScenarios

open canopy
open Common

let positive _ =
    context "Positive home page tests"

    "When on home page" &&& fun _ ->
        goto "/"

    "it contains jumbotron" &&& fun _ ->
        displayed ".jumbotronblock"
    
    "it contains Alloy Plan" &&& fun _ ->
        "h2" *~ "Alloy Plan"

    "it contains Alloy Track" &&& fun _ ->
        "h2" *~ "Alloy Track"

    "it contains Alloy Meet" &&& fun _ ->
        "h2" *~ "Alloy Meet"

let all _ =
    positive()
```

Here I have created a module - _HomePageScenarios_. I am splitting tests into separate contexts (groups). For the home page, I have only one - _positive_. And then at the end, I have defined a function which executes all test contexts I have in this module.

Then I am opening the home page using our _goto_ function from the _Common_ module. The first assertion checks if _jumbotron_ is displayed. I am not asserting the content as it might change quite often. The last three tests check for the teaser block titles.

"*~" is a special operator in the [canopy](https://lefthandedgoat.github.io/canopy/assertions.html) which executes a regex against the content. In our example, it just checks if the _h2_ content is same as on the right, but it allows much more complex comparisons. One case which might be useful is a case-insensitive comparison.

```fsharp
"h2" *~ "(?i)Alloy Meet"
```

But knowing how to do with regex and repeating it for all assertions you need it is quite time-consuming. So we can create our assertion operator.

```fsharp
module Assertions

open canopy

let ( *=~ ) cssSelector value = cssSelector *~ ("(?i)" + value)

```

I have put it in a separate module - _Assertions_. My operator is "*=~" and the resulting assert looks like this:

```fsharp
"h2" *=~ "Alloy Meet"
```

One disadvantage is that you have to remember all these operators. Instead, you can use normal functions with a descriptive name. 

## Pages

There is one thing bothering me with navigation to the pages - I am hardcoding page URLs into tests. If these URLs change, then I have to change those in all tests. Same applies for selectors of elements. For example, ".jumbotronblock" selector might change in the future, but we are hardcoding it in the test.

For this purpose, I have created a separate module where I am defining page data.

```fsharp
module Pages

type CommonData = { url: string; heading: string }
type BasicPage = { common: CommonData }

let articlePage = {
    common = { url = "/article"; heading = "Article" }
    }

type HomePage = { common: CommonData; jumbotron: string }
let homePage = {
    common = { url = "/"; heading = "Home" };
    jumbotron = ".jumbotronblock"
    }
```

Here I am defining several types for our page definition. All pages will share some common data, so I have created _CommondData_ type to hold the URL of the page and the heading. Then I have created a _BasicPage_ type which just uses common data. This is useful for simple pages where you are not using any element selectors. You can see how I defined a _BasicPage_ value for article page. For the home page, I have created a separate type which includes common data and a jumbotron selector.

Now we can use _Pages_ module in our tests.

```fsharp
module HomePageScenarios

open canopy
open Common
open Pages

let positive _ =
    context "Positive home page tests"

    "When on home page" &&& fun _ ->
        goto homePage.common.url
    
    "it contains jumbotron" &&& fun _ ->
        displayed homePage.jumbotron
```

Now, tests are easier to maintain. It is also better for readability.

## Navigation

When testing a _CMS_ website, it is important to navigate to the pages through the navigation. In most cases, you should start with the home page, then navigate to the page you want to test, and only then perform the tests on that page.

You can write navigation manipulation directly in your tests, but it will be hard to maintain as you have to repeat this from test case to test case. So it is good to create some abstraction over navigation.

```fsharp
module Navigate

open canopy

let toAlloyPlan () =
    element ".nav"
    |> elementWithin "Alloy Plan"
    |> click

let toNth index =
    nth index ".nav > li a"
    |> click
```

Here I am showing two different approaches. The first function - _toAlloyPlan_ uses a certain navigation element. This approach works when navigation doesn't change often.

The second method - _toNth_ uses another approach. It navigates to the element by its index. This approach is useful when your navigation is dynamic.

You can combine these two approaches for your website. For example, you could have a top navigation with an element _Categories_ which has a sub-menu. The sub-menu can contain a list of categories which are dynamic. In this case, you can explicitly click on the _Categories_ navigation item and then randomly click on the category.

# Summary

_canopy_ gives you a great lightweight API over Selenium which together with F# syntax makes simple and readable tests. But you can also write your UI tests successfully in C# and Selenium without any framework. The main idea is writing your tests keeping in mind that _CMS_ content might change and structure tests accordingly.

You can find a test project on [GitHub](https://github.com/marisks/examples/tree/master/UITests/Alloy).