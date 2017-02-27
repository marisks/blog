---
layout: post
title: "Testing events"
description: >
  <t render="markdown">
  Previously, I wrote an [article](/2017/02/12/better-event-handling-in-episerver/) how to handle events in the Episerver but I did not show how to test those. I am a fan of the Test Driven Development but when working with the Episerver it is quite hard to test the code including .NET event testing. Developers tend to not write unit tests for those. In this article, I will show that this is quite easy when using the right tools.
  </t>
category:
tags: [EPiServer, TDD]
date: 2017-02-26
visible: true
---

In the [Better event handling in Episerver](/2017/02/12/better-event-handling-in-episerver/) article, I described event handling in the initialization module. But it makes the code harder to test. Because of that, I extracted event initialization into separate class - _EventsMediator_.

```
public class EventsMediator
{
    private readonly IContentEvents _contentEvents;
    private readonly IMediator _mediator;

    public EventsMediator(IContentEvents contentEvents, IMediator mediator)
    {
        if (contentEvents == null) throw new ArgumentNullException(nameof(contentEvents));
        if (mediator == null) throw new ArgumentNullException(nameof(mediator));
        _contentEvents = contentEvents;
        _mediator = mediator;
    }

    public void Initialize()
    {
    }
}
```

_EventsMediator_ is responsible for initialization of _Episerver_ events and event publishing on the mediator. There is one method - _Initialize_ (_Uninitialize_ also is needed but I omitted it in this article) which should be called in the initialization module's _Initialize_ method. _EventsMediator_ should be registered as a singleton (same as _IMediator_ and _IContentEvents_) that there should be only one instance which is publishing events.

