---
layout: post
title: "Calling async methods within Episerver events"
description: >
  <t render="markdown">
  In the article [Better event handling in Episerver](/2017/02/12/better-event-handling-in-episerver/), I wrote how to handle _Episerver_ events. I was calling the async _Publish_ method of mediator in the fire and forget manner. But it is not a good solution in an ASP.NET application as there is no warranty that [the running task will finish](http://stackoverflow.com/a/18509424/660154).
  </t>
category:
tags: [EPiServer]
date: 2017-04-02
visible: true
---

As I mentioned, the first version was just calling an async method and not caring if it will finish executing.

```charp
contentEvents.LoadingContent += ContentEvents_LoadingContent;

// ...

private void ContentEvents_LoadingContent(
    object sender, EPiServer.ContentEventArgs e)
{
    RunMeAsync();
}
```

It is unlikely that you would want the method to start running but not completing.

Next reasonable solution which did work in the unit tests were _async_/_await_. I had to add _async_ keyword to the event handling method and _await_ to my async method call.

```charp
private async void ContentEvents_LoadingContent(
    object sender, EPiServer.ContentEventArgs e)
{
    await RunMeAsync();
}
```

While this is the right way to handle events, it doesn't work in the ASP.NET context. You will get this exception if you try:

```
An asynchronous operation cannot be started at this time. Asynchronous operations may only be started within an asynchronous handler or module or during certain events in the Page lifecycle. If this exception occurred while executing a Page, ensure that the Page is marked <%@ Page Async="true" %>. This exception may also indicate an attempt to call an "async void" method, which is generally unsupported within ASP.NET request processing. Instead, the asynchronous method should return a Task, and the caller should await it.
```

Maybe try waiting on the task completion?

```charp
private void ContentEvents_LoadingContent(
    object sender, EPiServer.ContentEventArgs e)
{
    RunMeAsync().Wait();
}
```

Initially, when I tried it, it did work, but the performance of the site was very low. I tried it on the site which was hosted on _IIS_. But then I tried it on the new _Alloy Tech_ project running on the _IIS Express_, and it just never loaded. Unfortunately, waiting for an async method can cause deadlocks. Not sure where in this case.

After googling for some time, I found an answer on the [Stack Overflow](http://stackoverflow.com/a/5097066/660154). It suggested using some _AsyncHelpers_ class. I copied this over to my project, and it looked like working except when my async method threw an exception.

Some more googling and I found another similar [answer](http://stackoverflow.com/a/18509424/660154). In this [Stack Overflow thread](http://stackoverflow.com/a/18509424/660154), another _Erik Philips_ gave an example of another _AsyncHelper_ class which is used by _Microsoft_ internally.

```charp
internal static class AsyncHelper
{
    private static readonly TaskFactory _myTaskFactory = new 
      TaskFactory(CancellationToken.None, 
                  TaskCreationOptions.None, 
                  TaskContinuationOptions.None, 
                  TaskScheduler.Default);

    public static TResult RunSync<TResult>(Func<Task<TResult>> func)
    {
        return AsyncHelper._myTaskFactory
          .StartNew<Task<TResult>>(func)
          .Unwrap<TResult>()
          .GetAwaiter()
          .GetResult();
    }

    public static void RunSync(Func<Task> func)
    {
        AsyncHelper._myTaskFactory
          .StartNew<Task>(func)
          .Unwrap()
          .GetAwaiter()
          .GetResult();
    }
}
```

Now calling my async method from the event handler method works perfectly.

```charp
private void ContentEvents_LoadingContent(
    object sender, EPiServer.ContentEventArgs e)
{
    AsyncHelper.RunSync(RunMeAsync);
}
```

# Conclusion

When calling an async method from the event handler method, use the solution from [this Stack Overflow answer](http://stackoverflow.com/a/25097498/660154) and don't try anything else :)

But in all other cases (controller's action method, for example) if you can, use _async_/_await_.