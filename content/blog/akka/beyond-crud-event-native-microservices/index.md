---
title: "Beyond CRUD: A Manifesto for Event-Native Microservices"
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
  - micro-frontends
categories:
  - akka
  - architecture
description: "Why most microservice architectures carry monolithic thinking into distributed systems — and how event sourcing, the actor model, and platform-managed infrastructure offer a fundamentally different way to build."
summary: "A manifesto for event-native microservices: why CRUD is a category error, entities are the true unit of distribution, AI should be a peer not a layer, and independence should extend from database to UI pixel."
ShowToc: true
TocOpen: true
images:
  - "images/cover.png"
cover:
  image: "images/cover.png"
  alt: "Beyond CRUD - Event-Native Microservices"
  caption: "A manifesto for building enterprise microservices that are conceptually honest about how distributed systems work"
  relative: true
series: ["Building Resilient Microservices with Akka"]
---

Something is wrong with the way we build microservices.

We decomposed the monolith. We drew service boundaries. We gave each team a repository, a deployment pipeline, and a Kubernetes namespace. And yet, when a production incident strikes at 2 AM, we find ourselves tracing a request across twelve services, staring at a stale database row, asking the same question: *what happened here?*

The row says the account balance is $347.52. But how did it get there? Which transactions were applied? In what order? Was there a reversal that was subsequently reversed? The database — the thing we call the "source of truth" — cannot tell us. It only knows the present tense. The history is gone, overwritten by the last UPDATE statement.

This is not a tooling problem. It is an architectural one. And it runs deeper than most teams realize.

## The CRUD Delusion

The dominant enterprise architecture looks like this: services receive requests, validate them, and update rows in a relational database. Create, Read, Update, Delete. CRUD. It is so deeply ingrained that most frameworks generate it for you. Spring Boot, Django, Rails, .NET — they all assume that your job is to mutate rows in tables.

This model has a seductive simplicity. The database *is* the state. Need to know the current balance? `SELECT balance FROM accounts WHERE id = ?`. Need to change it? `UPDATE accounts SET balance = ? WHERE id = ?`. Done.

But this simplicity is a lie. It hides several problems that only reveal themselves at scale, under pressure, in production:

**You are destroying information.** Every UPDATE overwrites the previous value. You cannot answer temporal questions: what was the balance yesterday at 3 PM? What was the state of this order before the last modification? You've compressed an entire history into a single snapshot and thrown the rest away. Imagine if git only stored the latest version of each file — no diffs, no history, no blame. That is what CRUD does to your business data.

**You are creating invisible coupling.** When two services read and write the same table — or even the same logical entity through an API that fronts a mutable row — they are coupled through shared mutable state. Changing one service's write pattern can break another service's read assumptions. The coupling is invisible because it lives in the data, not in the code.

**You are conflating two fundamentally different concerns.** Writes capture *what happened*. Reads answer *questions*. These have different consistency requirements, different scaling characteristics, different optimization strategies. CRUD forces them through the same path, the same schema, the same database. This is a forced compromise that serves neither concern well.

**You are building on an abstraction that fights distribution.** A mutable row assumes a single writer with exclusive access. In a distributed system with multiple replicas, that assumption requires distributed locks, consensus protocols, or "last-write-wins" semantics that silently lose data. The abstraction that makes single-node programming simple makes distributed programming treacherous.

None of this is new. The banking industry has known this for centuries. A bank ledger does not have an "account balance" field that gets overwritten. It has a sequence of debits and credits, and the balance is computed by summing them. Double-entry bookkeeping — invented in 15th century Italy — is event sourcing. Every transaction is an immutable record. The "current state" is always a derivation.

Version control systems know this too. Git does not store the current state of your files. It stores a sequence of commits — each one an immutable record of what changed. The working directory is a derivation. You can reconstruct any point in history, branch from any moment, merge timelines. The power comes from keeping the history, not from the snapshot.

