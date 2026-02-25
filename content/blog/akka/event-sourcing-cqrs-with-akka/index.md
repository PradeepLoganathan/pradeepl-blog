---
title: "Building Resilient Microservices with Akka — Part 1: Event Sourcing Fundamentals"
lastmod: 2026-02-18T16:00:00+10:00
date: 2026-02-18T16:00:00+10:00
draft: true
Author: Pradeep Loganathan
tags:
  - akka
  - microservices
  - event-sourcing
  - java
  - distributed-systems
  - resilience
categories:
  - akka
  - architecture
description: "Building immutable, event-sourced microservices with Akka SDK — practical patterns for entities, sealed event interfaces, tombstone deletes, and idempotent command handling from a banking demo."
summary: "Build immutable, event-sourced microservices with Akka SDK — entities as the unit of distribution, sealed event interfaces for type safety, tombstone deletes, idempotent command handling, and testing with EventSourcedTestKit."
ShowToc: true
TocOpen: true
images:
  - "images/cover.png"
cover:
  image: "images/cover.png"
  alt: "Event Sourcing Fundamentals with Akka SDK"
  caption: "Building immutable, event-sourced microservices with Akka SDK"
  relative: true
series: ["Building Resilient Microservices with Akka"]
weight: 2
---

{{< series-toc >}}

In the [introduction to this series]({{< ref "/blog/akka/beyond-crud-event-native-microservices" >}}), we argued that most microservice architectures carry a fundamental error: they treat mutable database rows as the source of truth, destroying history with every UPDATE statement. We proposed a correction — event sourcing, where state is a derived value computed from an immutable log of facts.

This post puts that argument into practice. We will build two event-sourced services using the **Akka SDK**, and in the process encounter the patterns that make event sourcing not just theoretically sound but practically powerful: sealed event interfaces for type-safe evolution, immutability as an architectural guarantee, tombstone deletes for handling deletion in an append-only world, and idempotent command handling for surviving the realities of distributed message delivery.

Views and CQRS projections build on these foundations — we explore those in detail in [Part 2]({{< ref "/blog/akka/views-cqrs-read-write-optimization" >}}).

