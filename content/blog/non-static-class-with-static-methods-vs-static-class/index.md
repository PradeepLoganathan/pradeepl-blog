---
title: "Non Static class with Static methods Vs Static class"
date: "2017-10-25"
categories: 
  - "architecture"
tags: 
  - "code"
---

During a design session a few folks in my team had questions on using a static class vs a class with static methods.  We hit upon this when designing utility classes and extension methods.During the course of this discussion some of us were surprised about what I felt was basic knowledge and I was also caught out on a few which led me to documenting this down below.

### Static Class

- Marking a class as static means that a compile time check will be conducted to ensure that all members of the class are static.
- Since the CLR does not have a notion of static, marking a class as static translates it to an abstract sealed class. ( conversly you cannot mark a static class as abstract)
- Static classes always inhert from Object and you cannot have it derive from another class.
- You cannot inherit from a static class.
- Static classes cannot implement an interface.
- You cannot obviously instantiate a static class.
- It cannot have constructors and the compiler also does not create a default parameterless constructor.
- Defining extensions in C# requires us to implement the static extension methods in a static class.
- There is a minor performance gain to using static methods as documented in [this code analysis performance tip.](https://docs.microsoft.com/en-in/visualstudio/code-quality/ca1822-mark-members-as-static)
- The performance gain is due to the fact that instance methods always use the this instance pointer as the first parameter which is a small overhead.
- Instance methods also implement the callvirt instruction in IL which also leads to a very small overhead.

### Non Static Class

- A non-static class can have static members. ( both methods and fields ).
- You can create an instance of a Non static class with static methods.
- Factory pattern is an example of a Non Static class implementing a static method to control object instatiation.

Microsoft docs has an article on this topic [here](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/static-classes-and-static-class-members).
