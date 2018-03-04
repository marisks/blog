---
layout: post
title: "EpiEvents library support for approval events"
description: >
  <t render="markdown">
  Last year I created a library [EpiEvents](/2017/06/09/epievents-a-library-for-simpler-episerver-event-handling/) for pub/sub like Episerver event handling. It supported all content related events, but after my package release, Episerver has released content approvals. The content approvals feature also raises events. Now I have added support also for those.
  </t>
category:
tags: [EPiServer]
date: 2018-03-04
visible: true
---

The new version supports _Episerver_ 11.1+. You can install the new version from the [Episerver NuGet Feed](http://nuget.episerver.com/feed/packages.svc/):

```powershell
Install-Package EpiEvents.Core
```

The current version of the package has added support for these events:

- ApprovalStepStarted - an equivalent of IApprovalEngineEvents.StepStarted event
- ApprovalStepApproved - an equivalent of IApprovalEngineEvents.StepApproved event
- ApprovalStepRejected - an equivalent of IApprovalEngineEvents.StepRejected event
- ApprovalStarted - an equivalent of IApprovalEngineEvents.Started event
- ApprovalAborted - an equivalent of IApprovalEngineEvents.Aborted event
- ApprovalApproved - an equivalent of IApprovalEngineEvents.Approved event
- ApprovalRejected - an equivalent of IApprovalEngineEvents.Rejected event

For more information, check [the documentation](https://github.com/marisks/EpiEvents/blob/master/readme.md) and source code on [GitHub](https://github.com/marisks/EpiEvents).