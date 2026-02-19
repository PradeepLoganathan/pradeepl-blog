---
title: "Building Resilient Microservices with Akka — Part 3: Deployment, Resilience & Multi-Region"
lastmod: 2026-02-18T16:00:00+10:00
date: 2026-02-18T16:00:00+10:00
draft: true
Author: Pradeep Loganathan
tags:
  - akka
  - microservices
  - deployment
  - multi-region
  - distributed-systems
  - resilience
categories:
  - akka
  - architecture
description: "Taking event-sourced Akka services from local development to global deployment — the Akka Platform deployment workflow, service discovery in action, and multi-region replication for true resilience."
summary: "Deploy event-sourced Akka services to production with zero-config service discovery, explore the runtime model for entity distribution and failure recovery, and understand multi-region replication for global resilience."
ShowToc: true
TocOpen: true
images:
  - "images/cover.png"
cover:
  image: "images/cover.png"
  alt: "Deployment, resilience and multi-region replication with Akka"
  caption: "From local development to globally distributed, resilient microservices with Akka"
  relative: true
series: ["Building Resilient Microservices with Akka"]
---

In [Part 1]({{< ref "/blog/akka/event-sourcing-cqrs-with-akka" >}}), we built event-sourced entities with CQRS views. In [Part 2]({{< ref "/blog/akka/cross-service-communication-agentic-ai" >}}), we wired services together with `HttpClientProvider` and added AI-powered analysis. Everything worked locally with `mvn compile exec:java`.

But local development is the easy part. The real test of a microservices architecture is deployment: can these services run reliably in production, discover each other without configuration, scale independently, and survive failures? And the question that separates good architectures from great ones: can they operate across multiple regions for global resilience and low-latency access?

In this final post, we'll deploy our banking demo to the Akka Platform, examine how the abstractions we built in Parts 1 and 2 translate to production, and explore Akka's multi-region replication — where the event-sourced entities we designed become the foundation for globally distributed, eventually consistent state.

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

The `--push` flag uploads the image to Akka's container registry and deploys it in one step. The platform provisions the runtime, configures the event journal, and starts the service. Within a minute, the service is running:

```bash
akka services list

NAME                     STATUS   REPLICAS
statement-service        Ready    3
product-service          Ready    3
analysis-service         Ready    3
recommendation-service   Ready    3
```

Each service runs with 3 replicas by default. The Akka runtime distributes entity instances across replicas — entity `stmt-2025-12` might live on replica 1, while `stmt-2026-01` lives on replica 2. The `ComponentClient` and `HttpClientProvider` route requests to the correct replica transparently.

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

The `--enable-cors` flag configures CORS headers — essential when browser-based clients (like our mobile banking shell) call the API directly.

### Seeding Data

The statement-service and product-service require seed data. Our endpoint design anticipated this:

```bash
curl -X POST https://<statement-host>/accounts/seed
curl -X POST https://<product-host>/products/seed
```

These endpoints are idempotent by design (recall the `if (currentState() != null) return effects().reply(done())` pattern from Part 1). You can call them multiple times safely — the second call finds existing entities and returns success without emitting duplicate events.