Even databases know this internally. PostgreSQL uses a write-ahead log (WAL) — an append-only sequence of mutations — as the authoritative record. The tables are merely a materialized view of the WAL. When the database crashes and recovers, it does not trust the tables. It replays the WAL.

The pattern is everywhere: **the log is the truth; the state is a cache.** Yet the default enterprise architecture inverts this. It treats the cache (mutable rows) as the truth and discards the log (the history of changes). This is not a design choice. It is a category error.

## State Is a Derived Value

Event sourcing corrects this inversion. Instead of storing current state, you store the sequence of events that produced it. The current state is computed — it is a left fold over the event log.

This is not merely a storage optimization. It is a different mental model:

```
Traditional:  state = database.read(entity_id)

Event-sourced: state = events.foldLeft(emptyState) { (state, event) =>
                 state.apply(event)
               }
```

The left fold is a pure function. Given the same events in the same order, it always produces the same state. This purity has profound consequences:

**Temporal queries become trivial.** Want the account state as of last Tuesday? Fold the events up to that timestamp. Want to know what changed between two dates? Diff the event subsequence. The history is not an add-on; it is the architecture.

**Debugging becomes deterministic.** A production bug can be reproduced by replaying the exact sequence of events that triggered it. No guessing, no "it works on my machine." The event log is a perfect recording of everything that happened.

**Audit is free.** Every state change is an immutable event with a timestamp, a type, and a payload. Compliance teams do not need a separate audit table that might drift from reality. The event log *is* the audit trail.

**Recovery is replay.** When a service crashes, when a new replica starts, when you deploy a new version — the state is reconstructed by replaying events from the journal. There is no data migration script, no schema diff to apply. The new code reads the old events and builds its understanding of the world. This means deployments cannot corrupt state. If the new version has a bug, you roll back and the old code replays the same events correctly.

**New read models are retroactive.** Need a new dashboard that aggregates data in a way you did not anticipate? Build a new projection, point it at the event log, and let it process the entire history. The data was always there; you just had not asked that question yet.

Event sourcing does not add complexity. It removes the complexity that CRUD hides — the silent data loss, the temporal blindness, the coupling through shared mutable state. The system becomes more complex *to build* (you must design events, manage projections, think about eventual consistency) but simpler *to reason about* (state is deterministic, history is complete, recovery is mechanical).

## Entities, Not Services, Are the Unit of Distribution

The microservices movement taught us to decompose by service boundary. Each service owns a domain, a database, an API. This is a significant improvement over the monolith. But it stops one level of abstraction too soon.

Consider a banking system with a statement-service that manages bank statements. In a traditional architecture, the service has N statement rows in a database table. All requests go to the service, which routes them to the right row. The service is the unit of deployment, the unit of scaling, and the unit of failure.

But what actually needs to be distributed? Not the service — the *entities*. Statement A and Statement B have no relationship to each other. They do not share state, they do not need to coordinate, they do not conflict. If Statement A is being processed on Node 1 and Statement B on Node 2, there is no reason for them to be aware of each other's existence.

This is the insight at the heart of the actor model — the computational model that Akka is built on. In the actor model, the fundamental unit is not the service or the thread or the process. It is the **entity**: an independently addressable, location-transparent unit of state and computation.

Each entity:

- **Has its own state** — not a row in a shared table, but an isolated state machine that processes events sequentially
- **Processes messages one at a time** — no locks, no concurrent mutation, no race conditions
- **Can live anywhere in the cluster** — the runtime decides which node hosts which entity, and routes messages accordingly
- **Fails independently** — if entity A crashes, entity B is unaffected. The runtime recovers A by replaying its events on another node.

This is a fundamentally different decomposition than "one service per bounded context." The service is a deployment unit — a container with endpoints. The entity is a *computational* unit — an autonomous agent with state, behavior, and a mailbox. You might have a million entities within a single service, each independently addressable, each processing its own events, each recoverable from its own journal.

