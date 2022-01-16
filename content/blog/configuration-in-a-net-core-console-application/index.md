---
title: "Configuration in a .Net core Console application"
date: "2019-12-20"
categories: 
  - "csharp"
  - "dotnet"
---

A .NET core console application is an amazing bare bones application template which lets you quickly test out ideas. At the same time, it can also be used to build a production ready application. Since it is a lightweight application template it does not have functionality such as configuration or dependency injection baked in.

As a .NET core console application does not have dependency injection built in, features that an application depends on such as configuration is not readily available. In a full-fledged ASP.net core application, configuration is available using the injected IConfiguration interface by default. In a .NET core console application Configuration can be added using the ConfigurationBuilder class. Additionally, support for configuring the application using a Json file, environmental variables, command line or using a custom configuration provider can also be added.

The IConfiguration and the Configuration builder types are available in the Microsoft.Extensions.Configuration package. The extensions to add a json file such as appsettings.json as a configuration source is available in the Microsoft.Extensions.Configuration.Json nuget package. The extensions to add Environmental variables as a configuration source is available in the nuget package Microsoft.Extensions.Configuration.EnvironmentVariables. the extensions to add the command line as a configuration source is available in the Microsoft.Extensions.Configuration.CommandLine nuget package.

The above NuGet packages can be installed using the install-package command as below.

<script src="https://gist.github.com/PradeepLoganathan/0427bb05b1ca7444bc00c7bed3c2b305.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/0427bb05b1ca7444bc00c7bed3c2b305">View this gist on GitHub</a>

Installing packages for Configuration

Once these packages are installed it provides the necessary functionality to use the ConfigurationBuilder class. In the below gist I am adding a json configuration file called appsettings.json. I am also adding environmental variables and command line as a configuration source.

<script src="https://gist.github.com/PradeepLoganathan/53a82c0f676099c77a9c34708e12b5fc.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/53a82c0f676099c77a9c34708e12b5fc">View this gist on GitHub</a>

Adding configuration sources and building the ConfigurationBuilder

Now that we have built our configuration providers, we can use them as below

<script src="https://gist.github.com/PradeepLoganathan/7cc16d8b1555d96c454429f61420d575.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/7cc16d8b1555d96c454429f61420d575">View this gist on GitHub</a>

Getting configuration sections and values

Each configuration source overrides the configuration source in the order in which it is has been added to the configuration builder. The Sections can also be assigned to strongly typed objects representing the configuration using the Bind method.

As an example, if we have the below class representing an imaginary logging configuration

<script src="https://gist.github.com/PradeepLoganathan/f2b650511dad038f437716bfff07b649.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/f2b650511dad038f437716bfff07b649">View this gist on GitHub</a>

Strongly typed configuration class

We can then strongly bind it using Configuration.Bind("LogSettings", LoggingConfig). It can then be injected into the services collection if we have implemented dependency injection using services.AddSingleton(services.AddSingleton(config)); as below

<script src="https://gist.github.com/PradeepLoganathan/1a7e316449a319a4d7621007db70e530.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/1a7e316449a319a4d7621007db70e530">View this gist on GitHub</a>

Binding configuration strongly typed to use DI

[In the next post](https://pradeeploganathan.com/dotnet/dependency-injection-in-net-core-console-application/) let us look at implementing Dependency injection in a console application which can also be used to inject configuration.