## Service Discovery in Action

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
    "reason": "Your travel spending is 53.5% of total — earn 3x points on every trip"
  },
  {
    "productId": "bill_pay_assist",
    "productName": "SmartBill Pay Assistant",
    "reason": "Recurring payments detected — automate bills and never miss a due date"
  }
]
```

Three services, three hops, zero configuration. The December statement data (travel-heavy with recurring airline bookings) flows through the analysis categorizer and into the recommendation engine, producing personalized results.

## Why This Works: Akka's Runtime Model

To understand why deployment is this smooth, it helps to understand what the Akka runtime does beneath the surface.

### Entity Distribution

When you deploy an `EventSourcedEntity`, the Akka runtime creates a virtual partition space. Entity instances are assigned to partitions based on their entity ID, and partitions are distributed across replicas. This is similar to Kafka's partition model, but for stateful computation rather than message consumption.

When a request arrives for entity `stmt-2025-12`, the runtime routes it to the replica that owns that partition. If the entity is not in memory, the runtime loads it by replaying events from the journal. If it is already in memory, the request is processed immediately. This is why event sourcing and entity distribution work so well together — the event journal is the recovery mechanism for any replica that needs to reconstruct state.

### Automatic Scaling

The platform monitors resource usage and request rates. When load increases, it can:

- Add replicas and rebalance entity partitions
- Scale individual services independently (the recommendation-service might need more compute than the product-service)
- Scale to zero during idle periods (for development environments)

This is transparent to the application code. Entity location is a runtime concern, not an application concern.

### Failure Recovery

When a replica fails:

1. The platform detects the failure (health checks)
2. Partitions from the failed replica are reassigned to healthy replicas
3. Entities on those partitions are recovered by replaying their events from the journal
4. In-flight requests are retried on the new replica

The event journal is the single source of truth. As long as the journal is durable (and the Akka Platform ensures it is), entity state can be reconstructed on any replica. This is the fundamental resilience guarantee of event sourcing — state is not in memory, it is in the journal. Memory is just a cache.

## Multi-Region Replication

Everything we have discussed so far operates within a single region. But for truly resilient systems — systems that survive datacenter failures, that serve users globally with low latency — you need multi-region.

Akka provides multi-region replication for event-sourced entities. The same `EventSourcedEntity` we built in Part 1 can be replicated across regions with minimal code changes.

### How It Works

Multi-region replication in Akka operates at the event level:

1. An entity in Region A processes a command and persists events to its local journal
2. Those events are asynchronously replicated to Region B's journal
3. The entity instance in Region B applies the replicated events, updating its local state

```
Region A (us-east-1)              Region B (eu-west-1)
┌─────────────────────┐           ┌─────────────────────┐
│  StatementEntity    │           │  StatementEntity    │
│  state: [txn1,txn2] │  events  │  state: [txn1,txn2] │
│                     │ -------> │                     │
│  Event Journal      │  async   │  Event Journal      │
│  [Created,TxnAdded] │ replicate│  [Created,TxnAdded] │
└─────────────────────┘           └─────────────────────┘
```

Both regions can serve reads from their local replica. Writes can be directed to either region (active-active) or to a primary region (active-passive), depending on the consistency requirements.

### Conflict Resolution

Active-active multi-region replication introduces the possibility of conflicting writes. Two users might update the same entity in different regions simultaneously, and those updates arrive at each region in different orders.

Akka handles this through **CRDTs (Conflict-free Replicated Data Types)** and **custom conflict resolution**. For many event-sourced entities, the events themselves are commutative — a `TransactionAdded` event in Region A and a `TransactionAdded` event in Region B can be applied in either order and produce the same final state (the statement contains both transactions).

For entities where order matters, you can implement custom merge logic in the `applyEvent` method, using metadata about the event's origin region and timestamp.

### What This Means for Our Banking Demo

Consider the statement-service. A customer's statement is an event-sourced entity that accumulates transactions. If we deploy to two regions:

- Transactions added in `us-east-1` replicate to `eu-west-1`
- Transactions added in `eu-west-1` replicate to `us-east-1`
- Both regions eventually have the complete transaction list
- The `StatementsByAccountView` in each region processes all events and maintains a consistent projection

The analysis-service and recommendation-service benefit transitively — they call the statement-service in their local region, which has a replica of the entity. Cross-region HTTP calls are eliminated; each region is self-sufficient for read operations.

### Configuration

Enabling multi-region replication requires configuration at the entity level and platform level:

```java
@Component(id = "statement")
@Replication(
    regions = {"us-east-1", "eu-west-1"},
    strategy = ReplicationStrategy.ACTIVE_ACTIVE
)
public class StatementEntity extends EventSourcedEntity<Statement, StatementEvent> {
    // ... same code as before
}
```

The entity code does not change. The commands, events, and event handlers remain identical. The replication is a runtime concern handled by the platform — the same separation of concerns that made local-to-cloud deployment seamless.

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

## Lessons from the Deployment

Several insights emerged from taking these services from local development to production:

**Service names are the only addressing mechanism.** The `HttpClientProvider` pattern means that inter-service communication is configuration-free. This is not just convenient — it eliminates an entire category of deployment bugs (wrong URLs, missing environment variables, DNS misconfiguration).

**Idempotent seeds are essential.** The seed endpoints being idempotent meant we could run them during deployment scripts, CI/CD pipelines, or manual testing without worrying about duplicate data. This pattern should be the default for any initialization logic.

**Event sourcing enables fearless deployment.** When a new version of a service starts, it replays events from the journal to reconstruct state. This means deployments do not need data migration scripts — the new code reads the same events and builds the state its way. If the new version has a bug, you roll back and the old code replays the same events correctly.

**The tombstone delete pattern pays off in production.** The product-service's `@JsonIgnore boolean deleted` pattern kept the API clean while maintaining event journal integrity. In production, you occasionally need to "undelete" an entity (a product was accidentally removed, a statement needs to be restored). With tombstone deletes, this is a new event — not a journal repair operation.

**Pure business logic is testable business logic.** The refactoring that moved HTTP fetching into endpoints and made the `HeuristicCategorizer` and `RecommendationEngine` pure functions over data was validated during deployment. Unit tests caught rule threshold bugs that would have been much harder to diagnose through deployed service logs.

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

Four services, twelve replicas, zero hardcoded URLs, immutable event journals, derived read models, platform-managed service discovery, and a path to multi-region replication that requires no application code changes.

## Series Recap

Across these three posts, we built a microservices system grounded in event sourcing and CQRS:

**Part 1** established the foundation — `EventSourcedEntity` for immutable state management, sealed event interfaces for type safety, CQRS with Views for read-optimized projections, and the tombstone delete pattern for handling deletes in event-sourced systems.

**Part 2** connected the services — `HttpClientProvider` for platform-managed inter-service communication, deterministic processing alongside AI-powered agents, and the design principle of keeping business logic as pure functions over data.

**Part 3** brought it to production — the deployment workflow, service discovery in action, failure recovery through event replay, and multi-region replication as the path to global resilience.

The architectural choices compound. Event sourcing enables fearless deployment and multi-region replication. CQRS enables independent read and write scaling. Platform-managed service discovery enables configuration-free deployment. And Akka's entity model — where each entity is a lightweight, independently addressable unit of state and computation — maps naturally to the distributed, replicated, resilient systems that modern applications demand.

The [complete source code](https://github.com/PradeepLoganathan/microsvs-microapp) is available on GitHub, including all four services, tests, deployment scripts, and the Excalidraw architecture diagrams referenced throughout this series.
