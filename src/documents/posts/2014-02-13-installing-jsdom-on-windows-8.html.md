---
layout: post
title: "Installing JSDOM on Windows 8"
description: "I was starting to build JavaScript module which manipulates XML DOM. For testing purposes I needed some module which creates browser like document object model and the best module I found was JSDOM. Unfortunately installing it might be tricky."
category: 
tags: [node,npm,javascript]
date: 2014-02-13
---

<p class="lead">
I was starting to build JavaScript module which manipulates XML DOM. For testing purposes I needed some module which creates browser like document object model and the best module I found was JSDOM. Unfortunately installing it might be tricky.
</p>

I found article how to install it on [Windows 7](http://www.steveworkman.com/node-js/2012/installing-jsdom-on-windows/) and several Stack Overflow questions. But even following these instructions I couldn't get it working on my Windows 8.1 machine.

The reason for failure is that JSDOM has dependency on [contextify](https://github.com/brianmcd/contextify) module and this is Node's C module. To install it you have to build it with C/C++ compiler and cross-platform tool - [node-gyp](https://github.com/TooTallNate/node-gyp) provides compilation service. But node-gyp still needs compiler to run and on Windows it is Visual Studio C++. On Windows 7 there are two choices - Visual Studio 2010 and Visual Studio 2012 C++ compiler, but on Windows 8 it works only with Visual Studio 2012 C++ and you **must not have Visual Studio 2010 installed (any version, even Shell)**.

So prerequisites for JSDOM (and any other C module) on Windows 8 are:
- Node.js - >= 0.8.0
- NPM
- Python - >= 2.7.3 and < 3.0.0
- Visual Studio 2012 C++ ([Windows Desktop](http://go.microsoft.com/?linkid=9816758) also can be used)
- **Visual Studio 2010 must not have been installed**

