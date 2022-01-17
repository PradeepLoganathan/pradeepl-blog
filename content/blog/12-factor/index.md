---
title: "12 Factor Apps"
lastmod: 2018-09-09T15:55:13+10:00
date: 2018-09-09T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - "architecture"
  - "cloud"
categories: 
  - "architecture"
  - "cloud"
#slug: kubernetes/introduction-to-kubernetes-admission-controllers/
summary: A group of people within Heroku developed the 12 Factors in 2012. This is essentially a manifesto describing the rules and guidelines that needed to be followed to build a microservices based cloud-native application.
ShowToc: true
TocOpen: false
images:
  - wim-van-t-einde-752333-unsplash.jpg
cover:
    image: "wim-van-t-einde-752333-unsplash.jpg"
    alt: "12 Factor Appications"
    caption: "12 Factor Applications"
    relative: true
editPost:
  URL: "https://github.com/PradeepLoganathan/pradeepl-blog/tree/master/content"
  Text: "Edit this post on github" # edit text
  appendFilePath: true # to append file path to Edit link
---

## Overview

A group of people within Heroku developed the 12 Factors in 2012. This is essentially a manifesto describing the rules and guidelines that needed to be followed to build a microservices based cloud-native application. The manifesto is currently hosted [here](https://12factor.net/). This methodology presents a thought process on how to develop applications and is complimentary to other methodologies and thought processes such as the [reactive manifesto](https://pradeeploganathan.com/patterns/reactive-manifesto/).

The 12 factors are

1. Codebase - One codebase tracked in revision control, many deploys.
2. Dependencies - Explicitly declare and isolate dependencies.
3. Configuration - Store configuration in the environment.
4. Backing Services - Treat backing services as attached resources.
5. Build, release, run - Strictly separate build and run stages.
6. Processes - Execute the app as one or more stateless processes.
7. Port binding - Export services via port binding.
8. Concurrency - Scale out via the process model.
9. Disposability - Maximize robustness with fast startup and graceful shutdown.
10. Dev/prod parity - Keep development, staging, and production as similar as possible.
11. Logs - Treat logs as event streams
12. Admin processes - Run admin/management tasks as one-off processes

### Codebase

> "_A twelve-factor app is always tracked in a version control system… A codebase is any single repo (in a centralized revision control system like Subversion), or any set of repos who share a root commit (in a decentralized revision control system like Git)._"

One codebase tracked in revision control, many deploys. There can only be one codebase per application. The codebase must be managed by a version control system. Various deploys are generated from this codebase, each one for a different environment—development, staging, and production. This looks too simplistic and non nonsensical but if you think about it in the world of SOA and microservices we have to think through our version control strategies. Each service should be maintained as its own codebase and should be version controlled independently.

However there is no one size fits all with codebase strategies and teams move from Mono repo to Multi repos based on various factors. Mono Repo is where all Microservices are housed within a single repository. In multi repo each microservice codebase is tracked in its own independent repo.

### Dependencies

> _“A twelve-factor app never relies on implicit existence of system-wide packages.”_

Dependencies used by a project and their versions must be explicitly declared and isolated from code. Explicitly stating versions results in lower compatibility issues across environments. This also results in better reproducibility of issues occurring in specific version combinations. Dependencies not only include packages but also platforms, SDK's etc. Package dependencies can be manged using package management tools like Nuget, NPM etc. Container technology simplifies this further by explicitly specifying all installation steps. It also specifies versions of base images , so that image builds are idempotent.

### Application configuration

> _“Apps sometimes store config as constants in the code. This is a violation of twelve-factor, which requires strict separation of config from code. Config varies substantially across deploys, code does not.”_

Application configuration, that differ across environments such as external dependencies, databases, credentials, ports etc are manifested at runtime. This configuration should not be hard coded in the source code but dynamically modifiable from outside of the application. The use of environment variables that can be injected when deploying an application in a specific environment is recommended.

### Backing Services

> _“The code for a twelve-factor app makes no distinction between local and third-party services…Each distinct backing service is a resource.”_

Databases, API's and other external systems that are accessed from the application are called resources. The application should be abstracted away from its external resources. These resources should be attached to the application in a loosely coupled manner. They should be replaceable by different instances without any impact to the application. Backing services should be abstracted into individual components with clean interfaces.

### Build, Release, Run

> _“The twelve-factor app uses strict separation between the build, release, and run stages.”_

A single codebase is taken through the build process to produce a compiled artifact. The output of the build stage is combined with environment specific configuration information to produce another immutable artifact, a release. Each release is labelled uniquely. This immutable release is then delivered to an environment (development, staging , production, etc.) and run. If there are issues this gives us the ability to audit a specific release and roll back to a previously working release.

### Processes

> _“Twelve-factor processes are stateless and share-nothing.”_

All processes and components of the application must be stateless and share-nothing. An application can create and consume transient state while handling a request or processing a transaction, but that state should all be gone once the client has been given a response. All long-lasting state must be external to the application and provided by backing services. Processes come and go, scale horizontally and vertically, and are highly disposable. This means that anything shared among processes could also vanish, potentially causing a cascading failure.

### Port Binding

> _“The twelve-factor app is completely self-contained and does not rely on runtime injection of a webserver into the execution environment to create a web-facing service.”_

A twelve-factor app is fully self-contained and does not depend on the use of an external server, such as IIS or NGNIX, to be exported as a service.It is self-contained and is never injected into any kind of external application server or container. A twelve-factor app must export the HTTP service by port-binding, meaning that the application also interfaces with the world via a URL. The application might run as http://localhost:5001 on a developer’s workstation, and in QA it might run as http://164.132.1.10:5000, and in production as http://service.company.com. An application developed with exported port binding in mind supports this environment-specific port binding without having to change any code.

### Concurrency

> _“In the twelve-factor app, processes are a first class citizen…The process model truly shines when it comes time to scale out.”_

Applications should scale out using the process model. Elastic scalability can be achieved by scaling out horizontally. Rules can be setup to dynamically scale the number of instances of the application/service based on load or other runtime telemetry. Stateless, share-nothing processes are well positioned to take full advantage of horizontal scaling and running multiple, concurrent instances.

### Disposability

> _“The twelve-factor app’s processes are disposable, meaning they can be started or stopped at a moment’s notice.”_

Processes are constantly created and killed on demand. An application’s processes are disposable, and can be started or stopped rapidly. An application cannot scale, deploy, release, or recover rapidly if it cannot start rapidly and shut down gracefully. Shutting down gracefully implies saving the state if necessary, and releasing the allocated computing resources.

### Dev/Prod Parity

> _“The twelve-factor app is designed for continuous deployment by keeping the gap between development and production small.”_

All environments should be maintained to be as similar as possible.

### Logs

> " _A twelve-factor app never concerns itself with routing or storage of its output stream.”_

Logs should be treated as event streams.Logs are a sequence of events emitted from an application in time-ordered sequence. A cloud-native application writes all of its log entries to stdout and stderr.You can use tools like the ELK stack (ElasticSearch, Logstash, and Kibana), Splunk etc to capture and analyze your log emissions. Applications should be decoupled from the knowledge of log storage, processing, and analysis. Logs can be directed anywhere. For example, they could be directed to a database in NoSQL, to another service, to a file in a repository, to a log-indexing-and-analysis system, or to a data-warehousing system.

### Admin Processes

> _“Run admin/management tasks as one-off processes.”_

Maintenance tasks, such as script execution for data migration, initial data seeding and cache warming should be automated and performed on time.