The complete source code for this series is available on [GitHub](https://github.com/PradeepLoganathan/microsvs-microapp). The demo comprises four backend microservices — statement-service, analysis-service, recommendation-service, and product-service — that together form a banking platform capable of analyzing customer spending and recommending financial products.

![Statement Service Architecture](images/statement-service-architecture.png)

## Why Event Sourcing for Microservices?

Traditional CRUD services store the current state of an entity. When a customer's account balance changes, the old value is overwritten. This seems simple, but it introduces subtle problems in distributed systems:

- **Lost history** — You cannot reconstruct how the system reached its current state. Debugging production issues becomes archaeological guesswork.
- **Conflicting writes** — Two services updating the same row create race conditions that are notoriously difficult to resolve.
- **Tight coupling to schema** — Every consumer reads the same mutable record, making independent evolution painful.
- **No natural audit trail** — Compliance and debugging require bolted-on audit logging that inevitably drifts from reality.
- **Performance ceilings** — Read-modify-write cycles require locks. Locks mean contention. Contention means latency. At scale, mutable state becomes a performance bottleneck that no amount of caching can solve.

Event sourcing inverts this model. Instead of storing current state, we store the sequence of events that produced it. The current state is a derived value, a left fold over the event log. And it addresses all five problems *structurally* — not through additional infrastructure, but through a different architectural model.

### The Left Fold: State as Computation Over History

This idea — state as a left fold — deserves more attention than it usually gets, because it is the intellectual core of everything that follows in this series.

```
state = events.foldLeft(emptyState) { (state, event) => state.apply(event) }
```

In concrete terms: you start with an empty state (a new entity with no history), and you apply each event in sequence. After applying the first event, you have a state. Apply the second event to that state, you get a new state. Continue until you run out of events. The final result is the current state.

This is a pure function. Given the same events in the same order, it always produces the same state. This purity unlocks capabilities that mutable-state architectures simply cannot offer:

- **Temporal queries** — Want the state as of last Tuesday? Fold the events up to that timestamp. Want to know what changed between two dates? Fold the subsequence. The history is not an add-on; it is the architecture.
- **Deterministic debugging** — A production bug can be reproduced by replaying the exact sequence of events that triggered it. No guessing, no "it works on my machine."
- **Free audit trails** — Every state change is an immutable event with a timestamp, a type, and a payload. Compliance teams do not need a separate audit table that might drift from reality. The event log *is* the audit trail.
- **Recovery by replay** — When a service crashes, a new replica starts, or you deploy a new version, state is reconstructed by replaying events. No data migration scripts, no schema diffs. The new code reads the old events and builds its understanding of the world.
- **Retroactive projections** — Need a new dashboard that aggregates data in a way you never anticipated? Build a new view, point it at the event log, and let it process the complete history. The data was always there; you just had not asked that question yet.

The left fold is not an implementation detail. It is the architectural invariant. Everything else — entity distribution, failure recovery, multi-region replication — depends on this function being pure. If `applyEvent` has side effects, replay produces different results. If replay produces different results, recovery is broken. The purity of the fold is the contract that makes everything else in this series possible.

There is a performance dimension as well. Writes in an event-sourced system are appends — the fastest possible disk operation. No read-modify-write cycle. No lock acquisition. No index update on every write. The entity processes a command, emits an event, and the event is appended to the journal. This is inherently faster than the CRUD pattern of read → lock → modify → write → release.

This is not a novel concept. Accounting ledgers, version control systems, and database write-ahead logs have always worked this way. The pattern is everywhere: **the log is the truth; the state is a cache.** Event sourcing simply makes this the architectural default rather than a hidden implementation detail.

In Akka SDK, this pattern is first-class. The `EventSourcedEntity` is the core building block: it receives commands, validates them against the current state, emits events, and applies those events to produce the next state. The runtime handles persistence, snapshotting, and recovery transparently.

## The Statement Service: Event Sourcing in Practice

The statement-service manages bank statements and transactions for customer accounts. Each statement is an event-sourced entity that maintains an immutable log of everything that has happened to it.

### Defining the Domain

We start with the domain records. In Java 21, records give us immutable value types with no boilerplate:

```java
public record Statement(
    String statementId,
    String accountId,
    String periodStart,
    String periodEnd,
    double totalDebits,
    double totalCredits,
    List<Transaction> transactions
) {}

public record Transaction(
    String id,
    String date,
    String merchant,
    double amount,
    String category,
    String description
) {}
```

These records are immutable by design. A `Statement` is never mutated — when a transaction is added, a new `Statement` instance is created with the updated transaction list and recalculated totals.

### Events as the Source of Truth

Events represent facts that have happened. They are past tense, immutable, and form the authoritative record of state changes. We define them as a sealed interface — this ensures the compiler verifies that every event type is handled:

```java
public sealed interface StatementEvent {

    @TypeName("statement-created")
    record StatementCreated(
        String statementId,
        String accountId,
        String periodStart,
        String periodEnd,
        double totalDebits,
        double totalCredits,
        List<Transaction> transactions
    ) implements StatementEvent {}

    @TypeName("transaction-added")
    record TransactionAdded(
        Transaction transaction
    ) implements StatementEvent {}
}
```

Two design choices here are worth pausing on, because they address a problem that haunts every long-lived system: schema evolution.

The `@TypeName` annotation decouples the serialized event name from the Java class name. When an event is persisted, `"statement-created"` is stored in the journal, not `com.example.StatementEvent.StatementCreated`. This means you can refactor your code — rename classes, move packages, restructure modules — without breaking event deserialization. Events that were persisted months ago will still replay correctly. The `@TypeName` is the durable contract; the Java class is just the current interpretation.

The `sealed interface` ensures the compiler verifies that every event type is handled. When you add a new event to the system six months from now, every `switch` statement that processes events will fail to compile until you handle the new case. This is not optional type safety — it is an architectural guarantee. In a traditional system, adding a new column or a new message type is a prayer that every consumer will notice. With sealed events, it is a compile error.

Together, these two features — stable serialized names and exhaustive compile-time checks — make events a more reliable contract than a database schema or an API specification. The schema can drift. The API spec can lie. But the events are immutable facts with enforced handling. This is what makes event sourcing viable for systems that need to evolve over years, not months.

### The EventSourcedEntity

The entity is where commands are validated, events are emitted, and state transitions are defined. Here is the complete `StatementEntity`:

```java
@Component(id = "statement")
public class StatementEntity extends EventSourcedEntity<Statement, StatementEvent> {

    public ReadOnlyEffect<Statement> getStatement() {
        if (currentState() == null) {
            return effects().error("No statement found for id '"
                + commandContext().entityId() + "'");
        }
        return effects().reply(currentState());
    }

    public Effect<Done> create(Statement statement) {
        if (currentState() != null) {
            return effects().reply(done());
        }
        return effects()
            .persist(new StatementCreated(
                statement.statementId(),
                statement.accountId(),
                statement.periodStart(),
                statement.periodEnd(),
                statement.totalDebits(),
                statement.totalCredits(),
                statement.transactions()))
            .thenReply(__ -> done());
    }

    public Effect<Done> addTransaction(Transaction transaction) {
        if (currentState() == null) {
            return effects().error("Statement '"
                + commandContext().entityId() + "' does not exist");
        }
        return effects()
            .persist(new TransactionAdded(transaction))
            .thenReply(__ -> done());
    }

    @Override
    public Statement applyEvent(StatementEvent event) {
        return switch (event) {
            case StatementCreated created -> new Statement(
                created.statementId(),
                created.accountId(),
                created.periodStart(),
                created.periodEnd(),
                created.totalDebits(),
                created.totalCredits(),
                created.transactions()
            );
            case TransactionAdded added -> {
                var updatedTxns = new ArrayList<>(currentState().transactions());
                updatedTxns.add(added.transaction());
                yield new Statement(
                    currentState().statementId(),
                    currentState().accountId(),
                    currentState().periodStart(),
                    currentState().periodEnd(),
                    currentState().totalDebits() + added.transaction().amount(),
                    currentState().totalCredits(),
                    updatedTxns
                );
            }
        };
    }
}
```

Several patterns are worth noting here:

**Idempotent command handling** — The `create` method checks `currentState() != null` before persisting. If the entity already exists, it returns success without emitting any events. This is critical in distributed systems where messages may be delivered more than once.

**Command validation before persistence** — The `addTransaction` method verifies the statement exists before accepting the transaction. Commands are the gateway — they enforce business rules before any event is committed.

**Pure event application** — The `applyEvent` method is a pure function. It takes the current state and an event, and returns the next state. No side effects, no I/O, no exceptions. This function is called both during command processing (to update in-memory state) and during recovery (to rebuild state from the event journal). Its purity guarantees that replaying events always produces the same result.

**Sealed switch exhaustiveness** — The `switch` over `StatementEvent` is exhaustive because the interface is sealed. If you add a new event type and forget to handle it here, the compiler will catch it.

## Immutability Everywhere

Immutability is not a coding style preference. In a distributed system, it is an architectural requirement.

Java records enforce immutability by language design. There is no `setBalance()`. There is no `addTransaction()` that mutates a list. Every state change produces a new instance. The `Statement` record, the `Transaction` record, the `StatementCreated` event — all are immutable values that, once created, can never be changed.

This matters in distributed systems for reasons that go beyond thread safety:

**Safe to replicate.** An immutable event means the same thing in every region, on every replica, at every point in time. You do not need transformation logic, conflict resolution, or version negotiation. The event is a fact; facts do not change.

**Safe to cache.** An immutable object never becomes stale. If you cache a `Statement` record, you know it will never be silently mutated by another thread or process. Cache invalidation — one of the hardest problems in computer science — becomes trivial when the cached objects are immutable.

**Safe to log.** The object you logged is the object that existed. There is no race condition between logging a value and that value being mutated. Your debug output is a faithful record.

**No defensive copying.** When you pass an immutable record across a thread boundary, you do not need to copy it. The record is safe to share because it cannot change. This eliminates an entire class of performance overhead and concurrency bugs.

Sealed interfaces extend this safety from values to types. The `sealed interface StatementEvent` declares that the only possible event types are `StatementCreated` and `TransactionAdded`. The `switch` in `applyEvent` is exhaustive:

```java
return switch (event) {
    case StatementCreated created -> // handle creation
    case TransactionAdded added -> // handle transaction
};
```

When you add `TransactionReversed` to `StatementEvent` six months from now, every `switch` statement in the codebase fails to compile. This is not optional safety — it is an architectural guarantee that no event goes unhandled. In a traditional system, adding a new message type is a prayer that every consumer will notice. With sealed events, it is a compiler error.

Together — immutable records for values, sealed interfaces for types — the Java type system becomes an enforcement mechanism for architectural invariants. The system does not *prevent* bugs at runtime; it prevents entire *categories* of bugs at compile time.

## Idempotent Command Handling

In distributed systems, messages may be delivered more than once. Network timeouts cause retries. Load balancers reroute requests. Failovers replay in-flight commands. If your command handler is not idempotent, every retry is a potential data corruption.

The `StatementEntity.create` method demonstrates the pattern:

```java
public Effect<Done> create(Statement statement) {
    if (currentState() != null) {
        return effects().reply(done());  // Idempotent: no event, same reply
    }
    return effects()
        .persist(new StatementCreated(/* ... */))
        .thenReply(__ -> done());
}
```

The first call to `create` persists a `StatementCreated` event and returns `Done`. The second call detects that the entity already exists (via `currentState() != null`), returns the same `Done` response, and emits **zero events**. The caller cannot distinguish between "created" and "already existed." This is intentional.

This is different from defensive programming. Defensive programming catches errors and fails loudly — "entity already exists, 409 Conflict." Idempotent design succeeds silently. The second call is not an error; it is a successful no-op. This distinction matters because the caller may not know whether it is retrying. A load balancer timeout, a network hiccup, a process restart — any of these can cause a command to be delivered twice. If the handler is idempotent, the retry is free. If it is not, the retry is a bug.

The `ProductEntity` follows the same pattern:

```java
public Effect<Done> create(Product product) {
    if (isActive()) {
        return effects().reply(done());  // Already exists and active
    }
    // ... persist ProductCreated
}
```

Testing idempotency explicitly is not optional — it is an architectural requirement verified by test:

```java
// First create: emits StatementCreated event
var result = testKit.method(StatementEntity::create).invoke(statement);
assertEquals(done(), result.getReply());
assertFalse(result.getAllEvents().isEmpty());

// Second create: success, but zero events emitted
var duplicate = testKit.method(StatementEntity::create).invoke(statement);
assertEquals(done(), duplicate.getReply());
assertTrue(duplicate.getAllEvents().isEmpty());  // No new events!
```

Idempotency enables retry-safety. Retry-safety enables resilience. If every command handler is idempotent, the platform can retry failed requests, reroute commands after failovers, and replay in-flight operations during partition recovery — all without risking data corruption. This is not a nice-to-have; it is the property that makes the resilience story in [Part 5]({{< ref "/blog/akka/platform-internals-multi-region-resilience" >}}) possible.

## The Product Service: Tombstone Deletes

The product-service demonstrates a different challenge: how do you handle deletes in an event-sourced system?

In Akka SDK, the `applyEvent` method **must never return null**. This is a deliberate constraint — returning null would mean the entity's state disappears, but the events that created it still exist in the journal. Replaying those events would resurrect the entity, creating an inconsistency.

The solution is the **tombstone delete pattern**: instead of removing the entity, you mark it as deleted with a boolean flag in the state.

### The Product Record

```java
public record Product(
    String productId,
    String productName,
    String category,
    String description,
    String eligibility,
    @JsonIgnore boolean deleted
) {
    // Convenience constructor, defaults deleted to false
    public Product(String productId, String productName, String category,
                   String description, String eligibility) {
        this(productId, productName, category, description, eligibility, false);
    }
}
```

The `@JsonIgnore` on `deleted` ensures this internal field never leaks into API responses. Consumers see a clean product record; the deletion state is an internal concern.

### Events with Delete

```java
public sealed interface ProductEvent {
    @TypeName("product-created")
    record ProductCreated(String productId, String productName,
        String category, String description, String eligibility
    ) implements ProductEvent {}

    @TypeName("product-updated")
    record ProductUpdated(String productName, String category,
        String description, String eligibility
    ) implements ProductEvent {}

    @TypeName("product-deleted")
    record ProductDeleted() implements ProductEvent {}
}
```

The `ProductDeleted` event carries no data — it is a pure signal. The entity ID is implicit from the entity context.

### The Entity with Tombstone

```java
@Component(id = "product")
public class ProductEntity extends EventSourcedEntity<Product, ProductEvent> {

    private boolean isActive() {
        return currentState() != null && !currentState().deleted();
    }

    public ReadOnlyEffect<Product> getProduct() {
        if (!isActive()) {
            return effects().error("No product found for id '"
                + commandContext().entityId() + "'");
        }
        return effects().reply(currentState());
    }

    public Effect<Done> create(Product product) {
        if (isActive()) {
            return effects().reply(done());
        }
        return effects()
            .persist(new ProductCreated(product.productId(),
                product.productName(), product.category(),
                product.description(), product.eligibility()))
            .thenReply(__ -> done());
    }

    public Effect<Done> delete() {
        if (!isActive()) {
            return effects().error("Product '"
                + commandContext().entityId() + "' does not exist");
        }
        return effects()
            .persist(new ProductDeleted())
            .thenReply(__ -> done());
    }

    @Override
    public Product applyEvent(ProductEvent event) {
        return switch (event) {
            case ProductCreated c -> new Product(c.productId(),
                c.productName(), c.category(),
                c.description(), c.eligibility());
            case ProductUpdated u -> new Product(
                currentState().productId(), u.productName(),
                u.category(), u.description(), u.eligibility());
            case ProductDeleted d -> new Product(
                currentState().productId(),
                currentState().productName(),
                currentState().category(),
                currentState().description(),
                currentState().eligibility(),
                true  // tombstone!
            );
        };
    }
}
```

The `isActive()` helper encapsulates the tombstone check. Every command handler gates on `isActive()` — a deleted product cannot be read, updated, or deleted again. But the state still exists in memory and in the event journal. If you ever need to "undelete" a product, you can add a `ProductReactivated` event that sets `deleted` back to `false`.

The append-only model matters for resilience beyond the individual entity. If the event journal is append-only, it can be replicated without conflict. A `ProductDeleted` event in Region A and a `ProductUpdated` event in Region B are both appends — they do not conflict. The append-only model is what makes multi-region replication possible, as we will explore in [Part 5]({{< ref "/blog/akka/platform-internals-multi-region-resilience" >}}).

![Product Service Architecture](images/product-service-architecture.png)

## The HTTP Endpoint Layer

Akka SDK endpoints are thin HTTP controllers that delegate to entities and views via the `ComponentClient`:

```java
@Acl(allow = @Acl.Matcher(principal = Acl.Principal.ALL))
@HttpEndpoint("/products")
public class ProductEndpoint extends AbstractHttpEndpoint {

    private final ComponentClient componentClient;

    public ProductEndpoint(ComponentClient componentClient) {
        this.componentClient = componentClient;
    }

    @Post("/{productId}")
    public HttpResponse create(String productId, Product product) {
        componentClient
            .forEventSourcedEntity(productId)
            .method(ProductEntity::create)
            .invoke(product);
        return HttpResponses.created();
    }

    @Get("/{productId}")
    public Product getProduct(String productId) {
        return componentClient
            .forEventSourcedEntity(productId)
            .method(ProductEntity::getProduct)
            .invoke();
    }

    @Delete("/{productId}")
    public HttpResponse delete(String productId) {
        componentClient
            .forEventSourcedEntity(productId)
            .method(ProductEntity::delete)
            .invoke();
        return HttpResponses.ok();
    }
}
```

The `ComponentClient` is Akka's internal routing mechanism. When you call `forEventSourcedEntity(productId)`, the runtime routes the request to the correct entity instance — which might be on this node or on another node in the cluster. The routing is transparent; the endpoint code does not know or care where the entity lives.

The `@Acl` annotation controls access. `Acl.Principal.ALL` opens the endpoint to all callers; in production you would restrict this to `Acl.Principal.INTERNET` with authentication, or to specific service principals for internal APIs.

## Testing Event-Sourced Entities

Akka SDK provides an `EventSourcedTestKit` that simulates the full entity lifecycle — command handling, event persistence, state recovery — all in-memory. No Docker, no database, no test containers. Tests run in milliseconds.

This is a direct consequence of event sourcing: because state is derived from events through a pure function, you can test the function without infrastructure.

### Testing the Happy Path

```java
var testKit = EventSourcedTestKit.of(StatementEntity::new);

// Create a statement
var statement = new Statement("stmt-1", "acc-1001",
    "2025-12-01", "2025-12-31", 500.0, 0.0, List.of());
EventSourcedResult<Done> result = testKit
    .method(StatementEntity::create)
    .invoke(statement);

assertEquals(done(), result.getReply());
StatementCreated event = result.getNextEventOfType(StatementCreated.class);
assertEquals("stmt-1", event.statementId());
```

### Testing Idempotency

```java
// First create succeeds with events
var result = testKit.method(StatementEntity::create).invoke(statement);
assertFalse(result.getAllEvents().isEmpty());

// Second create: success, but zero events emitted
var duplicate = testKit.method(StatementEntity::create).invoke(statement);
assertEquals(done(), duplicate.getReply());
assertTrue(duplicate.getAllEvents().isEmpty());  // No new events!
```

Every entity has an explicit idempotency test. This is not optional — it is an architectural requirement verified by test.

### Testing Precondition Guards

```java
// Adding a transaction to a non-existent statement → error
var testKit = EventSourcedTestKit.of(StatementEntity::new);
var transaction = new Transaction("txn-1", "2025-12-15",
    "Coffee Shop", 4.50, "Food", "Morning coffee");

var result = testKit
    .method(StatementEntity::addTransaction)
    .invoke(transaction);

assertTrue(result.isError());
```

### Testing State Accumulation

```java
// Create statement, then add multiple transactions
testKit.method(StatementEntity::create).invoke(statement);

var txn1 = new Transaction("txn-1", "2025-12-15", "Coffee", 4.50, "Food", "Coffee");
var txn2 = new Transaction("txn-2", "2025-12-16", "Gas", 45.00, "Transport", "Gas");

testKit.method(StatementEntity::addTransaction).invoke(txn1);
testKit.method(StatementEntity::addTransaction).invoke(txn2);

var state = testKit.method(StatementEntity::getStatement).invoke().getReply();
assertEquals(2, state.transactions().size());
assertEquals(549.50, state.totalDebits(), 0.01);  // 500.0 + 4.50 + 45.00
```

### Testing the Tombstone Lifecycle

```java
var productKit = EventSourcedTestKit.of(ProductEntity::new);
var product = new Product("prod-1", "Savings Account",
    "Savings", "High-yield savings", "Min balance $500");

// Create → active
productKit.method(ProductEntity::create).invoke(product);
assertFalse(productKit.method(ProductEntity::getProduct).invoke().isError());

// Delete → tombstoned
productKit.method(ProductEntity::delete).invoke();
assertTrue(productKit.method(ProductEntity::getProduct).invoke().isError());

// Attempting delete on already-deleted product → error
assertTrue(productKit.method(ProductEntity::delete).invoke().isError());
```

The test kit covers the full lifecycle without starting any runtime. This is the testing ergonomics that event sourcing produces as a byproduct: because the core logic is a pure function over events, it is testable without infrastructure.

## What These Foundations Enable

The patterns in this post — event sourcing, sealed events, immutability, tombstone deletes, idempotent commands — are not isolated techniques. They are the foundation that makes everything in the rest of this series possible.

In [Part 2]({{< ref "/blog/akka/views-cqrs-read-write-optimization" >}}), we build read-optimized projections that consume these events. `StatementsByAccountView` and `AllProductsView` demonstrate how CQRS separates read and write concerns, enabling independent optimization of each path. The views are eventually consistent with the entities — when an event is persisted, the view processes it asynchronously.

In [Part 3]({{< ref "/blog/akka/cross-service-communication-agentic-ai" >}}), we wire services together using `HttpClientProvider` — platform-managed service discovery by name, no URLs, no configuration. The same event-driven architecture enables an LLM-powered Akka Agent that uses function tools to orchestrate services.

In [Part 4]({{< ref "/blog/akka/deployment-resilience-multi-region" >}}), we deploy to the Akka Platform and discover that the same code works in production without configuration changes.

In [Part 5]({{< ref "/blog/akka/platform-internals-multi-region-resilience" >}}), we discover that the properties established here — immutability, idempotency, pure event application — are exactly what multi-region replication requires. Events can be replicated across regions without transformation. Idempotent commands can be safely retried after failovers. Pure state derivation means replaying events in any region produces the same result.

The architectural choices compound. The immutability established here is not a local optimization — it is the property that makes distribution, replication, and independent deployment viable at every layer of the stack.

The [complete source code](https://github.com/PradeepLoganathan/microsvs-microapp) is available on GitHub.