When you combine event sourcing with the actor model, the synergy is remarkable. The event journal is the recovery mechanism — any node that needs to take over an entity simply replays its events. The entity's sequential message processing eliminates write conflicts — there is exactly one writer for each entity at any moment. The location transparency means the runtime can rebalance entities across nodes as load changes, without application code knowing or caring.

The service boundary still matters — it defines the deployment unit, the team boundary, the API contract. But within that boundary, the entity is the unit of *everything that matters for distribution*: addressing, consistency, failure isolation, and scaling.

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

The industry has spent a decade building increasingly sophisticated infrastructure to manage the complexity of services talking to each other — service meshes, API gateways, configuration servers, secret managers. Each layer solves a real problem but adds its own operational burden. Platform-managed service discovery asks a different question: what if the platform just handled this, and the application code expressed intent ("I need to talk to statement-service") rather than mechanism ("connect to this host on this port with this certificate")?

## AI as Peer, Not Layer

The current enterprise approach to AI is architectural bolting. You have your microservices running in Kubernetes, and you add an "AI layer" — typically a separate service that wraps an LLM API. Other services call this AI service, wait for a response, and incorporate the result into their workflow.

This works, but it treats AI as something *external* to the architecture. The AI service has different deployment patterns, different failure modes, different scaling characteristics. It is a special case.

There is a more interesting possibility: what if the LLM were just another component with the same architectural contracts as everything else?

In the banking demo we will build in this series, the analysis-service has two modes. In heuristic mode, it categorizes transactions using deterministic keyword matching — fast, predictable, no external dependencies. In agent mode, it uses an LLM with function tools to perform the same analysis — slower, more nuanced, requires an API key.

The critical design decision is that both modes produce the same output: an `AnalysisSummary` with categories, top merchants, and insights. The recommendation-service calls the analysis-service and receives a summary. It does not know or care whether that summary was produced by a rules engine or by an LLM. The contract is the same. The demo happens to use OpenAI's GPT-4, but the architecture is LLM-agnostic — any model that can call function tools will work without changing the surrounding services.

The LLM-powered agent uses function tools — annotated methods that the LLM can invoke during its reasoning. One tool fetches transactions from the statement-service (using the same `HttpClientProvider` as any other inter-service call). Another tool categorizes transactions using the same deterministic logic as the heuristic mode. The agent orchestrates these tools, but the tools themselves are the same building blocks used by the rest of the system.

This is AI as a *peer* — a component that participates in the same service mesh, uses the same communication patterns, produces the same contracts. It is not a special layer with special rules. It is a strategy that can be swapped in or out based on configuration, with the rest of the architecture unchanged.

For enterprises adopting AI, this matters enormously. Instead of building a parallel AI infrastructure, you extend your existing service architecture to include LLM-powered components alongside deterministic ones. Testing is straightforward — you test the contract, not the implementation. Fallback is trivial — switch from agent mode to heuristic mode and the system keeps working. The AI capability is additive, not foundational.

## The Frontend Is a Microservice Too

We spent the last decade decoupling the backend. Services are independently deployable, independently scalable, independently evolvable. Teams own their services end-to-end.

But look at the frontend. Most organizations still ship a monolithic web or mobile application. Every team's UI changes go into the same build pipeline, the same release train, the same app store submission. The frontend is where independence goes to die.

Micro-frontends fix this, but most implementations add enormous complexity — webpack Module Federation with shared dependencies, runtime container orchestration, CSS isolation battles. The complexity often exceeds what teams are willing to accept.

There is a simpler approach that mirrors the backend's architecture. In our banking demo, the mobile shell application does not know what UI components exist at compile time. At runtime, it fetches a manifest from a registry — a JSON file that lists available micro-apps, their versions, and their CDN locations. The shell loads each micro-app as a Web Component — a standard browser API — and renders it into the page.

```
Shell fetches manifest → discovers "statement-analysis" v2.0.0
Shell injects <script src="cdn/statement-analysis/2.0.0/main.js">
Browser registers <mf-statement-analysis> custom element
Shell creates element and appends to DOM
Micro-app renders independently, calls its own backend services
```

