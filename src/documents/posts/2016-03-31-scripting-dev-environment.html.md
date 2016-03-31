---
layout: post
title: "Scripting development environment"
description: "Recently, I installed and configured my new development computer. Manual application and configuration take a lot of time. In the Linux (Ubuntu) world you can use apt-get to script application installation, but for configuration can backup "dotfiles" on the old machine and restore on the new. Luckily there are some tools which will help you do same on Windows."
category:
tags: [EPiServer,.NET]
date: 2016-03-31
visible: true
---
<p class="lead">
Recently, I installed and configured my new development computer. Manual application and configuration take a lot of time. In the Linux (Ubuntu) world you can use apt-get to script application installation, but for configuration can backup "dotfiles" on the old machine and restore on the new. Luckily there are some tools which will help you do same on Windows.
</p>

# Install applications with Chocolatey

For application installation, you can use [Chocolatey](https://chocolatey.org/). It is a tool like _apt-get_ on _Linux (Ubuntu)_ and has lot of different applications which are used for developers. For example, _Notepad++_, _Atom_, _GitHub for Desktop_ etc.

First, install Chocolatey. I have created separate _Powershell_ script file for it - _installChocolatey.ps1_:

```
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
```

Then I created a _backup.ps1_ script to create a list of applications I already installed. It creates the list as a _Powershell_ script which can be used to restore applications. _backup.ps1_ lists all installed applications, parses the output, creates _Chocolatey_ install command for each application and outputs everything into _restore.ps1_ file:

```
choco list -l -r | foreach { "choco install " + ($_).Split("|")[0] } > restore.ps1
```

Generated _restore.ps1_ for all my applications looks like this:

```
choco install 7zip
choco install 7zip.install
choco install Atom
choco install autohotkey.portable
choco install cdex
choco install chocolatey
choco install ConEmu
choco install DotNet4.5
choco install fiddler
choco install filezilla
choco install github
choco install grepwin
choco install imagemagick
choco install imagemagick.app
choco install irfanview
choco install kdiff3
choco install libreoffice
choco install nodejs
choco install nodejs.install
choco install notepadplusplus
choco install notepadplusplus.install
choco install NuGet.CommandLine
choco install paint.net
choco install pdf24
choco install ReSharper
choco install resharper-platform
choco install sumatrapdf
choco install sumatrapdf.commandline
choco install sumatrapdf.install
choco install synkron
choco install terminals
choco install vcredist2010
choco install vim
choco install vlc
```

Now I can use _restore.ps1_ on my new computer to install all the packages. Note that this script prompts for running scripts for each application to install. If you want to skip it, generate _choco install_ command with "-y" parameter.

# Configure IIS using Powershell and Chocolatey

For [EPiServer](http://world.episerver.com) development, I use full _IIS_ instead of _IIS Express_, but it requires proper configuration. It is hard to remember what settings and what features are required when setting it up. So it is better to use _Powershell_ script for it:

```
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionDynamic
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpTracing
Enable-WindowsOptionalFeature -Online -FeatureName IIS-BasicAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DigestAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ClientCertificateMappingAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-IISCertificateMappingAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45 -All

# requires chocolatey to be installed first
choco install webpi
```

The last command installs _Web Platform Installer (WebPI)_. I need it for one feature - _Url Rewriter_. Unfortunately, _Url Rewriter_ has to be installed manually using _WebPI_. A future version of _Chocolatey_ will be able to install _WebPI_ features too.

# Backup/restore of Git configuration

Another configuration I want to backup is _.gitconfig_. On _Windows_ it is usually stored in _C:\Users\MyUsername_. To backup _.gitconfig_, just use _Copy-Item_ _Powershell_:

```
Copy-Item C:\Users\MyUsername\.gitconfig $PSScriptRoot
```

It will copy _.gitconfig_ into the same folder where the script is located.

Use the same _Copy-Item_ to restore it:

```
Copy-Item $PSScriptRoot\.gitconfig C:\Users\MyUsername
```

Same way it is possible to backup and restore any configuration file.

# Where to store scripts and configuration?

I am using _OneDrive_ to store all my scripts and backed up configuration. It is available in _Windows_ after installation and automatically syncs between all my computers. All scripts are available when _Windows_ installation is done.

# Summary

While a lot of applications can be installed using _Chocolatey_, there are a lot of applications which still are not available. Also, I won't install _Visual Studio_ and _SQL Server_ using _Chocolatey_ unless I could provide my configuration in a script.
