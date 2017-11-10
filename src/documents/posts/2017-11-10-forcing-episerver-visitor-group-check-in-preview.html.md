---
layout: post
title: "Forcing Episerver visitor group check in a preview"
description: >
  <t render="markdown">
  Jacob Khan has written an article how to [preview content in a View Mode](https://world.episerver.com/blogs/Jacob-Khan/Dates/2016/4/preview-content-in-view-mode/). While this works fine, it ignores visitor groups.
  </t>
category:
tags: [EPiServer]
date: 2017-11-10
visible: true
---

By default, _Episerver_ ignores visitor groups in a preview mode, but it allows an editor to force particular visitor group under _Toggle view settings_ -> _View as this visitor_:

<img src="/img/2017-10/visitor-group-selection.png" class="img-responsive" alt="Visitor group selection">

This works fine in the CMS administrative UI. There are use cases where a preview link should be sent to users who do not have access to the administrative interface.

Luckily, there is a solution. Khanh Pham from Episerver has sent me an example how to achieve it with MVC filter. _Episerver_ switches visitor groups by URL parameter - _visitorgroupsByID_. So one solution would be to send the link with this parameter if you know for which visitor groups to show the content.

```text
http://mysite.localtest.me/5_123?visitorgroupsByID=5b0f49b9-7793-42a6-bfbe-4fc
```

But it will not work if you want visitor groups to be detected as on the published page. Below is a modified Khanh's example which allows to achieve it.

```csharp
public class ForceVisitorGroupCheckFilter : ActionFilterAttribute
{
    private readonly PreviewContext _previewContext;
    private readonly IVisitorGroupRoleRepository _visitorGroupRoleRepository;
    private readonly IVisitorGroupRepository _visitorGroupRepository;

    public ForceVisitorGroupCheckFilter(
        IVisitorGroupRepository visitorGroupRepository,
        IVisitorGroupRoleRepository visitorGroupRoleRepository,
        PreviewContext previewContext)
    {
        _previewContext = previewContext
            ?? throw new ArgumentNullException(nameof(previewContext));
        _visitorGroupRoleRepository = visitorGroupRoleRepository
            ?? throw new ArgumentNullException(nameof(visitorGroupRoleRepository));
        _visitorGroupRepository = visitorGroupRepository
            ?? throw new ArgumentNullException(nameof(visitorGroupRepository));
    }

    public override void OnActionExecuting(ActionExecutingContext filterContext)
    {
        if (!_previewContext.IsPreview)
        {
            base.OnActionExecuting(filterContext);
            return;
        }

        var visitorGroupKeyByID = "visitorgroupsByID";
        var httpContext = filterContext.HttpContext;
        var contextMode = RequestSegmentContext.CurrentContextMode;

        if (httpContext.Request.QueryString[visitorGroupKeyByID] == null
            && contextMode.EditOrPreview())
        {
            var visitorGroupIds =
                GetVisitorGroupIdsByCurrentUser(filterContext.HttpContext);

            UpdateQueryString(
                httpContext,
                visitorGroupKeyByID,
                string.Join("|", visitorGroupIds.ToArray()));
        }

        base.OnActionExecuting(filterContext);
    }

    private List<string> GetVisitorGroupIdsByCurrentUser(HttpContextBase httpContext)
    {
        var visitorGroupId = new List<string>();
        var user = httpContext.User;
        var visitorGroups = _visitorGroupRepository.List();
        foreach (var visitorGroup in visitorGroups)
        {
            if (_visitorGroupRoleRepository
                    .TryGetRole(visitorGroup.Name, out var virtualRoleObject))
            {
                if (virtualRoleObject.IsMatch(user, httpContext))
                {
                    visitorGroupId.Add(visitorGroup.Id.ToString());
                }
            }
        }

        return visitorGroupId;
    }

    private void UpdateQueryString(HttpContextBase context, string queryString, string value)
    {
        var isReadOnly = typeof(System.Collections.Specialized.NameValueCollection)
            .GetProperty("IsReadOnly", BindingFlags.Instance | BindingFlags.NonPublic);
        if (isReadOnly == null) return;
        isReadOnly.SetValue(context.Request.QueryString, false, null);
        context.Request.QueryString.Set(queryString, value);
        isReadOnly.SetValue(context.Request.QueryString, true, null);
    }
}
```

In this example, _PreviewContext_ is my custom class which detects if a user is in a preview. I am just adding a cookie when the preview is initialized and then check if it is set.

This MVC filter looks for all visitor groups and checks if those match the current user. If so, then adds visitor group to the current request's query string. The magic happens in the _UpdateQueryString_ method. It disables read-only state for the query string property and replaces its value. Now, _Episerver_ "sees" _visitorgroupsByID_ parameter as it would be added to the URL.

When the filter is created, I am setting it in the MVC's global filters.

And thanks Khanh for help with this issue! :)