For testing, I chose to use a [Fixie](https://fixie.github.io/) test framework - this is simple convention based framework with great flexibility. It doesn't matter which test framework you are using but I wanted to try something new. Another tool which is used here is a [FakeItEasy](https://fakeiteasy.github.io/) fake framework. It allows easily to fake event raising and an assert method calls.

Here is the setup for our _EventsMediator_.

```
public class EventsMediatorTests
{
    private readonly EventsMediator _eventsMediator;
    private readonly IContentEvents _contentEvents;
    private readonly IMediator _mediator;

    public EventsMediatorTests()
    {
        _contentEvents = A.Fake<IContentEvents>();
        _mediator = A.Fake<IMediator>();
        _eventsMediator = new EventsMediator(_contentEvents, _mediator);

        _eventsMediator.Initialize();
    }
}
```

The test class has the postfix _Tests_ in the name - this is a default convention for _Fixie_ to look for test classes. Then in the constructor, I initialized fake content events and mediator instances which are passed into the _EventsMediator_. And then call _Initialize_ method which we are going to test for event initialization.

_Fixie_ framework runs any public method in the test class as a test. So I created a public method for the first test which tests _CheckedInContent_ event raising.

```
public void it_publishes_CheckedInContent_notification_on_CheckedInContent_event()
{
    _contentEvents.CheckedInContent +=
      Raise.With(new ContentEventArgs(ContentReference.EmptyReference));

    A.CallTo(
      () => _mediator.Publish(A<CheckedInContent>.Ignored, A<CancellationToken>.Ignored))
      .MustHaveHappened();
}
```

_CheckedInContent_ is of generic type _EventHandler&lt;ContentEventArgs&gt;_. It makes raising of the event simple with _FakeItEasy's_ _Raise.With_ and passing in event arguments. Then comes assertion - use _FakeItEasy's_ _CallTo_ method to check if the method was called. In our case, it is calling to the mediator's _Publish_ method. For now, I am ignoring parameter values but checking for correct types passed into the method.

Raising events on the custom delegate is a little bit harder. For example, _LoadingChildren_ event has a type of _ChildrenEventHandler_ delegate. When raising such event, you have to pass type parameter of the event, object sender and event arguments.

```
object nullSender = null;
var ev = new ChildrenEventArgs(ContentReference.EmptyReference, new List<IContent>());
_contentEvents.LoadingChildren += Raise.With<ChildrenEventHandler>(nullSender, ev);
```

Writing down same _FakeItEasy's_ _CallTo_ calls in each test method is quite annoying. It is possible to simplify it by extracting the method for such assertion. As I care only if the particular event type is called, my assertion method takes only the type of the event I care about.

```
private void ShouldPublishNotificationWith<T>()
    where T: INotification
{
    A.CallTo(
      () => _mediator.Publish(A<T>.Ignored, A<CancellationToken>.Ignored))
      .MustHaveHappened();
}
```

Now test method looks much simpler and easier to read.

```
public void it_publishes_CheckedInContent_notification_on_CheckedInContent_event()
{
    _contentEvents.CheckedInContent +=
      Raise.With(new ContentEventArgs(ContentReference.EmptyReference));

    ShouldPublishNotificationWith<CheckedInContent>();
}
```

While testing for the raised type of the event is useful, we are not checking for correct values passed into the mediator. We have to compare the passed in event object to the expected one. While we can compare each property of the event, it would be harder to maintain. As events can be immutable, we can think of those as [value objects](https://martinfowler.com/bliki/ValueObject.html). Value objects should be easy to compare. To achieve this, I am using a base class for all events - [ValueObject](https://lostechies.com/jimmybogard/2007/06/25/generic-value-object-equality/) which takes care of comparing the objects.

For example, _LoadingChildren_ event inherits from _ValueObject&lt;LoadingChildren&gt;_. I also added factory method for the event to be easier to create.

```
public class LoadingChildren : ValueObject<LoadingChildren>, INotification
{
    public LoadingChildren(ContentReference contentLink)
    {
        ContentLink = contentLink;
    }

    public ContentReference ContentLink { get; }

    public static LoadingChildren FromChildrenEventArgs(ChildrenEventArgs args)
    {
        return new LoadingChildren(args.ContentLink);
    }
}
```

Now we need another assertion method which allows comparing the value passed into the mediator's _Publish_ method. To be able to compare any value passed into it, I added a predicate argument.

```
private void ShouldPublishNotificationWith<T>(Expression<Func<T, bool>> predicate)
    where T : INotification
{
    A.CallTo(
      () => _mediator.Publish(A<T>.That.Matches(predicate), A<CancellationToken>.Ignored))
      .MustHaveHappened();
}
```

Our _LoadingChilden_ event test looks like this now.

```
public void it_publishes_LoadingChildren_notification_on_LoadingChildren_event()
{
    object nullSender = null;
    var ev = new ChildrenEventArgs(ContentReference.EmptyReference, new List<IContent>());
    var expected = LoadingChildren.FromChildrenEventArgs(ev);

    _contentEvents.LoadingChildren += Raise.With<ChildrenEventHandler>(nullSender, ev);

    ShouldPublishNotificationWith<LoadingChildren>(actual => actual == expected);
}
```

I did not show how _EventMediator_ looked like after each step of the _TDD_ cycle but here is the final version.

```
public class EventsMediator
{
    private readonly IContentEvents _contentEvents;
    private readonly IMediator _mediator;

    public EventsMediator(IContentEvents contentEvents, IMediator mediator)
    {
        if (contentEvents == null) throw new ArgumentNullException(nameof(contentEvents));
        if (mediator == null) throw new ArgumentNullException(nameof(mediator));
        _contentEvents = contentEvents;
        _mediator = mediator;
    }

    public void Initialize()
    {
        _contentEvents.LoadingChildren += OnLoadingChildren;
        _contentEvents.CheckedInContent += OnCheckedInContent;
    }

    private async void OnLoadingChildren(object sender, ChildrenEventArgs e)
    {
        await _mediator.Publish(LoadingChildren.FromChildrenEventArgs(e));
    }

    private async void OnCheckedInContent(object sender, ContentEventArgs e)
    {
        await _mediator.Publish(new CheckedInContent());
    }
}
```

It is still missing a lot of event handling. Also, _CheckedInContent_ event doesn't contain the data but now it is easy to write the tests for the rest events with the current setup.
