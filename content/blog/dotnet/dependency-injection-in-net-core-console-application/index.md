---
title: "Dependency injection in .Net Core Console application"
lastmod: 2020-02-01T15:55:13+10:00
date: 2020-02-01T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
tags:
  - "net"
  - "net-core"
  - "dependencyinjection"
categories:
  - "dotnet"
#slug: kubernetes/introduction-to-kubernetes-admission-controllers/
summary: Dependency injection enables an application to use a key design principle called Loose coupling. Loose coupling enables us to write highly maintainable
# description: Dependency injection enables an application to use a key design principle called Loose coupling. Loose coupling enables us to write highly maintainable
ShowSummary: true
ShowDescription: true
ShowToc: true
TocOpen: false
ShowPostNavLinks: true
images:
  - scott-trento-xrBxbPiK2w8-unsplash.jpg
cover:
  image: "scott-trento-xrBxbPiK2w8-unsplash.jpg"
  alt: "Dependency injection in .Net Core Console application"
  caption: "Dependency injection in .Net Core Console application"
  relative: false # To use relative path for cover image, used in hugo Page-bundles
editPost:
  URL: "https://github.com/PradeepLoganathan/pradeepl-blog/tree/master/content"
  Text: "Edit this post on github" # edit text
  appendFilePath: true # to append file path to Edit link
---


In the previous [post](https://pradeepl.com/dotnet/configuration-in-a-net-core-console-application/) we implemented configuration in a .net core console application. In this post let us look at implementing dependency injection in a .net core console application.

An ELI5 explanation of dependency injection is provided in [this historically significant stackoverflow post](https://stackoverflow.com/questions/1638919/how-to-explain-dependency-injection-to-a-5-year-old). DI helps implement a key design pattern called loose coupling. DI enables loose coupling by allowing us to program against an interface(contract), rather than a concrete implementation. This makes code more maintainable and testable.

Dependency injection can be implemented using an off the shelf DI container or by custom coding a Pure DI implementation. A pure DI implementation will need to provide for Object composition, Lifetime management and interception. A pure DI implementation is not a trivial exercise. The time and effort required to create one for a specific solution is not justified.

## Dependency Injection Container

A DI Container is a software library that provides DI functionality and automates many of the tasks involved in Object Composition, Interception, and Lifetime Management. It’s an engine that resolves and manages object graphs. These DI Containers depend on the static information compiled into all classes. Using reflection, they can analyze the requested class and figure out which Dependencies are needed. Many excellent DI Containers are available for the .NET platform such as Autofac, StructureMap, Ninject, and also the built-in Microsoft.Extensions.DependencyInjection library.This post is not a deep dive into dependency injection , but rather about using a dependency injection framework to implement DI in a .net core console application using the Microsoft dependency injection service The code sample for this post is [here](https://github.com/PradeepLoganathan/Injector).

We start off by creating a console application. To use the Microsoft Dependency injection library, we need to install the Microsoft.Extensions.DependencyInjection nuget library.

```shell
Install-Package Microsoft.Extensions.DependencyInjection
```

The high-level steps involved in implementing Dependency injection using Microsoft's IoC container is below

1. Create a Service Collection.
2. Add services to the service collection.
3. Create a Service Provider.
4. Use the service provider to access services provided in a scope.

## Service Collection

We need a service container, and this is provided by the ServiceCollection class. We create an instance of the ServiceCollection class and add services to this class with a specific service lifetime scope as below. Scope lifetime can be singleton, scoped or transient. These require their own blog post for a detailed explanation. I register the Customer type as a concrete implementation of the ICustomer interface using a singleton scope. I also directly register a Type ( ConsoleApplication). By doing this, I am trying to use the program class as a shell which creates the service container and registers the necessary services.

```csharp
private static void RegisterServices()
{
  var services = new ServiceCollection();
  services.AddSingleton<ICustomer, Customer>();
  services.AddSingleton<ConsoleApplication>();            
  _serviceProvider = services.BuildServiceProvider(true);
}
```

Registering an interface and a Concrete type as singletons

The service collection needs to be disposed on exit and that is performed in the DisposeServices method.

```csharp

private static void DisposeServices()
{
  if (_serviceProvider == null)
  {
    return;
  }
  if (_serviceProvider is IDisposable)
  {
    ((IDisposable)_serviceProvider).Dispose();
  }
}
```

Disposing the Service collection

## Registering Services

The programs entry point now calls RegisterServices to register all the necessary services using configuration as code. Once this is done it creates an object lifetime scope using the serviceprovider.CreateScope call. It then calls the GetRequiredService generic method to get the concrete ConsoleApplication type and calls the run method on it. The ConsoleApplication is created by automatically injecting its dependencies through constructor injection. In this case the ConsoleApplication class depends on the ICustomer interface. The dependency injection system intercepts this call and passes in the concrete implementation of ICustomer which was configured in RegisterServices. I have also as part of this design abstracted out the core application from the program template boilerplate.

```csharp
static void Main(string[] args)
{
  RegisterServices();
  IServiceScope scope = _serviceProvider.CreateScope();
  scope.ServiceProvider.GetRequiredService<ConsoleApplication>().Run();
  DisposeServices();
}
```

Using ServiceScope to get a service

```csharp

using Injector.Abstractions;
using System;
using System.Collections.Generic;
using System.Text;

namespace Injector
{
    class ConsoleApplication
    {
        private readonly ICustomer _customer;
        public ConsoleApplication(ICustomer customer)
        {
            _customer = customer;
        }

        public void Run()
        {
            _customer.CreateCustomer(); 
        }
    }
}
```

ICustomer being injected by dependency injection

## Auto register types

We can also change our code to auto register types using assembly scanning. To implement assembly scanning we can use the .net core reflection api's and LINQ as below.

```csharp

Assembly ConsoleAppAssembly = typeof(Program).Assembly;

var ConsoleAppTypes =
    from type in ConsoleAppAssembly.GetTypes()
    where !type.IsAbstract
    where typeof(ICustomer).IsAssignableFrom(type)
    select type;

foreach (var type in ConsoleAppTypes)
{
    services.AddTransient(typeof(ICustomer), type);
}
```

Using Assembly scanning to auto register type assignable from ICustomer

We now have a fully functioning DI system in a .net core console application. we can now design our interfaces and classes and make sure that they are designed to be maintainable and independently testable. We can create mocks and use them in place of the actual implementation etc.
