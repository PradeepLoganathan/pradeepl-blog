---
title: "Richardson's Maturity Model"
date: "2016-10-21"
categories: 
  - "rest"

series: ["REST"]
---

The Richardson Maturity Model was developed by [Leonard Richardson](https://web.archive.org/web/20180822201706/http://www.crummy.com/). It specifies a model to grade REST services according to their adherence to the REST constraints. This model identifies three levels of service maturity based on the service’s support for URI’s, HTTP and Hypermedia.

**Level Zero Services** – Level zero services are characterized by services having only one URI and using a single request type mainly POST. The message contains both the operation to be performed and the data needed for that operation. At this level services do not have the concept of representations or resources that are uniquely identifiable. They also do not use the HTTP verbs and status codes for providing rich interaction between the client and the server. For e.g. Most of the WS-\* based web services are level zero since they only use the POST request to transmit the SOAP based message body. This is also called as swamp of POX (plain old XML) model. HTTP constructs are not used to communicate between the client and the server.

**Level One Services** – A level one service has many URI’s but uses a single HTTP verb. Level one services expose multiple resources through unique URI’s. However, operations on these resources are performed by a using a single HTTP verb primarily POST. For e.g. URI tunneling is only at level one in Richardson’s maturity model

**Level Two Services** – Level two services host representations and resources at uniquely identifiable URI’s and use the gamut of HTTP verbs for communicating between the client and the server. The URI specifies the resource being operated on and the operation is performed using the standard HTTP verbs GET, POST, PUT, DELETE etc. It also uses the standard HTTP status codes for responses and adheres to the Idempotency and safety principles of the HTTP verbs.

**Level Three Services** – Level three services implement the concept of Hypermedia as the engine of application state (HATEOAS). Representations hosted at unique URI’s contain URI links to other representations that may be of interest to the client or indicate a choice of actions that can be performed by the client. These choices of actions lead the client through the application resources causing state transitions to occur based on the action chosen by the client.

Services that are at Level three are truly RESTful and adhere to the REST principles as defined by Roy Fielding in his thesis.
