---
layout: post
title: "Episerver: starting a Scheduled Job programmatically"
description: >
  <t render="markdown">
  In January I wrote an [article](/2019/01/31/episerver-working-with-scheduled-jobs-programmatically-revisited/) about new APIs Episerver has created for working with Scheduled Jobs. Unfortunately, the feature starting the job doesn't work reliably. At least it doesn't work when you start a job from another job.
  </t>
category:
tags: [EPiServer]
date: 2019-04-23
visible: true
---

While _Episerver's_ async methods for starting a scheduled job do not work well, there is a workaround. You can schedule the job to run later. Then the scheduler will pick up the job and start it.

Here I have created an extension method to schedule the job to run after ten seconds.

```csharp
public static class ScheduledJobExtensions
{
    public static void ScheduleRunNow(
      this ScheduledJob job, IScheduledJobRepository scheduledJobRepository)
    {
        job.IntervalType = ScheduledIntervalType.None;
        job.IntervalLength = 0;
        job.IsEnabled = true;
        job.NextExecution = DateTime.Now.AddSeconds(10);

        scheduledJobRepository.Save(job);
    }
}
```

You can use this extension method like this:

```csharp
var job = _scheduledJobRepository.Get(new Guid(MyJob.Guid));
job.ScheduleRunNow(_scheduledJobRepository);
```