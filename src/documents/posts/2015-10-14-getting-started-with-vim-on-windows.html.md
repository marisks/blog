---
layout: post
title: "Getting started with Vim on Windows"
description: "I am not a new Vim user, but I have never used it as my main editor. I've learned the basic movement and editing commands, which I am using in Vi modes in different editors - Sublime Text's Vi mode, Visual Studio's extension - VsVim, and others. As now Vim can be used as fully featured C# (by Omnisharp) and F# (by vim-fsharp) environment, I want to use Vim as my main development environment. The first step for that is installing and setting up basic configuration."
category: [Vim]
tags: [Vim]
date: 2015-10-14
visible: true
---

<p class="lead">
I am not a new _Vim_ user, but I have never used it as my main editor. I've learned the basic movement and editing commands, which I am using in _Vi_ modes in different editors - _Sublime Text's Vi_ mode, _Visual Studio's_ extension - _VsVim_, and others. As now _Vim_ can be used as fully featured C# (by <a href="http://www.omnisharp.net/">Omnisharp</a>) and F# (by <a href="https://github.com/fsharp/vim-fsharp">vim-fsharp</a>) environment, I want to use _Vim_ as my main development environment. The first step for that is installing and setting up basic configuration.
</p>

# Installing ConEmu

I'd like to use _Vim_ in the terminal and [ConEmu](http://conemu.github.io/) console emulator is a good fit for my needs. As I am [Chocolatey](https://chocolatey.org/) user, installation is easy - just type in command in console:

    choco install conemu

Then configured it to use _Solarized_ theme and start _PowerShell_ by default.

# Installing Vim

Same as with _ConEmu_, install _Vim_ using _Chocolatey_:

    choco install vim

# Basic Vim configuration

Open the terminal (_ConEmu_) and _CD_ into the home folder (usually _C:\Users\YourUserName_). Create _Vim_ configuration file _.vimrc_ here:

    echo $null >> .vimrc

Open _.vimrc_ and add following lines:

    " Enable syntax highlighting
    syntax on

    " Enable auto indentation custom per file type
    filetype plugin indent on

    " Set tabs to 4 space chars
    set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab

    " Set backspace behavior in insert mode
    set backspace=indent,eol,start

    " Disable beeps
    set noerrorbells visualbell t_vb=
    autocmd GUIEnter * set visualbell t_vb=

All settings are described well with comments except auto indentation. As described in [Vim Wiki](http://vim.wikia.com/wiki/Indenting_source_code#File-type_based_indentation) _filetype plugin indent on_ allows to customize indentation per file type and it will use indentation scripts located in the _indent_ folder of _Vim_ installation.

# Install Pathogen plugin manager

_Vim_ has lots of different useful plugins, but managing those manually might be hard. [Pathogen](https://github.com/tpope/vim-pathogen) is a tool which manages _Vim's_ _runtimepath_ so that is easy to locate plugins.

To install _Pathogen_ first create new folder _vimfiles_ and two sub-folders - _autoload_ and _bundle_ in your home directory:

    mkdir vimfiles\autoload
    mkdir vimfiles\bundle

Then download _Pathogen_ into _vimfiles\autoload_ directory:

    curl -OutFile vimfiles\autoload\pathogen.vim https://tpo.pe/pathogen.vim

Now configure _Vim_ to use it. Open _.vimrc_ file and on the top add this line:

    execute pathogen#infect()

# Colors and themes

_ConEmu_ supports terminal with 256 colors and it is possible to configure _Vim_ to use color syntax highlighting in it. There are some issues with different _Vim_ versions and color schemes which is described on [ConEmu page](http://conemu.github.io/en/VimXterm.html).

Before enabling colors in _Vim_, install the theme first. I am using [zenburn](https://github.com/jnurmine/Zenburn) theme.

    git clone https://github.com/jnurmine/Zenburn vimfiles\bundle\zenburn

Now configure _Vim_ to use 265 colors in terminal (as described on [ConEmu page](http://conemu.github.io/en/VimXterm.html#requirements)) and set theme:

    " Set colors in console
    if !has("gui_running")
        set term=xterm
        set t_Co=256
        let &t_AB="\e[48;5;%dm"
        let &t_AF="\e[38;5;%dm"
        colorscheme zenburn
    endif

# Known issues

## Issue with key bindings

After installation and configuration I tried _Vim's_ _:help_ to find out how to start _vimtutor_ - interactive _Vim's_ tutorial. The issue I came up was that I was unable to navigate to required section with keys - _Ctrl+]_. Unfortunately it doesn't work and it seems that _Ctrl_ is ignored - only _]_ gets sent as command. I tried to find solution to enable this key combination, but couldn't find any. Only solution is to remap it to different keys. So I remapped it to use _F3_ key. Add these lines to your _.vimrc_ to remap it:

    " Key mappings
    map <F3> <C-]>

## Issue with colors

Sometimes colors look strange when scrolling, but it is ok to live with that.

# Tips

Copying/pasting in _Vim_ is quite different than in other editors and sometimes you have to copy into _Window's_ clipboard. To do that use copying into the _+_ buffer. Select the text and type command:

    "+y

For novice user this command might look strange, but is quite simple:
- _"_ - means that you are using named buffer,
- _+_ - is the name of the buffer - _+_ in _Windows_ is _Clipboard_,
- _y_ - is copying (yank) command.
