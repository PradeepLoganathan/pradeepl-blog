---
title: "Beyond CRUD: A Manifesto for Resilient Microservices"
lastmod: 2026-02-19T10:00:00+10:00
date: 2026-02-19T10:00:00+10:00
draft: true
Author: Pradeep Loganathan
tags:
  - akka
  - microservices
  - event-sourcing
  - cqrs
  - actor-model
  - distributed-systems
  - architecture
  - resilience
categories:
  - akka
  - architecture
description: "Why most microservice architectures carry monolithic thinking into distributed systems — and how event sourcing, CQRS, the actor model, and platform-managed infrastructure offer a fundamentally different approach to building high-performance, resilient services."
summary: "A manifesto for resilient microservices: why CRUD is a category error in distributed systems, entities are the true unit of distribution, immutability is the foundation of resilience, and platform-managed infrastructure enables true service independence."
ShowToc: true
TocOpen: true
images:
  -
series: ["Building Resilient Microservices with Akka"]
weight: 1
---

{{< series-toc >}}

Something is wrong with the way we build microservices.

We decomposed the monolith. We drew service boundaries. We gave each team a repository, a deployment pipeline, and a Kubernetes namespace. And yet, when a production incident strikes at 2 AM, we find ourselves tracing a request across twelve services, staring at a stale database row, asking the same question: *what happened here?*

The row says the account balance is $347.52. But how did it get there? Which transactions were applied? In what order? Was there a reversal that was subsequently reversed? The database, the thing we call the "source of truth", cannot tell us. It only knows the present tense. The history is gone, overwritten by the last UPDATE statement.

This is not a tooling problem. It is an architectural one. And it runs deeper than most teams realize.

We decomposed the code but not the mental model. The monolith is gone from the repository, but it lives on in our assumptions about how state works, how failures propagate, and how services should communicate. We split the application into services but carried the same CRUD mindset, the same mutable state, the same synchronous request/reply expectations, the same belief that consistency comes cheap and failure is exceptional. The architecture changed. The thinking did not.

## The Distributed Systems Complexity Problem

The promise of microservices was compelling: independent deployment, team autonomy, technology diversity, and the ability to scale individual components rather than the entire system. Smaller services, faster iteration, fewer coordination costs.

What actually happens is different. Teams build services that share databases through back channels, coordinate releases because of schema dependencies, and cascade failures through synchronous call chains. The monolith was a single process that failed atomically. The distributed monolith is a network of processes that fail in correlated, unpredictable, and difficult-to-diagnose ways.

The root cause is not microservices themselves. It is that we carried three monolithic assumptions into the distributed world:

**Mutable shared state is manageable.** Within a single process, mutable state is already the primary source of bugs — race conditions, stale reads, inconsistent writes. Across network boundaries, it becomes pathological. Two services writing to the same row through a shared API creates a distributed coordination problem. Two replicas of the same service writing to the same database creates a consistency problem. Every mutable shared reference is a distributed lock waiting to happen — and distributed locks mean latency, contention, and failure modes that do not exist in a monolith.

**Consistency is cheap.** In a single-process application, consistency is nearly free — a function call returns before the caller continues. In a distributed system, consistency requires coordination: two-phase commits, consensus protocols, distributed transactions. Each coordination point adds latency and reduces availability. The CAP theorem is not a theoretical curiosity; it is a design constraint that every distributed system must navigate. Strong consistency across services is possible, but it costs performance and availability in ways that most teams underestimate.

**Failure is exceptional.** In a monolith, the process is either running or it is not. In a distributed system, *partial failure is the normal operating state*. The network is unreliable. Latencies spike. Services restart. Nodes disappear. A system designed under the assumption that failure is exceptional will be fragile; a system designed under the assumption that failure is routine can be resilient.

To build high-performance, resilient microservices, you must abandon these three assumptions and replace them with their distributed counterparts: immutability instead of mutable shared state, eventual consistency instead of distributed transactions, and failure isolation instead of failure avoidance.

