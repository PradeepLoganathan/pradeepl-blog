---
title: "Creating a service in Angular 5 with RxJS 5.5"
date: "2018-02-16"
categories: 
  - "angular"
---

In the world of Microservices, the prevalence of REST API's has made client-side developers depend on them for even the smallest of applications. If you want to develop a Weather app, you better know how to connect to one of the Weather API's. If you want to develop a stock ticker you better know how to connect to a stock ticker API.  
In the world of Angular 5 connecting to API's requires developers to understand RxJs, Observables in particular. The new @common/http module provides all the functionality required to connect to an API. we can further make it reactive using observables and the corresponding operators from the Rxjs Libraries. A simple Angular service generally allows us to perform common HTTP actions ( Get, Post, Put, Delete ) and some uncommonly used actions such as Head and  Patch. I generally follow the below pattern when I create an angular service.

### Creating the Service

Before we start we need to import the HTTPClientModule from @angular/common/http into the AppModule so that it is available across the application. We can now import the HttpClient class into each of the services that we write. and have it injected through constructor injection ( see line 13 below ).  The below code is a contrived example of an angular service which allows components to operate on a product resource exposed by the products URI.

<script src="https://gist.github.com/PradeepLoganathan/eb43351f6bf69a6baee3e8bc2cbfc57f.js"></script>

In the above sample, I am using the RxJS 5.5 lettable or pipeable operators. In this version of RxJs all operators are available as pure functions under rxjs/operators. Lettable operators need to be imported explicitly from rxjs/operators and tree shaking is used to ensure that only the operators that are used are bundled. This reduces the size of the modules.We can compose observables using the pipe method which accepts any number of lettable operators as shown above.

### Handling Errors

When a component subscribes to the service , we also need to ensure that any errors that may be thown are handled gracefully. By default when a component subscribes to an observable, it also has an error callback which is called whenever an error occurs. This callback is called with the HTTPErrorResponse object which provides all the internal guts of the HTTP failure including the status code, status text , url and other information. Ideally these are implementation details and should stay within the boundary of the service.

The catchError RxJS operator enables us to gracefully handle errors. We can add this to the pipe operator when ever we call any http method and specify a callback function. In the call back function, I am creating a custom error object called ProductServiceError. Now that i am catching and returning a custom error object, I also need to change the return type of all methods to be an observable of the union type IProduct | ProductServiceError.

<script src="https://gist.github.com/PradeepLoganathan/6dbd4e4bad1391e6a6e961a333702d28.js"></script>

### Subscribing to the Service

The above code creates a service which exposes an observable of type IProduct . It allows us to get, create, update and delete a product resource hosted at a REST endpoint. It uses the standard HTTP verbs get, post, put and Delete to achive the above functionality. However the service on its own does nothing. To see any action we need to subscribe to the observable exosed by the service. Generally this observable will be subscribed to by a component which visually manages the products resource exposed by this service. Another contrived sample code of a component managing this is below.

<script src="https://gist.github.com/PradeepLoganathan/169d637d2cae8f1da6fc1231e02da648.js"></script>

In the above code we create a component which implements the onInit and the onDestroy lifecycle hooks. We use the angular dependency injection system to provide us with an instance of the Subscription service through constructor injection in line 22. We then use this service to subscribe to the Objservable returned by the service in line 39. The subscribe method subscribes to the stream of observables coming in from the service and allows us to tap into the data returned by calling the service. We also hold onto the observable returned by the call to subscribe as we need to unsubscribe to release resources once we are done with using the service. We use the onDestroy lifecycle hook to unsubscribe from the observable stream in line 33.

We now have a service which returns a stream of observables of type ISubscription. We also have a component which can subscribe to this stream of observables by calling subscribe and release it when done by calling unsubscribe.  One thing to note is that this service does not do any local state management or caching and calls the remote REST resource for all calls. Further , the GET, POST and PUT calls return the resource as per the REST standards and the Delete verb returns only the necessary status code based on the status of the delete operation.We can further optimize the service by providing state management and caching but this is for another blog post :-)

Photo by Gerrie van der Walt on Unsplash