Want to update the analysis UI? Build the new version, publish it to the CDN, update the manifest. Users see the new version on their next page load. No app store review. No coordinated release with other teams. No risk to the statement-details or recommendations micro-apps.

This is the backend decoupling philosophy applied to the frontend. The manifest is the frontend's equivalent of service discovery. The CDN is the frontend's equivalent of the container registry. The Web Component is the frontend's equivalent of the API contract — a custom HTML element with attributes, encapsulated from everything around it.

When you combine this with the backend architecture — event-sourced entities, platform-managed service discovery, independently deployable services — the entire system, from database event to UI pixel, is independently deployable. A team can change how a transaction is categorized (backend logic), how the analysis is displayed (micro-app UI), and how the data flows between them (service communication) — without coordinating with any other team, without touching any other service, without risking any other feature.

This is what "microservices" was supposed to mean. Not just backend decomposition, but *system-wide independence*.

## What We Will Build

This series builds a banking platform that embodies these principles. The system comprises four backend microservices, a micro-frontend shell with independently deployable UI components, and platform services that tie them together:

```
                    Mobile Shell (Ionic Angular)
                    ├── <mf-statement-details>
                    ├── <mf-statement-analysis>
                    └── <mf-recommendations>
                           │
            ┌──────────────┼──────────────────────┐
            │              │                      │
            v              v                      v
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

**The analysis-service** categorizes spending with both a deterministic heuristic engine and an LLM-powered Akka Agent. It calls the statement-service using platform-managed HTTP — no URLs, no configuration.

**The recommendation-service** applies rules against the analysis to suggest financial products. It calls the analysis-service, which calls the statement-service — three services collaborating through a chain of platform-managed HTTP calls.

**The product-service** manages a financial product catalog with event sourcing and tombstone deletes — demonstrating how to handle entity deletion in an append-only event model.

**The mobile shell** dynamically loads micro-app web components from a CDN based on a runtime manifest, enabling independent UI deployment with version switching.

The complete source code is available on [GitHub](https://github.com/PradeepLoganathan/microsvs-microapp).

## The Series

**[Part 1: Event Sourcing & CQRS]({{< ref "/blog/akka/event-sourcing-cqrs-with-akka" >}})** — We build the foundational data layer. `EventSourcedEntity` for immutable state management, sealed event interfaces for type safety, CQRS with Views for read-optimized projections, tombstone deletes, and idempotent command handling. This is where we prove that state-as-derived-value works in practice.

**[Part 2: Cross-Service Communication & Agentic AI]({{< ref "/blog/akka/cross-service-communication-agentic-ai" >}})** — We wire the services together. `HttpClientProvider` for configuration-free inter-service communication, dual-mode analysis with deterministic heuristics alongside an LLM-powered Akka Agent, and the design principles that emerge when you keep business logic as pure functions over data.

**[Part 3: Deployment, Resilience & Multi-Region]({{< ref "/blog/akka/deployment-resilience-multi-region" >}})** — We take the system to production. The deployment workflow, service discovery in action, entity distribution across replicas, failure recovery through event replay, and the path to multi-region replication where event-sourced entities become globally distributed.

**Part 4: Micro-Frontends — Independently Deployable from Database to Pixel** — We complete the independence story. Manifest-driven micro-app discovery, Web Components as the integration contract, CDN-hosted versioned bundles, live version switching, and the full-stack architecture where every layer — from event journal to UI component — is independently deployable.

---

The architectural choices compound. Event sourcing enables fearless deployment and multi-region replication. The actor model enables entity-level distribution and failure isolation. Platform-managed discovery eliminates configuration drift. AI-as-peer enables graceful adoption without architectural upheaval. Micro-frontends extend independence to the UI.

Individually, each of these is a useful technique. Together, they form a coherent philosophy: **build systems that are honest about how distribution works, that preserve history instead of destroying it, and that achieve independence at every layer of the stack.**

Let's begin.