## The CRUD Delusion

The dominant enterprise architecture looks like this: services receive requests, validate them, and update rows in a relational database. Create, Read, Update, Delete. CRUD. It is so deeply ingrained that most frameworks generate it for you. Spring Boot, Django, Rails, .NET, they all assume that your job is to mutate rows in tables.

This model has a seductive simplicity. The database *is* the state. Need to know the current balance? `SELECT balance FROM accounts WHERE id = ?`. Need to change it? `UPDATE accounts SET balance = ? WHERE id = ?`. Done.

But this simplicity is a lie. It hides several problems that only reveal themselves at scale, under pressure, in production:

**You are destroying information.** Every UPDATE overwrites the previous value. You cannot answer temporal questions: what was the balance yesterday at 3 PM? What was the state of this order before the last modification? You've compressed an entire history into a single snapshot and thrown the rest away. Imagine if git only stored the latest version of each file, no diffs, no history, no blame. That is what CRUD does to your business data.

**You are creating invisible coupling.** When two services read and write the same table, or even the same logical entity through an API that fronts a mutable row, they are coupled through shared mutable state. Changing one service's write pattern can break another service's read assumptions. The coupling is invisible because it lives in the data, not in the code.

**You are conflating two fundamentally different concerns.** Writes capture *what happened*. Reads answer *questions*. These have different consistency requirements, different scaling characteristics, different optimization strategies. CRUD forces them through the same path, the same schema, the same database. This is a forced compromise that serves neither concern well.

**You are building on an abstraction that fights distribution.** A mutable row assumes a single writer with exclusive access. In a distributed system with multiple replicas, that assumption requires distributed locks, consensus protocols, or "last-write-wins" semantics that silently lose data. The abstraction that makes single-node programming simple makes distributed programming treacherous. Every replica you add to improve resilience also adds a new participant in the distributed coordination problem. The more resilient you try to make a CRUD service, the more complex it becomes — more locks, more retries, more conflict resolution, more failure modes.

None of this is new. The banking industry has known this for centuries. A bank ledger does not have an "account balance" field that gets overwritten. It has a sequence of debits and credits, and the balance is computed by summing them. Double-entry bookkeeping, invented in 15th century Italy, is event sourcing. Every transaction is an immutable record. The "current state" is always a derivation.

Version control systems know this too. Git does not store the current state of your files. It stores a sequence of commits, each one an immutable record of what changed. The working directory is a derivation. You can reconstruct any point in history, branch from any moment, merge timelines. The power comes from keeping the history, not from the snapshot.

Even databases know this internally. PostgreSQL uses a write-ahead log (WAL), an append-only sequence of mutations, as the authoritative record. The tables are merely a materialized view of the WAL. When the database crashes and recovers, it does not trust the tables. It replays the WAL.

The pattern is everywhere: **the log is the truth; the state is a cache.** Yet the default enterprise architecture inverts this. It treats the cache (mutable rows) as the truth and discards the log (the history of changes). This is not a design choice. It is a category error.

## State Is a Derived Value

Event sourcing corrects this inversion. Instead of storing current state, you store the sequence of events that produced it. The current state is computed, it is a left fold over the event log.

This is not merely a storage optimization. It is a different mental model:

```
Traditional:  state = database.read(entity_id)

Event-sourced: state = events.foldLeft(emptyState) { (state, event) =>
                 state.apply(event)
               }
```

The left fold is a pure function. Given the same events in the same order, it always produces the same state. This purity has profound consequences:

**Temporal queries become trivial.** Want the account state as of last Tuesday? Fold the events up to that timestamp. Want to know what changed between two dates? Diff the event subsequence. The history is not an add-on; it is the architecture.

**Debugging becomes deterministic.** A production bug can be reproduced by replaying the exact sequence of events that triggered it. No guessing, no "it works on my machine." The event log is a perfect recording of everything that happened. In production, this means you can reproduce any failure by replaying events. "Unable to reproduce" ceases to be a category of bug.

