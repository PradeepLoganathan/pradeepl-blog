---
title: "Functions as a Service on Kubernetes"
author: "Pradeep Loganathan"
date: 2022-05-18T13:40:06+10:00

draft: true
comments: true
toc: true
showToc: true

description: ""

cover:
    image: "cover.png"
    relative: true

images:


tags:
  - "post"
---

 "Serverless on kubernetes .. Say what !!! ??"

That must be your first reaction when we talk about serverless on Kubernetes. Kubernetes is a platform to run containers and manage containerized applications. Serverless is an execution model which allows developers to focus on their application logic rather than the underlying infrastructure. Developers can deploy their code into an execution environment without having to think about the underlying infrastructure on which the application is deployed. In this model, the serverless platform automatically scales up or down based on demand. Serverless platforms on kubernetes similarly focus on allowing developers to focus on application logic rather than think about the complexities of container management and managing the underlying infrastructure.
A few platforms have emerged recently that bring serverless features to containers by abstracting away the complexities of managing containers and any underlying infrastructure.
The term serverless is a misnomer, because there are servers involved. In reality, there is no serverless, just someone else’s container. The Cloud Native Computing Foundation’s Serverless Working Group best summarizes this in a whitepaper:

"Serverless computing does not mean that we no longer use servers to host and run code; nor does it mean that operations engineers are no longer required. Rather, it refers to the idea that consumers of serverless computing no longer need to spend time and resources on server provisioning, maintenance, updates, scaling, and capacity planning. Instead, all of these tasks and capabilities are handled by a serverless platform and are completely abstracted away from the developers and IT/operations teams. As a result, developers focus on writing their applications’ business logic."
 Knative enables serverless on Kubernetes. Knative allows you to create serverless environments using containers, supporting event-driven scale-to-zero applications. It provides a higher level of abstraction for common app use cases.

 The term serverless is a misnomer, because there are servers involved. In reality, there is no serverless, just someone else’s container. The Cloud Native Computing Foundation’s Serverless Working Group best summarizes this in a whitepaper:

"Serverless computing does not mean that we no longer use servers to host and run code; nor does it mean that operations engineers are no longer required. Rather, it refers to the idea that consumers of serverless computing no longer need to spend time and resources on server provisioning, maintenance, updates, scaling, and capacity planning. Instead, all of these tasks and capabilities are handled by a serverless platform and are completely abstracted away from the developers and IT/operations teams. As a result, developers focus on writing their applications’ business logic."

<https://learning.oreilly.com/library/view/learning-serverless/9781492057000/introduction01.html#idm45596691660952>

![Robin serverless](/images/tuServerless_Robin.png)