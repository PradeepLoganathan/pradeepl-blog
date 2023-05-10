---
title: "REST architectural constraints"
lastmod: 2016-10-19T11:00:08+10:00
date: 2016-10-19T11:00:08+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - "api"
  - "rest"
  - "design"
categories: 
  - "api"
  - "rest"
summary: REST defines six architectural constraints which make any web service – a truly RESTful API. These are also called as Fielding's constraints. They generalize the Web’s architectural principles and represent them as a framework of constraints or an architectural style.
ShowToc: true
TocOpen: true
series: ["REST"]
images:
  - "images/REST-architectural-constraints.png"
cover:
    image: "images/REST-architectural-constraints.png"
    alt: "REST constraints"
    caption: "REST constraints"
    relative: true # To use relative path for cover image, used in hugo Page-bundles
editPost:
  URL: "https://github.com/PradeepLoganathan/pradeepl-blog/tree/master/content"
  Text: "Edit this post on github" # edit text
  appendFilePath: true # to append file path to Edit link
---

REST as defined in [Roy T Fielding's thesis](http://www.ics.uci.edu/~fielding/pubs/dissertation/top.htm) defines **_six architectural constraints_** which make any web service – a truly RESTful API. These are also called as Fielding's constraints. They generalize the Web’s architectural principles and represent them as a framework of constraints or an architectural style. The REST constraints are

1. Client–server architecture.
2. Stateless.
3. Cacheable.
4. Uniform interface.
5. Layered system.
6. Code on demand.

Implementing the above constraints has several advantages. It allows the service to use standard internet infrastructure elements such as caches, proxies and load balancers. This allows service developers to focus on core service logic rather than reinvent the wheel implementing custom caching services or security layers.

## Client- Server Architecture

This constraint species that the client and server must be able to evolve independently. They must have no dependency of any sort on each other. The only information needed is for the client to know the resource URIs on the server. This encourages separation of concerns between the client and the server allowing them to evolve independently.

## Stateless

A REST service must be stateless. Each request must have all the information needed for the server to process it and the server should not need any additional information from previous requests to fulfill the current request .This shifts the responsibility of maintaining state to the client freeing the server to focus on fulfilling as many requests as possible. The necessary state to operate the request is contained within the request as a part of the URI, query-string parameters, body, or headers. The URI identifies the resource, and the body contains the state of it. A stateless service is easily scalable since additional servers can be added or removed as necessary without having to worry about routing subsequent requests to the same server. These can be further load balanced as necessary.

## Cacheable

A REST service must explicitly indicate cacheblilty of responses. The service should also indicate the duration for which the response is valid. Caching helps improve performance on the client side and scalability on the server side. If the client has access to a valid cached response for a given request, it avoids repeating the same request. Instead, it uses its cached copy. This helps alleviate some of the server’s work, and thus contributes to scalability and performance.

## Uniform Interface

The uniform interface defines a contract for communication between the client and the server. This is achieved through four sub constraints namely

### Identification of resources

As discussed in [What is REST?]({{< ref "/blog/rest/what-is-rest">}}) resources are uniquely identified by URI's. These identifiers are stable and do not change across interactions even when the resource state changes.

### Manipulation of resources through representations

A client manipulates resources by sending new representations of the resource to the service. The server controls the resource representation and can accept or reject the  new resource representation sent by the client.

### Self-descriptive messages

REST request and response messages contain all information needed for the service and the client to interpret the message and handle it appropriately. The messages are quite verbose and include the method, protocol used and the content type. This enables each message to be independent.

### Hypermedia as the Engine of Application State (HATEOS)

Hypermedia connects resources to each other and describes their capabilities in machine-readable ways. Hypermedia is a strategy, implemented in different ways by dozens of technologies. Hypermedia is a way for the server to tell the client what HTTP requests the client might want to make in the future.

## Layered System

A layered system further builds on the concept of client-server architecture. A layered system indicates that there can be more components than just the client and the server and each system can have additional layers in it. These layers should be easy to add, remove or change. Proxies, gateways, load balancer's are also additional layers.

## Code on Demand

Code on Demand is an optional constraint. Code on Demand allows flexibility to the client by allowing it to download code. Servers are able to temporarily extend or customize the functionality of a client by transferring logic to it that it can execute. This enables transferring additional logic to the client to be executed. This is primarily accomplished using JavaScript and other web technologies.

The above constraints describe what a truly RESTful API should look like.