**Audit is free.** Every state change is an immutable event with a timestamp, a type, and a payload. Compliance teams do not need a separate audit table that might drift from reality. The event log *is* the audit trail.

**Recovery is replay.** When a service crashes, when a new replica starts, when you deploy a new version, the state is reconstructed by replaying events from the journal. There is no data migration script, no schema diff to apply. The new code reads the old events and builds its understanding of the world. This is the foundation of resilience: a crashed replica does not lose data — it replays events. A new region does not need a data migration — it replays events. A new version does not need a schema change — it replays events. Deployments cannot corrupt state. If the new version has a bug, roll back and the old code replays the same events correctly. There is no point of no return.

**New read models are retroactive.** Need a new dashboard that aggregates data in a way you did not anticipate? Build a new projection, point it at the event log, and let it process the entire history. The data was always there; you just had not asked that question yet.

Event sourcing does not add complexity. It removes the complexity that CRUD hides, the silent data loss, the temporal blindness, the coupling through shared mutable state. The system becomes more complex *to build* (you must design events, manage projections, think about eventual consistency) but simpler *to reason about* (state is deterministic, history is complete, recovery is mechanical).

## Entities, Not Services, Are the Unit of Distribution

The microservices movement taught us to decompose by service boundary. Each service owns a domain, a database, an API. This is a significant improvement over the monolith. But it stops one level of abstraction too soon.

Consider a banking system with a statement-service that manages bank statements. In a traditional architecture, the service has N statement rows in a database table. All requests go to the service, which routes them to the right row. The service is the unit of deployment, the unit of scaling, and the unit of failure.

But what actually needs to be distributed? Not the service, the *entities*. Statement A and Statement B have no relationship to each other. They do not share state, they do not need to coordinate, they do not conflict. If Statement A is being processed on Node 1 and Statement B on Node 2, there is no reason for them to be aware of each other's existence.

This is the insight at the heart of the actor model, the computational model that Akka is built on. In the actor model, the fundamental unit is not the service or the thread or the process. It is the **entity**: an independently addressable, location-transparent unit of state and computation.

Each entity:

- **Has its own state**, not a row in a shared table, but an isolated state machine that processes events sequentially
- **Processes messages one at a time**, no locks, no concurrent mutation, no race conditions
- **Can live anywhere in the cluster**, the runtime decides which node hosts which entity, and routes messages accordingly
- **Fails independently**, if entity A crashes, entity B is unaffected. The runtime recovers A by replaying its events on another node.

Because entities process messages sequentially with isolated state, there are no locks, no contention, no thread synchronization. This is how you achieve high performance in a distributed system — not by avoiding coordination, but by making coordination unnecessary at the entity level. Each entity is a single-writer, single-reader unit. A million entities can process a million commands concurrently on a cluster, with zero shared state and zero locking overhead.

This is a fundamentally different decomposition than "one service per bounded context." The service is a deployment unit, a container with endpoints. The entity is a *computational* unit, an autonomous agent with state, behavior, and a mailbox. You might have a million entities within a single service, each independently addressable, each processing its own events, each recoverable from its own journal.

When you combine event sourcing with the actor model, the synergy is remarkable. The event journal is the recovery mechanism, any node that needs to take over an entity simply replays its events. The entity's sequential message processing eliminates write conflicts, there is exactly one writer for each entity at any moment. The location transparency means the runtime can rebalance entities across nodes as load changes, without application code knowing or caring.

The service boundary still matters, it defines the deployment unit, the team boundary, the API contract. But within that boundary, the entity is the unit of *everything that matters for distribution*: addressing, consistency, failure isolation, and scaling.

## The Configuration Trap

Open the Kubernetes manifests of any enterprise microservice deployment. Count the ConfigMaps. Count the environment variables. Count the service entries, the ingress rules, the DNS records. Each one is a failure mode.

The analysis-service needs to call the statement-service. In a traditional setup, this requires:

