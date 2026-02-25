---
title: "Building Resilient Microservices with Akka — Part 4: From Code to Cloud"
lastmod: 2026-02-18T16:00:00+10:00
date: 2026-02-18T16:00:00+10:00
draft: true
Author: Pradeep Loganathan
tags:
  - akka
  - microservices
  - deployment
  - distributed-systems
  - resilience
  - devops
categories:
  - akka
  - architecture
description: "Taking event-sourced Akka services from local development to production — the deployment workflow, service discovery in action, automatic scaling, and the operational simplicity that event sourcing enables."
summary: "Deploy event-sourced Akka services to production with a single command, zero-config service discovery, automatic scaling, and the deployment ergonomics that make event-sourced microservices operationally simple."
ShowToc: true
TocOpen: true
images:
  - "images/cover.png"
cover:
  image: "images/cover.png"
  alt: "Deploying Akka microservices from code to cloud"
  caption: "From local development to production with zero configuration changes"
  relative: true
series: ["Building Resilient Microservices with Akka"]
weight: 5
---

{{< series-toc >}}

In [Part 1]({{< ref "/blog/akka/event-sourcing-cqrs-with-akka" >}}), we built event-sourced entities. In [Part 2]({{< ref "/blog/akka/views-cqrs-read-write-optimization" >}}), we separated reads from writes with CQRS views. In [Part 3]({{< ref "/blog/akka/cross-service-communication-agentic-ai" >}}), we wired services together with `HttpClientProvider` and added AI-powered analysis. Everything worked locally with `mvn compile exec:java`.

But local development is the easy part. The real test of a microservices architecture is deployment: can these services run reliably in production, discover each other without configuration, scale independently, and survive failures?

In this post, we deploy to the Akka Platform and discover that the abstractions we built translate directly to production — same code, zero configuration changes, one-command deployment.

![System Architecture](images/architecture.png)

## The Deployment Workflow

Akka SDK services are packaged as Docker images. The Maven build, configured through the `akka-javasdk-parent` POM, handles image creation automatically:

```bash
cd backend/statement-service
mvn clean install -DskipTests
```

This produces a tagged Docker image like `statement-service:1.0.0-SNAPSHOT-20260218051930`. The timestamp suffix ensures every build is uniquely identifiable — critical for rollback scenarios.

Deployment to the Akka Platform is a single command:

```bash
akka service deploy statement-service \
    statement-service:1.0.0-SNAPSHOT-20260218051930 --push
```

The `--push` flag uploads the image to Akka's container registry and deploys it in one step. The platform provisions the runtime, configures the event journal, and starts the service.

Compare this to a traditional Kubernetes deployment of the same service. You would write a Deployment manifest, a Service manifest, a ConfigMap for application configuration, an Ingress resource for external access, and a PersistentVolumeClaim for the event journal. You would configure liveness and readiness probes, set resource limits, manage secrets for database credentials, and set up a service mesh for inter-service TLS. Each of these is a YAML file that must be correct, consistent across environments, and maintained as the application evolves. The Akka Platform replaces all of this with a single command and a naming convention.

Within a minute, the service is running:

```bash
akka services list

NAME                     STATUS   REPLICAS
statement-service        Ready    3
product-service          Ready    3
analysis-service         Ready    3
recommendation-service   Ready    3
```

Each service runs with 3 replicas by default. The Akka runtime distributes entity instances across replicas — entity `stmt-2025-12` might live on replica 1, while `stmt-2026-01` lives on replica 2. The `ComponentClient` and `HttpClientProvider` route requests to the correct replica transparently.

The Akka Platform console provides a visual overview of the deployed services, their status, replica count, and region:

![Akka Platform — Project services dashboard showing all services running with 3 replicas in gcp-us-east1](images/akka-platform-services-dashboard.png)

### Exposing Services

By default, deployed services are only accessible to other services in the same project. To expose a service to external callers:

```bash
akka service expose analysis-service --enable-cors
```

This generates a public hostname:

```
The service 'analysis-service' was successfully exposed at:
white-bush-8904.gcp-us-east1.akka.services
```

The `--enable-cors` flag configures CORS headers, essential when browser-based clients call the API directly.

> **Production note:** `--enable-cors` allows all origins. In production, restrict the `Access-Control-Allow-Origin` header to your specific frontend domains (e.g., `https://app.yourbank.com`) to prevent unauthorized cross-origin requests.

### Seeding Data

