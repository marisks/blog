---
layout: post
title: "UI testing basics in Episerver"
description: >
  <t render="markdown">
  I haven't done UI testing much as I found it quite unreliable, hardly maintainable and hard to write. But there are still some cases when it is useful to have some UI tests.
  </t>
category:
tags: [EPiServer]
date: 2017-03-12
visible: true
---

# UI testing in Episerver

UI tests and tests, in general, should be repeatable and reliable. For this purpose, you have to set the system under test into some known state. For UI tests it is common to restore the database from the backup or the UI test itself should undo all changes it made.

Most of the time the _Episerver_ projects - _CMS_ or _Commerce_, displays the system's internal state to the user. This state can be - pages, products, and other content. But there are not so much data entry functionality which changes the state of the system itself. The system's state is modified by _CMS_ or _Commerce_ editors using _Episerver_ administrative interface or some back-end services. This makes _Episerver_ UI testing much simpler. It is unlikely that your _Episerver_ instance will change so much from one test run to another. So it is fine to have the same database for multiple test runs.

But why, when, and in which environments to test UI?

First of all, I find UI testing useful to make sure that the deployed version of your website is working correctly or at least main functionality works. It could be annoying for you to go through the main pages and test it manually. Automation helps to do it. Also, while developing a new feature when you have to do some steps repeatedly, it is worth to automate it. 

When working on the _Episerver_ project, it is good to have same or similar content in all environments - your development environment, test, staging, and production environments. This makes your UI testing work same everywhere. If so, then run it in all your environments.

# CMS testing

What to test? You should check main pages and main components of your website. But do not go into much detail. Do not rely on particular content, but use navigation instead to browse through your site. You should test the pages of particular page types if you know how to navigate to those. For example, a contact page can be checked by navigating to it by the link in the footer if you know that the link always will be there.

Here is the list of the main stuff to test:
- the start page
- the main navigation and it's sub-navigation if you have such
- header and footer links and pages those links navigate to
- the global search and the search result page

What should you test on those pages? First of all, make sure that you can navigate to the page. Then assert that there are no errors on it. Check if the page contains main components it should have based on the page type. For example, a start page should have a carousel block.

Assert that components persist on the page by testing for a particular CSS class, ID or tag's attribute. If you can't, then test by checking the text element. But text elements can be unreliable as editors might change those.

Next important thing when doing UI testing is an abstraction of the page behavior. You should create a separate test component for navigation, page, block, footer, or header behavior. Such component should abstract away any interaction with your website. It might be hard, but it is worth it for test maintainability. So for example, you can create a navigation test component. It should not expose any HTML/CSS selectors to your tests, but instead, provide methods to navigate to the particular page. It might look like this:

```
Navigation.ToNthMenuItem(main: 1);
Navigation.ToNthMenuItem(main: 1, sub: 2);
Footer.ToContactPage();
Search.For("car");
```

It might not be possible to abstract everything, but at least the main website components should be abstracted to matching test components.

# Commerce testing

_Episerver_ Commerce testing doesn't differ much from the CMS testing. Same rules for test components also applies to the Commerce UI testing.

On the _Commerce_ website you should test:
- the product listing page
- the product search and the search result page
- the product page itself
- the checkout process which includes putting the product in to the cart

When testing a checkout process, tests can have different levels of testing. When testing in development, test or staging environments, payments usually are configured to work with some test payment provider. This allows you to do full checkout testing. But in a production environment, you would test only till the actual payment.

A checkout process also requires filling some forms. Abstracting the form fill might not be the easy task. It is fine to use CSS selectors directly to achieve this.

# Summary

UI testing might be useful. While I described some points, I thought are important, those are not rules but suggestions. You should find your way for better tests. You might find different challenges with UI testing when using different testing frameworks.