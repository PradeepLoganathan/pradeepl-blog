---
title: "Reactive Manifesto"
lastmod: 2018-09-09T15:55:13+10:00
date: 2018-09-09T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - "architecture"
  - "reactive"
  - "cloud native"
  - "12 factor app"
  - "design"
  - "pattern"
categories: 
  - "architecture"
  - "patterns"
summary: "The Reactive Manifesto describes how to design and architect Reactive systems according to your needs.Systems built as Reactive Systems are more Reliable, flexible, loosely coupled, scalable and resilient. This makes them easier to develop and amenable to change. Reactive systems are more tolerant of failure and when failure does occur, they meet it with elegance rather than disaster."
ShowToc: true
TocOpen: true
images:
  - 12-factor-apps.png
cover:
    image: "images/Reactive-manifesto.png"
    alt: "Reactive Manifesto"
    caption: "Reactive Manifesto"
    relative: true
editPost:
  URL: "https://github.com/PradeepLoganathan/pradeepl-blog/tree/master/content"
  Text: "Edit this post on github" # edit text
  appendFilePath: true # to append file path to Edit link
---

## Cloud Native architecture

The design for Cloud native applications needs to factor in the distributed nature of cloud-based services. Cloud native applications face a lot of uncertainty. They need to factor in the usual concerns around network partitioning, network failures, hardware failures, etc but also need to design for quota restrictions, cost, service availability, and other factors. Cloud infrastructure mitigates a lot of these aspects. The [12 factor principles]({{< ref "/blog/12-factor-cloud-native-apps">}}) provide guidance in designing cloud native applications to cater to these design constraints.

Cloud native applications also need to be designed to take advantage of the functionality offered by hyper-scaled infrastructure. Cloud infrastructure can be scaled up, scaled out or scaled down very quickly. This allows the design to react to changes in demand quickly. Reactive architectures are well suited for cloud-based and distributed systems. Systems built using reactive architectural principles are called reactive systems.

## Reactive systems

Reactive systems are distributed systems that are responsive, resilient, elastic, and message driven. Reactive Systems are reliable, flexible, loosely coupled, scalable, and resilient. This makes them easier to develop and easier to change. They are more tolerant of failures and when a failure does occur, they meet it with elegance rather than disaster. They handle requests adequately even when under load or facing failures. They communicate asynchronously and can scale individually.

## Reactive Manifesto

The Reactive Manifesto describes the key tenets of Reactive systems. This manifesto distils the knowledge built across various organizations in building highly reliable and scalable applications. The Reactive Manifesto is currently at v.2.0, which was initially published on September 16, 2014. The manifesto is published at GitHub [here](https://github.com/reactivemanifesto/reactivemanifesto).  


## Tenets of Reactive Manifesto

The Reactive Manifesto identifies four key design characteristics of a reactive system. The key tenets of a reactive system are

* Responsive - Designed to handle requests in a timely manner.
* Elastic - Designed to scale up or down based on demand.
* Resilient - Designed to handle failures gracefully.
* Message Driven - Designed to use asynchronous message based communication.

These tenets help build an application that is responsive, loosely coupled, elastic, message driven and highly resilient to failures.

![Reactive Manifesto](images/Reactive-system-design.png#center)

Let us understand these tenets in further detail.

### Responsive

The system responds in a timely manner if at all possible. Responsiveness is the cornerstone of usability and utility. In a reactive world, not providing a response to users when needed and not providing any response at all are one and the same. Responsiveness means that problems may be detected quickly and dealt with effectively. Responsive systems focus on providing rapid and consistent response times, establishing reliable upper bounds so they deliver a consistent quality of service. This consistency in system responsiveness builds end user confidence and better error handling. 

### Resilient

A resilient system stays responsive in the face of failure. When failures occur, they are contained within each component. This can be achieved by isolating components from each other and ensuring that parts of the system can fail and recover without compromising the system as a whole. Resilience can be achieved by various strategies such as replication, containment, isolation and delegation.

* Replication: Running the same component in more than one place, so that if one fails, another could handle it and the application can function in a normal fashion.
* Containment/isolation: Issues of a particular component are contained and isolated within that component and don't interfere with other components or copies of the same component spun up as part of replication.The [Circuit Breaker pattern]({{< ref "/blog/patterns/circuit-breaker-pattern" >}}) is an example of a design pattern used to implement containment/isolation.
* Delegation: In the case of an issue in a component, control can be transferred to another similar component running in a completely different context.

Resilience means a Reactive system should respond to users even in the event of failures, by recovering itself. This is possible by isolating the failure handling to a different component. Recovery of each component is delegated to another (external) component and high-availability is ensured by replication where necessary. The client of a component is not burdened with handling its failures.

### Elastic

Reactive systems are responsive under varying workload. Reactive Systems can react to changes in the input rate by increasing or decreasing the resources allocated to service these inputs. This implies designs that have no contention points or central bottlenecks, resulting in the ability to shard or replicate components and distribute inputs among them. Reactive Systems support predictive, as well as Reactive, scaling algorithms by providing relevant live performance measures.

The system should be able to shard or replicate components and distribute inputs among them. A system should have the ability to spawn new instances for downstream and upstream services for client service requests as and when needed. There should be an efficient service discovery process to aid elastic scaling.

Elasticity = Scale up/down + Scale out/in  

1\. Scale up: When the load increases, a Reactive system should be able to easily upgrade it with more and more powerful resources (for instance, more CPU Cores) automatically, based on the demand.  
2\. Scale down: When the load decreases, a Reactive system should be able to easily degrade it by removing some resources (for instance, CPU Cores) automatically, based on demand.  
3\. Scale out: When the load increases, a Reactive system should be able to easily extend it by adding some new nodes or servers automatically, based on the demand.  
4\. Scale in: When the load decreases, a Reactive system should be able to easily sink it by removing some nodes or servers automatically, based on the demand.

### Message Driven

Asynchronous message passing is the foundation of reactive systems. From the reactive manifesto
>"Reactive Systems rely on asynchronous message-passing to establish a boundary between components that ensures loose coupling, isolation and location transparency. This boundary also provides the means to delegate failures as messages. Employing explicit message-passing enables load management, elasticity, and flow control by shaping and monitoring the message queues in the system and applying back-pressure when necessary. Location transparent messaging as a means of communication makes it possible for the management of failure to work with the same constructs and semantics across a cluster or within a single host. Non-blocking communication allows recipients to only consume resources while active, leading to less system overhead."

-- <cite>Reactive Manifesto</cite>

The Message-Driven approach gives us the following benefits:

1. Messages are immutable by design .
2. They share nothing and are thread-safe by design.
3. They provide loose coupling between system components.
4. They can work across the network, so they support Location Transparency.
5. They support scalability.
6. They support Resilience because they avoid single-point-of-failure using partitioning and replication techniques.

## Conclusion

The reactive manifesto describes the key concepts of a reactive system and describes how each of these concepts enables building a resilient, elastic and message driven system. Reactive systems are an extensive area comprising many concepts, patterns, programming frameworks etc. The reactive manifesto provides a good grounding to help build further on these core concepts and linking them together.