The statement-service and product-service require seed data. Our endpoint design anticipated this:

```bash
curl -X POST https://<statement-host>/accounts/seed
curl -X POST https://<product-host>/products/seed
```

These endpoints are idempotent by design (recall the `if (currentState() != null) return effects().reply(done())` pattern from Part 1). You can call them multiple times safely — the second call finds existing entities and returns success without emitting duplicate events.

## Service Discovery in Action

The Akka Platform console shows the project structure — each service and its components (entities, views, endpoints) are visible at a glance:

![Akka Platform — Project tree showing services and their components](images/akka-platform-project-tree.png)

The most satisfying moment in deployment is when cross-service communication works without any configuration changes.

In local development, the analysis-service endpoint had:

```java
this.statementClient = httpClientProvider.httpClientFor("statement-service");
```

In production, this exact same code resolves "statement-service" to the deployed instance. No URL changes, no environment variables, no DNS overrides. The `HttpClientProvider` delegates to the Akka Platform's service mesh, which handles:

- **Service resolution** — Maps the service name to the current set of healthy replicas
- **Load balancing** — Distributes requests across replicas
- **TLS** — All inter-service communication is encrypted by default
- **Authentication** — Services within the same project are mutually authenticated

Testing the full chain after deployment:

```bash
# This triggers: recommendation -> analysis -> statement
curl "https://<rec-host>/accounts/acc-1001/recommendations?statementId=stmt-2025-12"
```

```json
[
  {
    "productId": "travel_rewards_card",
    "productName": "Travel Rewards Platinum Card",
    "reason": "Your travel spending is 53.5% of total, earn 3x points on every trip"
  },
  {
    "productId": "bill_pay_assist",
    "productName": "SmartBill Pay Assistant",
    "reason": "Recurring payments detected, automate bills and never miss a due date"
  }
]
```

Three services, three hops, zero configuration. The December statement data (travel-heavy with recurring airline bookings) flows through the analysis categorizer and into the recommendation engine, producing personalized results.

## Automatic Scaling

The platform monitors resource usage and request rates. When load increases, it can:

- Add replicas and rebalance entity partitions
- Scale individual services independently (the recommendation-service might need more compute than the product-service)
- Scale to zero during idle periods (for development environments)

Each service scales independently. If the recommendation-service needs more compute due to increased traffic, the platform adds replicas to that service alone. The statement-service is unaffected. Scaling does not require code changes — entity partitions are rebalanced transparently when replicas are added or removed.

This is transparent to the application code. Entity location is a runtime concern, not an application concern.

## Failure Recovery

When a replica fails:

1. The platform detects the failure (health checks)
2. Partitions from the failed replica are reassigned to healthy replicas
3. Entities on those partitions are recovered by replaying their events from the journal
4. In-flight requests are retried on the new replica

The event journal is the single source of truth. As long as the journal is durable (and the Akka Platform ensures it is), entity state can be reconstructed on any replica. When you deploy a new version, there is no migration — the new code replays events and builds its understanding. When a replica fails, there is no data loss — another replica replays the same events. The events are a complete, immutable record of everything that happened.

We explore the runtime model behind this — entity distribution, location transparency, and multi-region replication — in depth in [Part 5]({{< ref "/blog/akka/platform-internals-multi-region-resilience" >}}).

## Observability

Running microservices in production without observability is operating blind. The Akka Platform provides several tools:

### Service Logs

```bash
akka service logs analysis-service -f
```

This tails the service logs in real-time, showing request handling, cross-service calls, and entity operations. The log entries include correlation IDs that flow across service boundaries, making distributed tracing possible with standard log aggregation.

### Environment Configuration

```bash
# Set analysis mode to agent
akka service env set analysis-service ANALYSIS_MODE=agent

# Set the OpenAI API key for agent mode
akka service env set analysis-service OPENAI_API_KEY=sk-...

# List all environment variables
akka service env list analysis-service
```

Environment variables are managed per service. Changes trigger a rolling restart — the platform drains existing replicas while bringing up new ones with the updated configuration.

## Principles That Emerged in Production

Taking these services from local development to production validated some design decisions and revealed others. These are not theoretical observations — they are lessons that only surface under the pressure of real deployment.

### Same Code, Zero Config Changes

The most satisfying validation was that `httpClientProvider.httpClientFor("statement-service")` worked identically in production. Not similar — identical. The same Java code, the same service name, the same call semantics. Every environment-specific configuration that we did *not* write was a configuration that could not break.

