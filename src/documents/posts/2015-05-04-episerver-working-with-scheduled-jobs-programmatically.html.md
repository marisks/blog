---
layout: post
title: "EPiServer: working with Scheduled Jobs programmatically"
description: "EPiServer provides Scheduled Jobs to run background tasks on schedule. By default those have simple scheduling available, but sometimes you might need more advanced scheduling techniques. EPiServer provides API for that."
category: [EPiServer]
tags: [EPiServer]
date: 2015-05-04
visible: true
---

<p class="lead">
EPiServer provides Scheduled Jobs to run background tasks on schedule. By default those have simple scheduling available, but sometimes you might need more advanced scheduling techniques. EPiServer provides API for that.
</p>

In older versions _EPiServer_ had used _ScheduledJob_ class as [active record](http://en.wikipedia.org/wiki/Active_record_pattern) to manipulate _Scheduled Jobs_, but now all _active record_ methods became obsolete. New way of working with _Scheduled Jobs_ is using _ScheduledJobRepository_. It provides several methods to get and store _Scheduled Jobs_ which might be useful:

* _Get(Guid id):ScheduledJob_ - retrieve _Scheduled Job_ by it's ID,
* _Get(string method, string typeName, string assemblyName):ScheduledJob_ - retrieve _Scheduled Job_ by method name (the name of the method called to when executing it - default name is _Execute_), type name, assembly name,
* _List():IEnumerable<ScheduledJob>_ - retrieve all stored _Scheduled Jobs_,
* _Save(ScheduledJob job):void_ - store _ScheduledJob_.

**NOTE**: When working with _List_ method, I noticed that newly added scheduled jobs might not be returned by it. When job is saved manually through UI then it is returned by _List_ method.

I was missing one method to get existing _Scheduled Job_ by _Type_. Usually there might be only one job with particular type so it is safe to do that. I created extension method with same name as instance methods - _Get_.

    public static class ScheduledJobRepositoryExtensions
    {
        public static ScheduledJob Get(this ScheduledJobRepository repository, Type jobType)
        {
            return repository.List().Single(x => x.TypeName == jobType.FullName);
        }
    }

_ScheduledJob_ class has several properties which might be useful to create custom scheduling logic.
* _IntervalType_ - the type of the interval which might have values:
    - ScheduledIntervalType.Days
    - ScheduledIntervalType.Hours
    - ScheduledIntervalType.Minutes
    - ScheduledIntervalType.Months
    - ScheduledIntervalType.None
    - ScheduledIntervalType.Seconds
    - ScheduledIntervalType.Weeks
    - ScheduledIntervalType.Years
* _IntervalLength_ - the length of the interval in units defined by _IntervalType_
* _IsEnabled_ - property to get or set if job is active

Read-only properties to get job status and if it can be stopped might be useful too.
* _IsStoppable_ - property if job can be stopped
* _IsRunning_ - property if job currently is running

And to take some action there are two methods.
* _Stop()_ - to stop the job if it is stoppable - _IsStoppable_ property is _true_
* _ExecuteManually()_ - to run job programmatically by skipping scheduling (I would better schedule it anyway).

And here are few examples how it can be used. In both examples I am using _Injected_ class to get _ScheduledJobRepository_ instance injected in the property (_Scheduled Jobs_ do not support constructor injection). In first example I am using my extension method to get _Scheduled Job_ by it's type. First example schedules another _Scheduled Job_ to run after 10 seconds and second example schedules itself to run after 10 seconds. In second example I am getting _Scheduled Job_ by it's ID which is instance's property - _ScheduledJobId_.

    [ScheduledPlugIn(DisplayName = "I shedule other job", SortIndex = 1000)]
    public class OtherJobScheduling : JobBase
    {
        public Injected<ScheduledJobRepository> ScheduledJobRepository { get; set; }

        public override string Execute()
        {
            var repository = ScheduledJobRepository.Service;
            var job = repository.Get(typeof(SelfScheduling));
            job.IsEnabled = true;
            job.NextExecution = DateTime.Now.AddSeconds(10);
            repository.Save(job);

            return "Scheduling completed.";
        }
    }

    [ScheduledPlugIn(DisplayName = "I shedule myself", SortIndex = 1010)]
    public class SelfScheduling : JobBase
    {
        public Injected<ScheduledJobRepository> ScheduledJobRepository { get; set; }

        public override string Execute()
        {
            var repository = ScheduledJobRepository.Service;
            var job = repository.Get(ScheduledJobId);
            job.IsEnabled = true;
            job.NextExecution = DateTime.Now.AddSeconds(10);
            repository.Save(job);

            return "Scheduling completed.";
        }
    }

Working with _Scheduled Jobs_ programmatically is simple while not well documented. Hope that this post will be good reference.

Documentation about how to create _Scheduled Jobs_ can be found on [EPiServer World](http://world.episerver.com/documentation/Items/Developers-Guide/EPiServer-CMS/8/Scheduled-jobs/Scheduled-jobs/).