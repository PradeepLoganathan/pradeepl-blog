---
title: "Configuration in a .Net Core Console application"
lastmod: 2019-12-20T15:55:13+10:00
date: 2019-12-20T15:55:13+10:00
draft: false
Author: Pradeep Loganathan

tags:
  - "dotnet"
  - "dotnet core"
  - "configuration"
  - "csharp"
  - "csharp11"

categories:
  - "dotnet"
#slug: kubernetes/introduction-to-kubernetes-admission-controllers/
summary: Adding configuration to a .Net core Console application to read configuration from a json file, or environmental variables or command line arguments.
# description: Adding configuration to a .Net core Console application to read configuration from a json file, or environmental variables or command line arguments.
ShowSummary: true
ShowDescription: true
ShowToc: true
TocOpen: true
images:
  - configuration-in-a-net-core-console-application-cover.png
cover:
  image: "configuration-in-a-net-core-console-application-cover.png"
  alt: "Configuration in a .Net Core Console application"
  caption: "Configuration in a .Net Core Console application"
  relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---

A .NET core console application is an amazing bare bones application template which lets you quickly test out ideas. At the same time, it can also be used to build a production ready application. Since it is a lightweight application template it does not have functionality such as configuration or dependency injection baked in.

As a .NET core console application does not have dependency injection built in, features that an application depends on such as configuration is not readily available. In a full-fledged ASP.net core application, configuration is available using the injected IConfiguration interface by default. In a .NET core console application Configuration can be added using the ConfigurationBuilder class. Additionally, support for configuring the application using a Json file, environmental variables, command line or using a custom configuration provider can also be added.

The ```IConfiguration``` and the ```ConfigurationBuilder``` types are available in the ```Microsoft.Extensions.Configuration``` package. The extensions to add a json file such as appsettings.json as a configuration source is available in the ```Microsoft.Extensions.Configuration.Json``` nuget package. The extensions to add Environmental variables as a configuration source is available in the nuget package ```Microsoft.Extensions.Configuration.EnvironmentVariables```. The extensions to add the command line as a configuration source is available in the ```Microsoft.Extensions.Configuration.CommandLine``` nuget package.

The above NuGet packages can be installed using the install-package command as below.

```shell
dotnet add package Microsoft.Extensions.Configuration
dotnet add package Microsoft.Extensions.Configuration.Json
dotnet add package Microsoft.Extensions.Configuration.CommandLine
dotnet add package Microsoft.Extensions.Configuration.Binder
dotnet add package Microsoft.Extensions.Configuration.EnvironmentVariables 
```

Installing packages for Configuration

Once these packages are installed it provides the necessary functionality to use the ```ConfigurationBuilder``` class. In the below code block I am adding a json configuration file called appsettings.json. I am also adding environmental variables and command line as a configuration source.

```csharp
static async Task Main(string[] args)
{
  
  IConfiguration Configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables()
    .AddCommandLine(args)
    .Build();
}
```

Each configuration source overrides the configuration source in the order in which it is has been added to the configuration builder. It is important to add your configuration sources in the right order based as the precedence is by order. When a configuration source is loaded and a key already exists from a configuration source added earlier, it overwrites the previous value.

Now that we have built our configuration providers, we can use them as below

```csharp
var section = Configuration.GetSection("Sectionofsettings");
var section = Configuration.GetValue("Onesetting");
```

We can The Sections can also be assigned to strongly typed objects representing the configuration using the Bind method.

As an example, if we have the below class representing an imaginary logging configuration

```csharp
class LoggingConfig
{
    public string LogPath {get;set;}
    public LogLevel Level {get;set;}
}
```

Strongly typed configuration class

We can then strongly bind it using Configuration.Bind("LogSettings", LoggingConfig). It can then be injected into the services collection if we have implemented dependency injection using services.AddSingleton(services.AddSingleton(config)); as below

```csharp
 public void ConfigureServices(IServiceCollection services)
 {
    var loggingConfig = new LoggingConfig(); 
    Configuration.Bind("loggingSettings", loggingConfig);  // binding here
    services.AddSingleton(loggingConfig);
 }
 ```

Binding configuration strongly typed to use DI

In the [next post]({{< ref "/blog/dotnet/dependency-injection-in-net-core-console-application" >}}) let us look at implementing Dependency injection in a console application which can also be used to inject configuration.
