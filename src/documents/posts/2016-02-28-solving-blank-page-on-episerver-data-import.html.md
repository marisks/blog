---
layout: post
title: "Solving blank page on EPiServer data import"
description: "Recently I had to import data from one EPiServer site to another but got blank page immediately after clicking Begin Import button."
category:
tags: [EPiServer]
date: 2016-02-28
visible: true
---
<p class="lead">
Recently I had to import data from one EPiServer site to another but got blank page immediately after clicking Begin Import button.
</p>

<img src="/img/2016-02/episerver-import-data-blank-page.png" alt="Blank page on EPiServer data import" class="img-responsive">

Few months before, I successfully did import from the same site. Exported data were around 30 MB in size and import went successfully. But now I just got a blank page. First I thought that it was due to upgraded target site to latest _EPiServer_ version (9.6) while source site's version was 8. I upgraded also source site to the same version but still got this weird data import behavior.

Then I started to dig deeper. First checked request with _Chrome's_ developer tools. It was strange that response from the server was with status code 400.

<img src="/img/2016-02/episerver-import-data-404-response.png" alt="404 response on EPiServer data import" class="img-responsive">

Used _Fiddler_ to check if request sent to the server looks suspicious. But it did not. Tried to debug _EPiServer_ data import page using _Reflector_, but I couldn't make it hit the breakpoint in the code. It seemed that request was handled somewhere in IIS.

After some googling, I found forum post by [Fredrik Stolpe](http://world.episerver.com/System/Users-and-profiles/Community-Profile-Card/?userid=eec93f11-21aa-db11-8952-0018717a8c82): [404 Not Found error during import](http://world.episerver.com/forum/developer-forum/-EPiServer-75-CMS/Thread-Container/2015/2/404-not-found-error-during-import/). Finally, solution was found.

Basically, IIS by default has a limit on the content length of 28.6 MB which can be changed by configuration element [requestLimit](https://www.iis.net/configreference/system.webserver/security/requestfiltering/requestlimits). When the content length is too large, IIS sends a response with status 404 and logs it with sub-status - 404.13. My latest exported site data were 48 MB in size, so it failed to import.

So I configured IIS to handle my files also with larger sizes. Here is the configuration which allows content length to be 100 MB:

```
<security>
  <requestFiltering>
    <requestLimits maxAllowedContentLength="104857600" />
  </requestFiltering>
</security>
```