- A Kubernetes Service resource for statement-service
- A DNS name or environment variable that the analysis-service reads
- Configuration that differs between dev, staging, and production
- Possibly a service mesh (Istio, Linkerd) for TLS, retries, and circuit breaking
- Health checks to detect when statement-service is down

Every one of these is a thing that can go wrong. The DNS entry can be stale. The environment variable can be wrong in one environment. The service mesh can have version incompatibilities. The health checks can have misconfigured thresholds.

Now consider the alternative. In Akka SDK, the analysis-service calls the statement-service like this:

```java
HttpClient statementClient = httpClientProvider.httpClientFor("statement-service");
```

That is the entire configuration. The string `"statement-service"` is the service's deployed name. The platform resolves it to the correct endpoint, handles TLS, load-balances across replicas, manages retries, and provides circuit breaking. The same code works in local development and in production. There are no environment variables, no DNS overrides, no service registry, no sidecar proxy.

This is not syntactic sugar. It is the elimination of an entire category of production incidents. Every URL you do not configure is a URL that cannot be misconfigured. Every infrastructure component you do not deploy is a component that cannot fail.

The industry has spent a decade building increasingly sophisticated infrastructure to manage the complexity of services talking to each other, service meshes, API gateways, configuration servers, secret managers. Each layer solves a real problem but adds its own operational burden. Platform-managed service discovery asks a different question: what if the platform just handled this, and the application code expressed intent ("I need to talk to statement-service") rather than mechanism ("connect to this host on this port with this certificate")?

## AI as Peer, Not Layer

The current enterprise approach to AI is architectural bolting. You have your microservices, and you add an "AI layer" — a separate service that wraps an LLM API. Other services call this AI service, wait for a response, and incorporate the result. This works, but it treats AI as something *external* to the architecture, with different deployment patterns, different failure modes, and different scaling characteristics.

There is a more interesting possibility: what if the LLM were just another component with the same architectural contracts as everything else?

In the banking demo we build in this series, the analysis-service has two modes: a deterministic heuristic engine and an LLM-powered Akka Agent. Both produce the same output — an `AnalysisSummary` with categories, merchants, and insights. The recommendation-service calls the analysis-service and receives a summary. It does not know or care whether that summary was produced by a rules engine or by an LLM. The contract is the same.

The LLM-powered agent uses function tools — annotated methods that the LLM can invoke during reasoning — and those tools use the same `HttpClientProvider` and the same deterministic logic as the rest of the system. Because the agent is an Akka component, it gets the same resilience guarantees: circuit breaking, supervision, logging, and lifecycle management. If the LLM provider is down, the endpoint falls back to heuristic mode. The failure is isolated. The AI capability is additive, not foundational.

Testing is contract-based — you test the output, not the implementation. Fallback is trivial. Adoption is incremental.

## Performance and Resilience by Design

The architectural choices in this series are not independent. They form a chain, where each link enables the next:

**Immutability** means events can be stored, cached, and replicated without transformation. An immutable event is the same in every region, on every replica, at every point in time.

**Idempotency** means commands can be safely retried. If a network partition causes a duplicate delivery, the entity recognizes it and returns success without emitting new events. Retries are free.

**Event sourcing** means state can be rebuilt anywhere, at any time, by replaying the event log. The entity's in-memory state is a cache; the journal is the truth.

**Replay recovery** means replicas are disposable. A crashed node does not lose data. A new replica does not need a data migration. It replays events and converges to the correct state.

**Entity distribution** means computation is partitioned. Entities live on specific replicas, process commands locally, and fail independently. The runtime routes requests to the correct replica without application code knowing the topology.

**Multi-region replication** means events — immutable, idempotent, replayable — flow between regions. Each region maintains a local copy of the event journal. Reads are local. The same code runs everywhere.

Remove immutability from the base, and every layer above it collapses. Mutable state cannot be safely replicated. Non-idempotent commands cannot be safely retried. Impure state derivation cannot be safely replayed. Performance and resilience are not features you bolt on. They are consequences of getting the fundamentals right.

