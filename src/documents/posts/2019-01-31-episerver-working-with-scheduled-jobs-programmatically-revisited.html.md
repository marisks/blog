---
layout: post
title: "EPiServer: working with Scheduled Jobs programmatically. Revisited."
description: >
  <t render="markdown">
  A few years ago I wrote an article on how to work with [Episerver scheduled jobs programmatically](/2015/05/04/episerver-working-with-scheduled-jobs-programmatically/). Since then Episerver has improved the API.
  </t>
category:
tags: [EPiServer]
date: 2019-01-31
visible: true
---

In the latest version, you still have a repository. However, instead of using a class, you should ask for an interface - _IScheduledJobRepository_. It still has the same set of methods:

* _Get(Guid id):ScheduledJob_
* _Get(string method, string typeName, string assemblyName):ScheduledJob_
* _List():IEnumerable<ScheduledJob>_
* _Save(ScheduledJob job):void_

[See my previous article for detailed information](/2015/05/04/episerver-working-with-scheduled-jobs-programmatically/).

The main changes in the API are about executing these jobs. _Stop_, _ExecuteManually_ and other methods of a _ScheduledJob_ class now are obsolete. You should use _IScheduledJobExecutor_ instead. _IScheduledJobExecutor_ has three methods:

* _StartAsync(ScheduledJob job, JobExecutionOptions options, CancellationToken cancellationToken):Task<JobExecutionResult>_ - starts a job with provided options and cancellation token,
* _Cancel(Guid id):void_ - cancels a job by Id,
* _ListRunningJobs():IEnumerable_ - - returns a list of running jobs.

_IScheduledJobExecutor_ also has several extension methods. These extension methods make it much easier to work with scheduled jobs:

* _StartAsync(this IScheduledJobExecutor executor, ScheduledJob job):Task<JobExecutionResult>_ - starts a job without any parameters,
* _StartAsync(this IScheduledJobExecutor executor, ScheduledJob job, JobExecutionOptions options):Task<JobExecutionResult>_ - starts a job with options,
* _ListRunningJobs&lt;T&gt;(this IScheduledJobExecutor executor):IEnumerable&lt;T&gt;_ - lists jobs of a specific type.

So with all this in your tool belt, you can load a job by id and start it.

```csharp
public async RunMyJob()
{
    var job = _scheduledJobRepository.Get(new Guid(MyJob.Guid));
    if (job.IsRunning)
    {
        return;
    }

    var result = await _scheduledJobExecutor.StartAsync(job);
    if (result.Status == ScheduledJobExecutionStatus.Succeeded)
    {
        return;
    }

    Log.Error($"Failed to start a job: {result.Status} {result.Message}");
    return;
}

```

You also, can pass some options:

```csharp
await _scheduledJobExecutor.StartAsync(job, new JobExecutionOptions
{
    Trigger = ScheduledJobTrigger.User,
    RunSynchronously = true,
    ContentCacheSlidingExpiration = null
});
```

Here the trigger just indicates how this job was started. It has four values - _Unknown_, _Scheduler_, _User_, _Restart_. So you can fake how it was started :)

_RunSynchronously_ set to _true_ will run the job synchronously.

With _ContentCacheSlidingExpiration_ you can set how long content is cached when executed.