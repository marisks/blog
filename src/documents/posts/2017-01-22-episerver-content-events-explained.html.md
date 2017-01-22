---
layout: post
title: "Episerver Content Events Explained"
description: >
  <t render="markdown">
  There are times when you need to be notified about some actions happening in the Episerver and execute the code when it happens. Episerver has built-in events which help to achieve it.
  In this article, I will describe content events which are implemented through IContentEvents interface.
  </t>
category:
tags: [EPiServer]
date: 2017-01-22
visible: true
---

While _IContentEvents_ interface is [documented](http://world.episerver.com/documentation/Class-library/?documentId=cms/9/34FD9C4D) quite well, there are some missing parts which are described in this article. Mainly, I focused on the event arguments passed into the event handler. As an event consumer, I care about those the most.

Unfortunately, there are a lot of inconsistencies with these arguments. Some events pass in different types of arguments. There are also different properties filled with different data leaving some properties with default values and some with event data.

I haven't repeated a description of the events which can be found in the _IContentEvents_ [documentation](http://world.episerver.com/documentation/Class-library/?documentId=cms/9/34FD9C4D) and in the source code (you can see documentation through IntelliSense), just added a short description. When I haven't mentioned some event argument's property, then assume that it has a default value.

# Event arguments

Here is the list of all event argument types used by events in the _IContentEvents_ interface:
- _ContentEventArgs_
- _ContentLanguageEventArgs_
- _CopyContentEventArgs_
- _DeleteContentEventArgs_
- _MoveContentEventArgs_
- _SaveContentEventArgs_
- _ChildrenEventArgs_

# Events

## LoadingChildren, LoadedChildren, and FailedLoadingChildren events

These events are raised on child content loading in the _IContentLoader.GetChildren&lt;T&gt;_ implementations.

### LoadingChildren

Raised: Before loading child content  
Arguments:
- _ChildrenEventArgs_ with:
  - _ContentLink_ - content link passed to _IContentLoader.GetChildren&lt;T&gt;_ but without version
  - _ChildrenItems_ - _null_

### LoadedChildren

Raised: After child content loaded  
Arguments:
- _ChildrenEventArgs_ with:
  - _ContentLink_ - content link passed to _IContentLoader.GetChildren&lt;T&gt;_ but without version
  - _ChildrenItems_ - loaded child content

### FailedLoadingChildren

Raised: On exception during child content loading  
Arguments:
- _ChildrenEventArgs_ with:
  - _ContentLink_ - content link passed to _IContentLoader.GetChildren&lt;T&gt;_ but without version
  - _ChildrenItems_ - can be _null_ or loaded child content which can be loaded only partially

## LoadingContent, LoadedContent, and FailedLoadingContent events

These events are raised on content loading in different methods of _IContentLoader_ implementions.

### LoadingContent

Raised: Before loading content but sometimes after content loaded (for example, in the _GetBySegment_ method).  
Arguments:
- _ContentEventArgs_ with:
  - _ContentLink_ - loading content's content link
  - _TargetLink_ - _null_

### LoadedContent

Raised: After content loaded  
Arguments:
- _ContentEventArgs_ with:
  - _ContentLink_ - loading content's content link
  - _TargetLink_ - _null_
  - _Content_ - loaded content

### FailedLoadingContent

Raised: On exception during content loading or when no content loaded (content is _null_)  
Arguments:
- _ContentEventArgs_ with:
  - _ContentLink_ - loading content's content link
  - _TargetLink_ - _null_
  - _Content_ - _null_

## LoadingDefaultContent and LoadedDefaultContent events

These events are raised on new content item creation in the _IContentRepository.GetDefault&lt;T&gt;_ and _IContentRepository.CreateLanguageBranch&lt;T&gt;_ implementions.

### LoadingDefaultContent

Raised: Before creating new content item  
Arguments:
- _ContentEventArgs_ with:
  - _ContentLink_
    - empty content reference when raised from _IContentRepository.GetDefault&lt;T&gt;_
    - source content's content link without version when raised from _IContentRepository.CreateLanguageBranch&lt;T&gt;_
  - _TargetLink_
    - parent content link when raised from _IContentRepository.GetDefault&lt;T&gt;_
    - default value when raised from _IContentRepository.CreateLanguageBranch&lt;T&gt;_
  - _Content_ - _null_
  - _RequiredAccess_
    - default value when raised from _IContentRepository.GetDefault&lt;T&gt;_
    - _AccessLevel.Edit_ when raised from _IContentRepository.CreateLanguageBranch&lt;T&gt;_

### LoadedDefaultContent

Raised: After new content item created  
Arguments:
- _ContentEventArgs_ with:
  - _ContentLink_
    - empty content reference when raised from _IContentRepository.GetDefault&lt;T&gt;_
    - source content's content link without version when raised from _IContentRepository.CreateLanguageBranch&lt;T&gt;_
  - _TargetLink_
    - parent content link when raised from _IContentRepository.GetDefault&lt;T&gt;_
    - default value when raised from _IContentRepository.CreateLanguageBranch&lt;T&gt;_
  - _Content_ - created content
  - _RequiredAccess_
    - default value when raised from _IContentRepository.GetDefault&lt;T&gt;_
    - _AccessLevel.Edit_ when raised from _IContentRepository.CreateLanguageBranch&lt;T&gt;_

## PublishingContent and PublishedContent events

These events are raised on content publishing in the _IContentRepository_ implementations.

### PublishingContent

Raised: Before content saving and when _Transition.NextStatus_ is _VersionStatus.Published_  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - publishing content's content link
  - _Content_ - publishing content
  - _SaveAction_ - _SaveAction.Schedule_ or _SaveAction.Publish_
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save or publish method

### PublishedContent

Raised: After content saving and when _Transition.NextStatus_ is _VersionStatus.Published_  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - updated publishing content's content link
  - _Content_ - updated publishing content
  - _SaveAction_ - _SaveAction.Schedule_ or _SaveAction.Publish_
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save or publish method

## CheckingInContent and CheckedInContent events

These events are raised on content checking in in the _IContentRepository_ implementations.

### CheckingInContent

Raised: Before content saving and when _Transition.NextStatus_ is _VersionStatus.CheckedIn_ or _VersionStatus.DelayedPublish_  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - checking in content's content link
  - _Content_ - checking in content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

### CheckedInContent

Raised: After content saving and when _Transition.NextStatus_ is _VersionStatus.CheckedIn_ or _VersionStatus.DelayedPublish_  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - updated checking in content's content link
  - _Content_ - updated checking in content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

## RequestingApproval and RequestedApproval events

These events are raised on content requesting approval in the _IContentRepository_ implementations.

### RequestingApproval

Raised: Before content saving and when _Transition.NextStatus_ is _VersionStatus.AwaitingApproval__  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - requesting approval content's content link
  - _Content_ - requesting approval content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

### RequestedApproval

Raised: After content saving and when _Transition.NextStatus_ is _VersionStatus.AwaitingApproval_  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - updated requesting approval content's content link
  - _Content_ - updated requesting approval content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

## RejectingContent and RejectedContent events

These events are raised on content rejecting in the _IContentRepository_ implementations.

### RejectingContent

Raised: Before content saving and when _Transition.NextStatus_ is _VersionStatus.Rejected__  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - rejected content's content link
  - _Content_ - rejected content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

### RejectedContent

Raised: After content saving and when _Transition.NextStatus_ is _VersionStatus.Rejected_  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - updated rejected content's content link
  - _Content_ - updated rejected content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

## CheckingOutContent and CheckedOutContent events

These events are raised on content checking out in the _IContentRepository_ implementations.

### CheckingOutContent

Raised: Before content saving and when _Transition.NextStatus_ is _VersionStatus.CheckedOut__  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - checking out content's content link
  - _Content_ - checking out content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

### CheckedOutContent

Raised: After content saving and when _Transition.NextStatus_ is _VersionStatus.CheckedOut_  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - updated checking out content's content link
  - _Content_ - updated checking out content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

## SchedulingContent and ScheduledContent events

These events are raised on content scheduling in the _IContentRepository_ implementations.

### SchedulingContent

Raised: Before content saving and when _Transition.NextStatus_ is _VersionStatus.DelayedPublish__  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - scheduling content's content link
  - _Content_ - scheduling content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

### ScheduledContent

Raised: After content saving and when _Transition.NextStatus_ is _VersionStatus.DelayedPublish_  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - updated scheduling content's content link
  - _Content_ - updated scheduling content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

## DeletingContent and DeletedContent events

These events are raised on content or content's children deleting in the _IContentRepository_ implementations.

### DeletingContent

Raised: Before content deleting or content's children deleting  
Arguments:
- _DeleteContentEventArgs_ with:
  - _ContentLink_ -
    - content's link without version when raised from _IContentRepository.Delete_
    - content's link when raised from _IContentRepository.DeleteChildren_
  - _TargetLink_ -
    - default value when raised from _IContentRepository.Delete_
    - content's link when raised from _IContentRepository.DeleteChildren_
  - _RequiredAccess_ - access level passed into delete method
  - _DeletedDescendents_ - content's descendant links

### DeletedContent

Raised: After content deleting or content's children deleting  
Arguments:
- _DeleteContentEventArgs_ with:
  - _ContentLink_ -
    - content's link without version when raised from _IContentRepository.Delete_
    - content's link when raised from _IContentRepository.DeleteChildren_
  - _TargetLink_ -
    - default value when raised from _IContentRepository.Delete_
    - content's link when raised from _IContentRepository.DeleteChildren_
  - _RequiredAccess_ - access level passed into delete method
  - _DeletedDescendents_ - content's descendant links
  - _Items["DeletedItemGuids"]_
    - content's Guid and its descendant Guids when raised from _IContentRepository.Delete_
    - content's descendant Guids when raised from _IContentRepository.DeleteChildren_

## CreatingContentLanguage and CreatedContentLanguage events

These events are raised on content new language branch creating in the _IContentRepository_ implementations.

### CreatingContentLanguage

Raised: Before content saving if a new language branch is created  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - created content's content link
  - _Content_ - created content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

### CreatedContentLanguage

Raised: After content saving if a new language branch is created  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - updated created content's content link
  - _Content_ - updated created content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

## DeletingContentLanguage and DeletedContentLanguage events

These events are raised on content language branch deleting in the _IContentRepository_ implementations.

### DeletingContentLanguage

Raised: Before deleting a language branch  
Arguments:
- _ContentLanguageEventArgs_ as _ContentEventArgs_ with:
  - _Content_ - deleted language branch content
  - _ContentLink_ - deleted language branch content's content link
  - _Language_ - deleted language branch language
  - _MasterLanguage_ - deleted language branch master language
  - _RequiredAccess_ - access level passed into delete method

### DeletedContentLanguage

Raised: After deleting a language branch  
Arguments:
- _ContentLanguageEventArgs_ as _ContentEventArgs_ with:
  - _Content_ - deleted language branch content
  - _ContentLink_ - deleted language branch content's content link
  - _Language_ - deleted language branch language
  - _MasterLanguage_ - deleted language branch master language
  - _RequiredAccess_ - access level passed into delete method

## MovingContent and MovedContent events

These events are raised on content moving including moving to wastebasket in the _IContentRepository_ implementations.

### MovingContent

Raised: Before moving content  
Arguments:
- _MoveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - moving content's content link without version
  - _TargetLink_ - destination content's content link
  - _OriginalParent_ - original parent content's content link
  - _Descendents_ - content's descendant content links
  - _Content_ - moving content

### MovedContent

Raised: After moving content  
Arguments:
- _MoveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - moving content's content link without version
  - _TargetLink_ - destination content's content link
  - _OriginalParent_ - original parent content's content link
  - _Descendents_ - content's descendant content links
  - _Content_ - updated moving content

## CreatingContent and CreatedContent events

These events are raised on content saving and copying in the _IContentRepository_ implementations.

### CreatingContent

Raised: Before content saving if a new content is created including during copying  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - created content's content link
  - _Content_ - created content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method
- _CopyContentEventArgs_ as _ContentEventArgs_ on copying with:
  - _ContentLink_ - empty content link
  - _SourceContentLink_ - source content's content link
  - _TargetLink_ - destination content's content link
  - _RequiredAccess_ - access level passed into copy method

### CreatedContent

Raised: After content saving if a new content is created including during copying  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - created content's content link
  - _Content_ - created content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method
- _CopyContentEventArgs_ as _ContentEventArgs_ on copying with:
  - _ContentLink_ - created content's content link
  - _SourceContentLink_ - source content's content link
  - _TargetLink_ - destination content's content link
  - _RequiredAccess_ - access level passed into copy method

## SavingContent and SavedContent events

These events are raised on content saving in the _IContentRepository_ implementations. These events are always raised before one of the other saving events like _PublishingContent_ and _PublishedContent_.

### SavingContent

Raised: Before content saving  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - saved content's content link
  - _Content_ - saved content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

### SavedContent

Raised: After content saving  
Arguments:
- _SaveContentEventArgs_ as _ContentEventArgs_ with:
  - _ContentLink_ - updated saved content's content link
  - _Content_ - updated saved content
  - _SaveAction_ - save action passed into save method
  - _Transition_ - evaluated transition based on content and save action
  - _RequiredAccess_ - access level passed into save method

## DeletingContentVersion and DeletedContentVersion events

These events are raised on content's version deleting in the _IContentVersionRepository_ implementations.

### DeletingContentVersion

Raised: Before deleting content version  
Arguments:
- _ContentEventArgs_ with:
  - _ContentLink_ - deleting content version content's content link
  - _RequiredAccess_ - access level passed into delete method

### DeletedContentVersion

Raised: After deleting content version  
Arguments:
- _ContentEventArgs_ with:
  - _ContentLink_ - deleting content version content's content link
  - _RequiredAccess_ - access level passed into delete method
