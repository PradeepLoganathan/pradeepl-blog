---
title: "Serialize exceptions as JSON using custom middleware in .Net Core"
date: "2018-05-10"
categories: 
  - "api"
---

Creating API's has a certain rigor to it right from the design phase which is different from a UI based Web application. One of the areas where this is very apparent is communicating exceptions to the client. In a web application exception are communicated to the client using the UI with the most common being a 404 page. This page has been elevated to an art form now. The image below is a 404 page on Pixar's website.

![](images/pixar-404.png)

In an API since there is no UI and the client and the API provider work on a contract, exceptions are communicated through the API response in the appropriate media format such as JSON or XML. There are multiple ways of returning exceptions back to the client. I generally prefer to implement a custom exception handling middleware. Implementing a middleware component is simpler and it can be added to the OWIN request/response processing pipeline. It makes the context of the middleware much more explicit by limiting it to handling and communicating exceptions to the client. It is in some ways a cross cutting concern which should be abstracted away from the domain code.

If you are new to the pipeline architecture of .NET core, I would suggest you read [this post](http://pradeeploganathan.com/asp-net/owin-katana-kestrel/) before moving ahead.

A middleware component is a request delegate that processes the request/response and then invokes the next component in the pipeline. The next request delegate is resolved by dependency injection.

A middleware component has three key parts

- A read-only field to hold the reference to the next RequestDelegate.
- A constructor that expects the next RequestDelegate as a parameter.
- An Invoke method that takes an HttpContext object to operate on and then pass it along to the next middleware.

### Creating the Middleware component

I have created a simple exception handling middleware component as below. Note that the invoke method also has the environment injected into it, allowing us to provide more information in case of non-production environments for debugging purposes.

<script src="https://gist.github.com/PradeepLoganathan/08357b35ff18cbbc8437c9794e317c98.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/08357b35ff18cbbc8437c9794e317c98">View this gist on GitHub</a>

### Middleware helper

Now we need to add this component to the pipeline. We can add this component to the pipeline by simply calling the app.UseMiddleware method in the startup class.  This will add it to the pipeline. It is important to add it before calling the app.UseMVC() method so that the middleware gets a crack at handling the exception post the MVC cycle. Conventionally adding a middleware is made even more easier by creating a helper similar to the UserMVC method. Let's create a helper method to add our middleware to the pipeline. We need to add a static helper class with a static method as below.

<script src="https://gist.github.com/PradeepLoganathan/24281bbc548336869f9e4a85f44b8877.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/24281bbc548336869f9e4a85f44b8877">View this gist on GitHub</a>

### Add to startup

We can now use this helper method in the startup class to add our ExceptionHandler component to the middleware pipeline. So in the startup class just call the method as below.

<script src="https://gist.github.com/PradeepLoganathan/9bc63fd2d54856aaf970558138bff85a.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/9bc63fd2d54856aaf970558138bff85a">View this gist on GitHub</a>

Now we are all done. Whenever there is an exception, it will be handled by our custom middleware and transformed into a JSON object which will be returned to the client.

![](images/ErrorAsJson-1024x385.png)

Photo by Pavan Trikutam on Unsplash