In a traditional deployment, you would have `application-dev.yml`, `application-staging.yml`, and `application-prod.yml` with different URLs for each environment. Each is a potential source of drift. Each is a thing that can be wrong in exactly one environment. The Akka model eliminates this entire category: the service name is the configuration, and the platform resolves it to the correct endpoint everywhere.

### Event Sourcing Enables Fearless Deployment

When a new version of a service starts, it replays events from the journal to reconstruct state. This means deployments do not need data migration scripts — the new code reads the same events and builds the state its way. If the new version has a bug, you roll back and the old code replays the same events correctly.

This is a radical departure from traditional database-backed services, where every schema change requires a migration script, every migration is a point of no return, and every rollback risks data loss. With event sourcing, the events are the schema. The code is just an interpretation.

### Idempotent Initialization Is Not Optional

The seed endpoints being idempotent meant we could run them during deployment scripts, CI/CD pipelines, or manual testing without worrying about duplicate data. Call `POST /accounts/seed` ten times — the second through tenth calls find existing entities and return success without emitting events.

This pattern should be the default for any initialization logic. In production, you will redeploy. CI/CD pipelines will retry. Operators will run scripts manually. If your initialization is not idempotent, you will eventually corrupt your data.

### Pure Business Logic Catches Bugs Before Production

When business logic is a pure function over data (as we discussed in Parts 2 and 3), you can test it with literal JSON strings. No mocking, no service stubs, no test infrastructure. The tests run in milliseconds and catch bugs that would take hours to debug in a distributed environment.

### The Tombstone Delete Pattern Pays Off

The product-service's `@JsonIgnore boolean deleted` pattern kept the API clean while maintaining event journal integrity. In production, you occasionally need to "undelete" an entity — a product was accidentally removed, a statement needs to be restored. With tombstone deletes, this is a new `ProductReactivated` event. Not a journal repair operation. Not a database UPDATE that loses the deletion history. A new fact appended to an immutable log.

## The Full Architecture

Stepping back, here is the complete system as deployed:

```
Akka Platform (GCP us-east1)
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  statement-service (3 replicas)                         │
│  ├── StatementEntity [EventSourcedEntity]               │
│  ├── StatementsByAccountView [View / CQRS]              │
│  └── StatementEndpoint [HTTP, seed, CRUD]               │
│                                                         │
│  analysis-service (3 replicas)                          │
│  ├── AnalysisEndpoint [HTTP, dual-mode routing]         │
│  ├── HeuristicCategorizer [deterministic analysis]      │
│  ├── TransactionAnalysisAgent [Akka Agent, LLM tools]   │
│  ├── AnalysisStore [in-memory cache]                    │
│  └── HttpClientProvider -> "statement-service"          │
│                                                         │
│  recommendation-service (3 replicas)                    │
│  ├── RecommendationEndpoint [HTTP]                      │
│  ├── RecommendationEngine [rules-based matching]        │
│  └── HttpClientProvider -> "analysis-service"           │
│                                                         │
│  product-service (3 replicas)                           │
│  ├── ProductEntity [EventSourcedEntity, tombstone]      │
│  └── ProductEndpoint [HTTP, CRUD, seed]                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

Four services, twelve replicas, zero hardcoded URLs, immutable event journals, derived read models, platform-managed service discovery. This architecture runs in a single region. In [Part 5]({{< ref "/blog/akka/platform-internals-multi-region-resilience" >}}), we explore what happens when you add a second region — and discover that the event-sourced foundations we built make multi-region replication possible without code changes.

## Wrapping Up

Four services, event-sourced from the ground up, communicating through platform-managed discovery, deployed to production with a single command per service. The architectural choices compound: immutability enables fearless deployment, the actor model enables entity-level distribution, platform-managed infrastructure eliminates configuration drift, and the same code runs everywhere without environment-specific changes.

In [Part 5]({{< ref "/blog/akka/platform-internals-multi-region-resilience" >}}), we go deeper into the platform — entity distribution, location transparency, multi-region replication, and conflict resolution. In [Part 6]({{< ref "/blog/akka/developer-experience-platform-advantage" >}}), we step back to reflect on how these architectural choices compound into a fundamentally better developer experience.

The [complete source code](https://github.com/PradeepLoganathan/microsvs-microapp) is available on GitHub, including all four backend services, tests, and deployment scripts.
