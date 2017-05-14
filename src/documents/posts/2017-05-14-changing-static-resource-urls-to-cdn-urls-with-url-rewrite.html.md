---
layout: post
title: "Changing static resource URLs to CDN URLs with URL Rewrite"
description: >
  <t render="markdown">
  Recently I was configuring a CDN in Azure for one of our projects. We needed to serve most of the static content (images and scripts) from the CDN to improve page load times. After the CDN had been set up, I had to change the content URLs to point to the CDN. There are several options to do it. You might handle it directly in the code, rewrite all URLs in some handler or as I did with URL rewrite.
  </t>
category:
tags: [EPiServer]
date: 2017-05-14
visible: true
---

There are several articles available about URL rewrite configuration which rewrites URLs in the response. But I couldn't find a good example how to rewrite relative URLs.

You can configure URL rewrite in the _Web.config_ file under the _rewrite_ section. The primary structure consists of the inbound and outbound rules.

```xml
<rewrite>
    <rules>
        <!-- inbound rules -->
    </rules>
    <outboundRules rewriteBeforeCache="true">
        <!-- outbound rules -->
    </outboundRules>
</rewrite>
```

When you want to modify an HTTP response, you should define the outbound rule for it. It consists of the two parts - what should it match and what action it should perform. In the _match_ tag, you can provide a filter for which HTML tags it should be applied. You should also set the _pattern_ attribute which can contain a regular expression.

```xml
<rule name="TheName" stopProcessing="true">
  <match filterByTags="A" pattern="http://mysite.com/" />
  <action type="Rewrite" value="http://anothersite.com" />
</rule>
```

When I was searching for the outbound rule to rewrite my relative URLs, I found an article [Create your own CDN using IIS Outbound Rules](https://www.saotn.org/create-cdn-using-iis-outbound-rules/). It has an example how to create rules for absolute URLs. It did not help me much as my site has only relative URLs for my static content. But this article was a good starting point. I found the regular expression to match different file extensions.

```
.*\.(jpg|jpeg|png).*
```

Now I started creating my regular expression. After several tries, I understood that matching relative URLs is a quite hard problem. More searching and I got to the [Stack Overflow answer](http://stackoverflow.com/a/31432012/660154) which helped me with relative URL matching.

```
(^(?!www\.|(?:http|ftp)s?:\/\/|[A-Za-z]:\\|\/\/)
```

I could combine these two regular expressions and create the rules for my content. I also added a precondition to rewrite only HTML response.

```xml
<rule name="CDN-01-jpg" preCondition="CheckHTML" stopProcessing="true">
  <match
    filterByTags="Img" 
    pattern="(^(?!www\.|(?:http|ftp)s?:\/\/|[A-Za-z]:\\|\/\/).*\.(jpg|jpeg|png).*)" />
  <action type="Rewrite" value="https://mycdn.azureedge.net{R:1}" />
</rule>
<rule name="CDN-01-js" preCondition="CheckHTML" stopProcessing="true">
  <match
    filterByTags="Script"
    pattern="(^(?!www\.|(?:http|ftp)s?:\/\/|[A-Za-z]:\\|\/\/).*\.(js).*)" />
  <action type="Rewrite" value="https://mycdn.azureedge.net{R:1}" />
</rule>
<preConditions>
  <preCondition name="CheckHTML">
    <add input="{RESPONSE_CONTENT_TYPE}" pattern="^text/html" />
  </preCondition>
</preConditions>
```

I am using CDN only for images and JavaScript. I do not rewrite CSS content as it might contain references to the other resources such as fonts and images but it would break because of [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS).

While this solution is working fine, I had another issue. There are some images on the site which are loaded dynamically. Image tags have a separate attribute - "data-src" which points to the image source but doesn't load the image on the page load. Image loading is done later by the JavaScript. The outbound rule which I created was rewriting only the _img_ tag's "src" attribute and ignored others.

After some searching, I found a [forum thread](https://forums.iis.net/t/1215031.aspx) on how to match and rewrite custom attributes. It helped me to create my own rule for it.

```xml
<rule name="CDN-01-custom-img" preCondition="CheckHTML" stopProcessing="true">
  <match
    filterByTags="None"
    pattern="&lt;img ([^>]*)data-src=&quot;(.*?)&quot;([^>]*)>" />
  <action
    type="Rewrite"
    value="&lt;img {R:1}data-src=&quot;https://mycdn.azureedge.net{R:2}&quot;{R:3}>" />
</rule>
```

This rule matches the whole image and rewrites entire tag including all its attributes.