## What We Will Build

This series builds a banking platform that embodies these principles. The system comprises four backend microservices and platform services that tie them together. Here is what the deployed system looks like on the Akka Platform:

![Akka Platform — Deployed services for the microapp-demo project](images/akka-platform-services-dashboard.png)

```
    statement-service  analysis-service  recommendation-service
    [EventSourced]     [Heuristic + Agent]  [Rules Engine]
    [CQRS Views]       [HttpClientProvider]  [HttpClientProvider]
            │              │                      │
            │              └──────────┬───────────┘
            │                         │
            └─────────────────────────┘
                  Event Journals
                  (immutable, append-only)

    product-service
    [EventSourced, Tombstone Deletes]
```

**The statement-service** manages bank statements and transactions as event-sourced entities. Every transaction is an immutable event; the statement state is a left fold. CQRS views provide read-optimized projections.

**The analysis-service** categorizes spending with both a deterministic heuristic engine and an LLM-powered Akka Agent. It calls the statement-service using platform-managed HTTP, no URLs, no configuration.

**The recommendation-service** applies rules against the analysis to suggest financial products. It calls the analysis-service, which calls the statement-service, three services collaborating through a chain of platform-managed HTTP calls.

**The product-service** manages a financial product catalog with event sourcing and tombstone deletes, demonstrating how to handle entity deletion in an append-only event model.

The complete source code is available on [GitHub](https://github.com/PradeepLoganathan/microsvs-microapp).

## The Series

**[Part 1: Event Sourcing Fundamentals]({{< ref "/blog/akka/event-sourcing-cqrs-with-akka" >}})** — We build the foundational data layer. `EventSourcedEntity` for immutable state management, sealed event interfaces for type safety, tombstone deletes, and idempotent command handling. This is where we prove that state-as-derived-value works in practice.

**[Part 2: Views, CQRS & Read/Write Optimization]({{< ref "/blog/akka/views-cqrs-read-write-optimization" >}})** — We separate reads from writes. Akka Views consume entity events to build denormalized read models. We explore `StatementsByAccountView` and `AllProductsView` from the sample project and examine how CQRS enables independent optimization of read and write paths.

**[Part 3: Cross-Service Communication & Agentic AI]({{< ref "/blog/akka/cross-service-communication-agentic-ai" >}})** — We wire the services together. `HttpClientProvider` for configuration-free inter-service communication, dual-mode analysis with deterministic heuristics alongside an LLM-powered Akka Agent, and the design decisions that emerge when you keep business logic as pure functions over data.

**[Part 4: From Code to Cloud]({{< ref "/blog/akka/deployment-resilience-multi-region" >}})** — We deploy to production. The deployment workflow, service discovery in action, automatic scaling, and the operational simplicity that event sourcing enables. Same code, zero configuration changes, one-command deployment.

**[Part 5: Platform Internals — Multi-Region, Entity Distribution & Resilience]({{< ref "/blog/akka/platform-internals-multi-region-resilience" >}})** — We go beneath the deployment surface. Entity distribution as a partitioning model, location transparency, failure recovery through event replay, multi-region replication, primaries and secondaries, conflict resolution, and entity reconciliation.

**[Part 6: Developer Experience & the Platform Advantage]({{< ref "/blog/akka/developer-experience-platform-advantage" >}})** — We step back and reflect on how the architectural choices across this series compound into a fundamentally better developer experience — from the local development loop and AI-assisted spec-based development, to testing ergonomics and deployment simplicity.

---

The architectural choices compound. Each post builds on the foundations of the one before it. Event sourcing enables fearless deployment and multi-region replication. The actor model enables entity-level distribution and failure isolation. Platform-managed discovery eliminates configuration drift. AI-as-peer enables graceful adoption without architectural upheaval.

Individually, each of these is a useful technique. Together, they form a coherent philosophy: **build systems that are honest about how distribution works, that preserve history instead of destroying it, and that achieve resilience not through redundancy but through correctness.**

Let's begin.
