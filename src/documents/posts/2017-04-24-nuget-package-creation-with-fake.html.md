---
layout: post
title: "NuGet package creation with FAKE"
description: >
  <t render="markdown">
  Recently, I was creating a library package for Episerver and required to create a NuGet package. Usually, at Geta we have a Team City configuration for project builds and NuGet package creation. But this time I was creating my package. While it is possible just to package your project with nuget.exe directly, it would need too many manual steps when releasing a new version of your package. In this article, I will show how to use [FAKE](http://fsharp.github.io/FAKE/) for this purpose.
  </t>
category:
tags: [EPiServer, F#, FAKE]
date: 2017-04-24
visible: true
---

# Initial setup

First of all, you have to install a _FAKE_ package. I found that it is much easier when you have a separate project for it. I have created a new _F#_ library project and called it _Build_. Then installed the _FAKE_ package.

```
Install-Package FAKE
```

Then create an initial build script. Call it _build.fsx_.

```fsharp
#r @"../../packages/FAKE.4.58.6/tools/FakeLib.dll"

open Fake

Target "Default" DoNothing

RunTargetOrDefault "Default"
```

On the first line, I am referencing a _FAKE_ library. Reference to the library should be relative to the build script. After _FAKE_ update you might need to change the path. But there are other options to install, reference and update _FAKE_ which would not need it. You can check [Octokit.NET](https://github.com/octokit/octokit.net) project for example.

Then, "open" the _FAKE_ namespace. "open" is a similar keyword to the "using" in _C#_.

With _Target_ you are defining steps and actions which should be run. In this case, I defined a _Default_ target which does nothing. After that, I run it by default on the script run.

Now, you have to create a batch file to simplify a build script execution.

```batch
@echo off
cls

"..\..\packages\FAKE.4.58.6\tools\Fake.exe" build.fsx
pause
```

I am just calling the _Fake.exe_ with the script file name as a parameter.

# Assembly info file patching

Now you have a base. Next step I would like to perform is building the project with the correct assembly version. _FAKE_ has a special [task for it](http://fsharp.github.io/FAKE/assemblyinfo.html).

```fsharp
#r @"../../packages/FAKE.4.58.6/tools/FakeLib.dll"

open Fake

let company = "Maris Krivtezs"
let projectName = "CoolProject"
let projectDescription = "A cool project."
let copyright = "Copyright © Maris Krivtezs 2017"
let assemblyVersion = "1.0.0"

let solutionPath = "../../CoolProject.sln"
let assemblyInfoPath = "../CoolProject/Properties/AssemblyInfo.cs"

MSBuildDefaults <- {
    MSBuildDefaults with
        ToolsVersion = Some "14.0"
        Verbosity = Some MSBuildVerbosity.Minimal }

open Fake.AssemblyInfoFile

Target "AssemblyInfo" (fun _ ->
    CreateCSharpAssemblyInfo assemblyInfoPath
      [ Attribute.Product projectName
        Attribute.Version assemblyVersion
        Attribute.FileVersion assemblyVersion
        Attribute.ComVisible false
        Attribute.Copyright copyright
        Attribute.Company company
        Attribute.Description projectDescription
        Attribute.Title projectName]
)

let buildMode = getBuildParamOrDefault "buildMode" "Release"

let setParams defaults = {
    defaults with
        ToolsVersion = Some("14.0")
        Targets = ["Build"]
        Properties =
            [
                "Configuration", buildMode
            ]
    }

Target "BuildApp" (fun _ ->
    build setParams solutionPath
        |> DoNothing
)

Target "Default" DoNothing

"AssemblyInfo"
  ==> "BuildApp"

RunTargetOrDefault "Default"
```

First of all, you have to define properties for an assembly info - author, project name, etc. Then you need to define several paths - a solution file location and an assembly info file location.

After that, define _MSBuild_ default settings. 

Next step, is an assembly info file patching. Reference a _Fake.AssemblyInfoFile_ namespace and create a target for an assembly info patching. Then, set all the required properties for the assembly info with _CreateCSharpAssemblyInfo_ function.

Now it is time to build our solution. At first, create a function which will override default build parameters and set build mode. The _getBuildParamOrDefault_ function will return a build mode from the script parameters or will use a default value. Create a build target and run the build.

The last step is defining dependencies. You can define dependencies by splitting target names with an _arrow_ - _===>_. In this example, our "AssemblyInfo" target will run before "BuildApp" target.

In the batch file add the parameter to run "BuildApp" target and execute the batch file. Now your application should be patched and built.

```batch
@echo off
cls

"..\..\packages\FAKE.4.58.6\tools\Fake.exe" build.fsx "BuildApp"
pause
```

# Creating NuGet package

The first step, when creating a NuGet package is a creation of the _nuspec_ file. It is a little bit different than we are used to. _FAKE_ has [different syntax](http://fsharp.github.io/FAKE/create-nuget-package.html) for the _placeholders_ than _NuGet_.

```xml
<?xml version="1.0" encoding="utf-8"?>
<package xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <metadata xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
    <id>@project@</id>
    <version>@build.number@</version>
    <authors>@authors@</authors>
    <owners>@authors@</owners>
    <summary>@summary@</summary>
    <licenseUrl>https://github.com/marisks/CoolProject/LICENSE</licenseUrl>
    <projectUrl>https://github.com/marisks/CoolProject</projectUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <description>@description@</description>
    <releaseNotes>@releaseNotes@</releaseNotes>
    <copyright>Copyright Maris Krivtezs 2017</copyright>
    <tags>Episerver</tags>
    @dependencies@
    @references@
  </metadata>
</package>
```

In this _nuspec_ file, I skipped the _@files@_ placeholder because I want to include files automatically.

Now you can add the target for the package creation.

```fsharp

let company = "Maris Krivtezs"
let authors = [company]
let projectName = "CoolProject"
let projectDescription = "A cool project."
let projectSummary = projectDescription
let releaseNotes = "Initial release"
let copyright = "Copyright © Maris Krivtezs 2017"
let assemblyVersion = "1.0.0"

let solutionPath = "../../CoolProject.sln"
let buildDir = "../CoolProject/bin"
let packagesDir = "../../packages/"
let packagingRoot = "../../packaging/"
let packagingDir = packagingRoot @@ "core"
let assemblyInfoPath = "../CoolProject/Properties/AssemblyInfo.cs"

let PackageDependency packageName =
    packageName, GetPackageVersion packagesDir packageName 

// ...

Target "CreateCorePackage" (fun _ ->
    let net45Dir = packagingDir @@ "lib/net45/"

    CleanDirs [net45Dir]

    CopyFile net45Dir (buildDir @@ "Release/CoolProject.dll")
    CopyFile net45Dir (buildDir @@ "Release/CoolProject.pdb")

    NuGet (fun p ->
        {p with 
            Authors = authors
            Project = projectName
            Description = projectDescription
            OutputPath = packagingRoot
            Summary = projectSummary
            WorkingDir = packagingDir
            Version = assemblyVersion
            ReleaseNotes = releaseNotes
            Publish = false
            Dependencies =
                [
                PackageDependency "EPiServer.CMS.Core"
                ]
            }) "core.nuspec"
)
```

You will need additional properties and paths for the target. Here I need a new folder for the packaging result. I specified it in the _packagingDir_ variable.

When running the target, you should clean the target folder first, then copy the files needed for the package and then create the package itself.

In the _NuGet_ function, specify all the properties required for the package and set dependencies. Here I am using a helper function to define a package dependency. It looks for a package with a package version from your packages folder.

The final script will look like this:

```fsharp
#r @"../../packages/FAKE.4.58.6/tools/FakeLib.dll"

open Fake

let company = "Maris Krivtezs"
let authors = [company]
let projectName = "CoolProject"
let projectDescription = "A cool project."
let projectSummary = projectDescription
let releaseNotes = "Initial release"
let copyright = "Copyright © Maris Krivtezs 2017"
let assemblyVersion = "1.0.0"

let solutionPath = "../../CoolProject.sln"
let buildDir = "../CoolProject/bin"
let packagesDir = "../../packages/"
let packagingRoot = "../../packaging/"
let packagingDir = packagingRoot @@ "core"
let assemblyInfoPath = "../CoolProject/Properties/AssemblyInfo.cs"

let PackageDependency packageName =
    packageName, GetPackageVersion packagesDir packageName 

MSBuildDefaults <- {
    MSBuildDefaults with
        ToolsVersion = Some "14.0"
        Verbosity = Some MSBuildVerbosity.Minimal }

Target "Clean" (fun _ ->
    CleanDirs [buildDir; packagingRoot; packagingDir]
)

open Fake.AssemblyInfoFile

Target "AssemblyInfo" (fun _ ->
    CreateCSharpAssemblyInfo assemblyInfoPath
      [ Attribute.Product projectName
        Attribute.Version assemblyVersion
        Attribute.FileVersion assemblyVersion
        Attribute.ComVisible false
        Attribute.Copyright copyright
        Attribute.Company company
        Attribute.Description projectDescription
        Attribute.Title projectName]
)

let buildMode = getBuildParamOrDefault "buildMode" "Release"

let setParams defaults = {
    defaults with
        ToolsVersion = Some("14.0")
        Targets = ["Build"]
        Properties =
            [
                "Configuration", buildMode
            ]
    }

Target "BuildApp" (fun _ ->
    build setParams solutionPath
        |> DoNothing
)

Target "CreateCorePackage" (fun _ ->
    let net45Dir = packagingDir @@ "lib/net45/"

    CleanDirs [net45Dir]

    CopyFile net45Dir (buildDir @@ "Release/CoolProject.dll")
    CopyFile net45Dir (buildDir @@ "Release/CoolProject.pdb")

    NuGet (fun p ->
        {p with 
            Authors = authors
            Project = projectName
            Description = projectDescription
            OutputPath = packagingRoot
            Summary = projectSummary
            WorkingDir = packagingDir
            Version = assemblyVersion
            ReleaseNotes = releaseNotes
            Publish = false
            Dependencies =
                [
                PackageDependency "EPiServer.CMS.Core"
                ]
            }) "core.nuspec"
)

Target "Default" DoNothing

Target "CreatePackages" DoNothing

"Clean"
   ==> "AssemblyInfo"
   ==> "BuildApp"

"BuildApp"
   ==> "CreateCorePackage"
   ==> "CreatePackages"

RunTargetOrDefault "Default"
```

In the final script, I also added "Clean" target which will wipe out all the previous build files. I also defined additional target dependencies.

The batch file for the package creation will look like this:

```batch
@echo off
cls

"..\..\packages\FAKE.4.58.6\tools\Fake.exe" build.fsx "CreatePackages"
pause

```