---
title: "Rest - Idempotency and Safety"
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
summary: Implementing the REST architectural principles results in the both Idempotency and safety being incorporated into the system. This is not however not completely automatic and needs to be thought through in detail. 
# description: Implementing the REST architectural principles results in the both Idempotency and safety being incorporated into the system. This is not however not completely automatic and needs to be thought through in detail. 
ShowToc: true
TocOpen: true
series: ["REST"]
images:
  - "images/rest-idempotency-safety.png"
cover:
    image: "images/rest-idempotency-safety.png"
    alt: "Rest - Idempotency and Safety"
    caption: "Rest - Idempotency and Safety"
    relative: true
 
---

Implementing HTTP’s uniform interface as discussed in the previous [posts]({{< ref "/blog/rest/rest-communicating-with-verbs-and-status-codes">}}) has a surprisingly good architectural side effect. If it is Implemented as specified in the REST specifications (HTTP specification - RFC 2616), you get two useful properties namely Idempotence and Safety.

# Safety

Safety is the ability to invoke an operation without any side effects arising out of the client invoking that operation. It means that the client can invoke an operation with the explicit knowledge that it is not going to change the state of the resource on the server.  In other words, a safe method is one that is read-only and does not alter any data or state of the resource it is acting upon. However, it does not mean that the server should return the same response every time. The server can also perform additional actions when these methods are invoked such as logging calls or incrementing counters etc. but these should not change the state of the resource being acted upon. Generally, read only methods are safe methods. GET, HEAD and OPTIONS are safe methods.
Safe methods can be called without the risk of causing unintended changes or side effects on server data. This predictability is crucial for developers and systems interacting with the API. Safe methods like GET are typically more cache-friendly because they do not involve data changes. Caching GET requests can significantly improve the performance and scalability of a web service by reducing the need to repeatedly fetch the same data from the server. Knowing that a method is safe allows clients and users to interact with a service without the fear of inadvertently modifying or deleting data. For example, applications can prefetch data from endpoints using GET requests without the risk of triggering any unwanted actions.

# Idempotence

Idempotence means that the effect of doing something multiple times will be the same as the effect of doing it only once. A simple example from Math would be the effect of multiplying any number by One. In math the number 1 is an idempotent of multiplication. e.g. 5 x 1 = 5 which is the same as 5 x 1 x 1 = 5. Similarly, an API operation that sets a user's name is a typically idempotent operation. Whether it is called once or multiple times, the effect of the operation is that the user's name will be set to the target value. Deleting a resource is an example of this distinction; the first time you invoke the delete, the object is deleted. The second time you attempt to delete it, there is no change in the state of the system, but the object remains deleted as requested. An idempotent operation generates no side effects.

Idempotency results in improved reliability, concurrency, prevents data loss and provides the ability to automatically retry /recover from failures. It improves reliability by providing the ability to safely retry requests that may or may not have been processed. This helps tide over network glitches and load spikes by replaying requests. Load balancers like HAProxy can retry requests when the server disconnects abruptly providing automatic recovery from failures. Since API calls are idempotent multiple API calls can be run concurrently without locks and mutexes to synchronize operations on data. This increases concurrency and system throughput resulting in better performance.

Safety and Idempotency let a client make reliable HTTP requests over an unreliable network. If you make a GET request and never get a response, just make another one. It’s safe even if your earlier request was fulfilled since it didn’t have any real effect on the state of the resource server. If you make a PUT request and never get a response, just make another one. If your earlier request got through, your second request will have no additional effect since PUT is idempotent and the operation can be repeated.

# HTTP methods - Idempotency & Safety

The following table lists shows you which HTTP method is safe, and which is idempotent

| HTTP Method | Safe| Idempotent |
| :---       | :---: | :---:   |
|  GET        | Yes |  Yes       |
|  POST       | No  |  No        |
|  PUT        | No  |  Yes       |
|  DELETE     | No  |  Yes       |
|  HEAD       | Yes |  Yes       |
|  OPTIONS    | Yes |  Yes       |

GET, HEAD, OPTIONS, PUT and DELETE requests are idempotent. If you DELETE a resource, it’s gone. If you DELETE it again, it’s still gone. The response codes in the above two requests can differ to indicate that the resource representation being deleted is gone. Two simultaneous Delete requests may result in the first request getting a 200 (OK) and the second request getting a 204 (NO CONTENT).If you create a new resource with PUT, and then resend the PUT request, the resource is still there and it has the same properties you gave it when you created it. Making an absolute update to a resource’s state or deleting it outright has the same outcome whether the operation is attempted once or many times. Again, a PUT request can have differing return codes based on the validation done. It can be a 200 (OK) for a successful PUT or a 409 (Conflict) for a PUT where the server resource state is different from the one referenced by the client. A GET or HEAD request should be safe: a client that makes a GET or HEAD request is not requesting any changes to server state. Making any number of GET requests to a certain URI should have the same practical effect as making no requests at all. The safe methods, GET and HEAD, are automatically idempotent as well. POST is neither safe nor idempotent. Making two identical POST requests will result in two subordinate resources containing the same information.

# Practical insights & Best practices

Here are some practical insights and best practices for integrating these concepts into your API design based on my previous experience :

## Idempotency

- Use PUT for Updates: Prefer PUT over POST for updating resources, as PUT is idempotent. This ensures that if a PUT request is repeated due to network issues or other failures, it will not have unintended side effects.

- Implement Idempotent POST where Appropriate: Although POST is generally not idempotent, you can design certain POST operations to be idempotent. For instance, when creating a resource, you can check if it already exists and avoid creating duplicates.

- Design PATCH Carefully: If using PATCH for partial updates, ensure that its implementation is idempotent. This can be achieved by applying changes in a manner that, if repeated, results in the same resource state.

- Use Nonces or Tokens: For operations that can't be naturally idempotent (like payment transactions), use tokens or nonces to ensure that repeated submissions don't cause unintended effects.

- Idempotency Keys: Provide a way for clients to specify an idempotency key in requests. This key helps the server recognize repeat submissions and avoid duplicate processing.

## Safety

- Respect HTTP Method Semantics: Adhere strictly to the intended use of HTTP methods. Use GET for fetching data without side effects, PUT and PATCH for updates, POST for creating new resources, and DELETE for removals.

- Avoid Side Effects with GET Requests: Never change the state of your resources or have any other side effects with GET requests. This maintains the safety property and ensures compatibility with web caches and browsers.

- Use HEAD for Safe Checks: Implement the HEAD method to allow clients to retrieve headers (like ETag or Last-Modified) without fetching the entire resource, which is a safe operation.

- Cache Control: Leverage caching for GET requests. Properly set cache headers to improve performance and reduce unnecessary load on your server.

Developing API's requires us to adhere to the REST semantics which specifies the safety and idempotency requirements for the various verbs as shown in the table above. API consumers will and should expect GET to be safe and idempotent. Similarly, API consumers will incorporate logic to manage additional factors since POST is neither safe nor idempotent. In RESTful API design, understanding and correctly implementing safety and idempotency is crucial to ensure a robust and reliable service, especially in systems where network reliability is a concern or operations might be retried.
