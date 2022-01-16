---
title: "Dependency injection in .net core console application"
date: "2020-02-01"
categories: 
  - "dotnet"
tags: 
  - "net"
  - "net-core"
  - "dependencyinjection"
---

In the previous [post](https://pradeeploganathan.com/dotnet/configuration-in-a-net-core-console-application/) we implemented configuration in a .net core console application. In this post let us look at implementing dependency injection in a .net core console application.

An ELI5 explanation of dependency injection is provided in [this historically significant stackoverflow post](https://stackoverflow.com/questions/1638919/how-to-explain-dependency-injection-to-a-5-year-old). DI helps implement a key design pattern called loose coupling. DI enables loose coupling by allowing us to program against an interface(contract), rather than a concrete implementation. This makes code more maintainable and testable.

Dependency injection can be implemented using an off the shelf DI container or by custom coding a Pure DI implementation. A pure DI implementation will need to provide for Object composition, Lifetime management and interception. A pure DI implementation is not a trivial exercise. The time and effort required to create one for a specific solution is not justified.

A DI Container is a software library that provides DI functionality and automates many of the tasks involved in Object Composition, Interception, and Lifetime Management. It’s an engine that resolves and manages object graphs. These DI Containers depend on the static information compiled into all classes. Using reflection, they can analyze the requested class and figure out which Dependencies are needed. Many excellent DI Containers are available for the .NET platform such as Autofac, StructureMap, Ninject, and also the built-in Microsoft.Extensions.DependencyInjection library.This post is not a deep dive into dependency injection , but rather about using a dependency injection framework to implement DI in a .net core console application using the Microsoft dependency injection service The code sample for this post is [here](https://github.com/PradeepLoganathan/Injector).

We start off by creating a console application. To use the Microsoft Dependency injection library, we need to install the Microsoft.Extensions.DependencyInjection nuget library.

<script src="https://gist.github.com/PradeepLoganathan/571807b5a7a4086f62b1e9ff830dc91a.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/571807b5a7a4086f62b1e9ff830dc91a">View this gist on GitHub</a>

The high-level steps involved in implementing Dependency injection using Microsoft's IoC container is below

1. Create a Service Collection.
2. Add services to the service collection.
3. Create a Service Provider.
4. Use the service provider to access services provided in a scope.

We need a service container, and this is provided by the ServiceCollection class. We create an instance of the ServiceCollection class and add services to this class with a specific service lifetime scope as below. Scope lifetime can be singleton, scoped or transient. These require their own blog post for a detailed explanation. I register the Customer type as a concrete implementation of the ICustomer interface using a singleton scope. I also directly register a Type ( ConsoleApplication). By doing this, I am trying to use the program class as a shell which creates the service container and registers the necessary services.

<script src="https://gist.github.com/PradeepLoganathan/b6d9a430ee8218318cc6f2311234d871.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/b6d9a430ee8218318cc6f2311234d871">View this gist on GitHub</a>

Registering an interface and a Concrete type as singletons

The service collection needs to be disposed on exit and that is performed in the DisposeServices method.

<script src="https://gist.github.com/PradeepLoganathan/d901587a375097bcf90b0f1596e48511.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/d901587a375097bcf90b0f1596e48511">View this gist on GitHub</a>

Disposing the Service collection

The programs entry point now calls RegisterServices to register all the necessary services using configuration as code. Once this is done it creates an object lifetime scope using the serviceprovider.CreateScope call. It then calls the GetRequiredService generic method to get the concrete ConsoleApplication type and calls the run method on it. The ConsoleApplication is created by automatically injecting its dependencies through constructor injection. In this case the ConsoleApplication class depends on the ICustomer interface. The dependency injection system intercepts this call and passes in the concrete implementation of ICustomer which was configured in RegisterServices. I have also as part of this design abstracted out the core application from the program template boilerplate.

<script src="https://gist.github.com/PradeepLoganathan/67ec3cef3b0350da03e5045526387d09.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/67ec3cef3b0350da03e5045526387d09">View this gist on GitHub</a>

Using ServiceScope to get a service

<script src="https://gist.github.com/PradeepLoganathan/eb8f668f80bcf74b6d50f85591a8eb7a.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/eb8f668f80bcf74b6d50f85591a8eb7a">View this gist on GitHub</a>

ICustomer being injected by dependency injection

We can also change our code to auto register types using assembly scanning. To implement assembly scanning we can use the .net core reflection api's and LINQ as below.

<script src="https://gist.github.com/PradeepLoganathan/152bd70dbda88390f8a347d285380124.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/152bd70dbda88390f8a347d285380124">View this gist on GitHub</a>

Using Assembly scanning to auto register type assignable from ICustomer

We now have a fully functioning DI system in a .net core console application. we can now design our interfaces and classes and make sure that they are designed to be maintainable and independently testable. We can create mocks and use them in place of the actual implementation etc.

> Photo by [Patrick Fore](https://unsplash.com/@patrickian4?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/s/photos/selection?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
