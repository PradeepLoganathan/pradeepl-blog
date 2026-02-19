---
title: "Building Resilient Microservices with Akka — Part 1: Event Sourcing & CQRS"
lastmod: 2026-02-18T16:00:00+10:00
date: 2026-02-18T16:00:00+10:00
draft: true
Author: Pradeep Loganathan
tags:
  - akka
  - microservices
  - event-sourcing
  - cqrs
  - java
  - distributed-systems
categories:
  - akka
  - architecture
description: "How to build immutable, event-sourced microservices with CQRS using Akka SDK — with practical patterns for entities, views, and soft deletes from a banking demo."
summary: "Build immutable, event-sourced microservices with CQRS using Akka SDK — practical patterns for entities, views, tombstone deletes, and idempotent command handling from a banking demo."
ShowToc: true
TocOpen: true
images:
  - "images/cover.png"
cover:
  image: "images/cover.png"
  alt: "Event Sourcing and CQRS with Akka SDK"
  caption: "Building immutable, event-sourced microservices with Akka SDK"
  relative: true
series: ["Building Resilient Microservices with Akka"]
---

In the [introduction to this series]({{< ref "/blog/akka/beyond-crud-event-native-microservices" >}}), we argued that most microservice architectures carry a fundamental error: they treat mutable database rows as the source of truth, destroying history with every UPDATE statement. We proposed a correction — event sourcing, where state is a derived value computed from an immutable log of facts.

This post puts that argument into practice. We will build two event-sourced services using the **Akka SDK**, and in the process, encounter the patterns that make event sourcing not just theoretically sound but practically powerful: CQRS for separating reads from writes, sealed event interfaces for type-safe evolution, tombstone deletes for handling deletion in an append-only world, and idempotent command handling for surviving the realities of distributed message delivery.

The complete source code for this series is available on [GitHub](https://github.com/PradeepLoganathan/microsvs-microapp). The demo comprises four backend microservices — statement-service, analysis-service, recommendation-service, and product-service — that together form a banking platform capable of analyzing customer spending and recommending financial products.

![Statement Service Architecture](images/statement-service-architecture.png)

## Why Event Sourcing for Microservices?

Traditional CRUD services store the current state of an entity. When a customer's account balance changes, the old value is overwritten. This seems simple, but it introduces subtle problems in distributed systems:

- **Lost history** — You cannot reconstruct how the system reached its current state. Debugging production issues becomes archaeological guesswork.
- **Conflicting writes** — Two services updating the same row create race conditions that are notoriously difficult to resolve.
- **Tight coupling to schema** — Every consumer reads the same mutable record, making independent evolution painful.
- **No natural audit trail** — Compliance and debugging require bolted-on audit logging that inevitably drifts from reality.

Event sourcing inverts this model. Instead of storing current state, we store the sequence of events that produced it. The current state is a derived value — a left fold over the event log.

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

The `@TypeName` annotation decouples the serialized event name from the Java class name. When an event is persisted, `"statement-created"` is stored in the journal — not `com.example.StatementEvent.StatementCreated`. This means you can refactor your code — rename classes, move packages, restructure modules — without breaking event deserialization. Events that were persisted months ago will still replay correctly. The `@TypeName` is the durable contract; the Java class is just the current interpretation.

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

**Idempotent command handling** — The `create` method checks `currentState() != null` before persisting. If the entity already exists, it returns success without emitting any events. This is critical in distributed systems where messages may be delivered more than once. The caller sees success either way, but the event log remains clean.

**Command validation before persistence** — The `addTransaction` method verifies the statement exists before accepting the transaction. Commands are the gateway — they enforce business rules before any event is committed.

**Pure event application** — The `applyEvent` method is a pure function. It takes the current state and an event, and returns the next state. No side effects, no I/O, no exceptions. This function is called both during command processing (to update in-memory state) and during recovery (to rebuild state from the event journal). Its purity guarantees that replaying events always produces the same result.

**Sealed switch exhaustiveness** — The `switch` over `StatementEvent` is exhaustive because the interface is sealed. If you add a new event type and forget to handle it here, the compiler will catch it.

### Testing with EventSourcedTestKit

Akka SDK provides an `EventSourcedTestKit` that lets you test entity behavior without starting the runtime:

```java
var testKit = EventSourcedTestKit.of(StatementEntity::new);

// Test creating a statement
var statement = new Statement("stmt-1", "acc-1001",
    "2025-12-01", "2025-12-31", 500.0, 0.0, List.of());
EventSourcedResult<Done> result = testKit
    .method(StatementEntity::create)
    .invoke(statement);

assertEquals(done(), result.getReply());
StatementCreated event = result.getNextEventOfType(StatementCreated.class);
assertEquals("stmt-1", event.statementId());

// Test idempotent create
EventSourcedResult<Done> duplicate = testKit
    .method(StatementEntity::create)
    .invoke(statement);
assertEquals(done(), duplicate.getReply());
assertTrue(duplicate.getAllEvents().isEmpty()); // No new events!
```

The test kit simulates the full entity lifecycle — command handling, event persistence, state recovery — all in-memory. You can verify that the correct events are emitted, that the state is updated correctly, and that idempotent operations produce no duplicate events.

## CQRS: Separating Reads from Writes

Event sourcing naturally leads to CQRS (Command Query Responsibility Segregation), and understanding why reveals something important about the nature of data in distributed systems.

Writes and reads are fundamentally different operations with different requirements. Writes capture *what happened* — they must be consistent, validated, and durable. Reads answer *questions* — they must be fast, flexible, and shaped for the consumer's needs. In a CRUD architecture, both concerns are forced through the same path: the same table, the same schema, the same database. This is a forced compromise. The schema optimized for writes (normalized, integrity-constrained) is rarely the shape that reads need (denormalized, query-optimized). Adding an index for a new query pattern can slow down writes. Changing the schema for a write requirement can break existing reads.

CQRS eliminates this compromise by separating the two concerns entirely. The event-sourced entity is optimized for writes — it handles commands and persists events. The **View** is optimized for reads — it consumes events and maintains a purpose-built projection.

In Akka SDK, Views consume events from one or more entities and maintain read-optimized projections. A View is eventually consistent with the entity — when an event is persisted, the View processes it asynchronously to update its query table. You can have multiple Views over the same event stream, each shaped for a different query pattern, each independently deployable and rebuildable.

### The StatementsByAccountView

The statement-service needs to list all statements for a given account. The entity is keyed by `statementId`, so there is no built-in way to query by `accountId`. The View provides this:

```java
@Component(id = "statements-by-account")
public class StatementsByAccountView extends View {

    @Consume.FromEventSourcedEntity(StatementEntity.class)
    public static class StatementSummaryUpdater extends TableUpdater<StatementSummary> {

        public Effect<StatementSummary> onEvent(StatementEvent event) {
            return switch (event) {
                case StatementCreated created -> {
                    yield effects().updateRow(new StatementSummary(
                        created.statementId(),
                        created.accountId(),
                        created.periodStart(),
                        created.periodEnd(),
                        created.totalDebits(),
                        created.transactions().size()
                    ));
                }
                case TransactionAdded added -> {
                    var current = rowState();
                    yield effects().updateRow(new StatementSummary(
                        current.statementId(),
                        current.accountId(),
                        current.periodStart(),
                        current.periodEnd(),
                        current.totalDebits() + added.transaction().amount(),
                        current.transactionCount() + 1
                    ));
                }
            };
        }
    }

    @Query("SELECT * AS statements FROM statements_by_account WHERE accountId = :accountId")
    public QueryEffect<StatementSummaries> getByAccount(String accountId) {
        return queryResult();
    }
}
```

The `@Consume.FromEventSourcedEntity` annotation wires the View to the entity's event stream. Every event persisted by any `StatementEntity` instance flows into this updater. The `StatementSummary` projection contains only what the read side needs — no full transaction lists, just counts and totals.

The `@Query` method defines a SQL-like query over the View's table. The Akka runtime manages the underlying storage, indexing, and query execution.

This is CQRS in its purest form:

- **Write side** (Entity): Validates commands, persists events, maintains authoritative state
- **Read side** (View): Consumes events, maintains denormalized projections, serves queries

The two sides are decoupled. You can add new Views without modifying the entity. You can rebuild a View from scratch by replaying events. If a View's schema needs to change, you deploy the new version and let it catch up from the event journal.

### Testing Views with Awaitility

Views are eventually consistent, which means testing them requires patience:

```java
// Seed data via the entity
httpClient.POST("/accounts/seed").invoke();

// Wait for the View to catch up
Awaitility.await()
    .ignoreExceptions()
    .atMost(20, TimeUnit.SECONDS)
    .untilAsserted(() -> {
        var result = componentClient.forView()
            .method(StatementsByAccountView::getByAccount)
            .invoke("acc-1001");
        assertThat(result.statements()).hasSize(3);
    });
```

The `Awaitility` library polls until the assertion passes or the timeout expires. This is the standard pattern for testing eventually consistent projections — you cannot assert immediately after a write.

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
    // Convenience constructor — defaults deleted to false
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

The `isActive()` helper encapsulates the tombstone check. Every command handler gates on `isActive()` — a deleted product cannot be read, updated, or deleted again. But the state still exists in memory and in the event journal. If you ever need to "undelete" a product, you can add an `ProductReactivated` event that sets `deleted` back to `false`.

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

## Patterns and Principles

Looking across the statement-service and product-service, several patterns emerge that are worth codifying:

**Immutability everywhere** — Domain records are Java records (immutable by default). Events are immutable records. State transitions create new state instances. There is no `setState()` or mutable field anywhere. This eliminates an entire class of concurrency bugs.

**Events are the contract** — The `@TypeName` annotation makes events the durable contract. Code can be refactored, classes renamed, packages reorganized. As long as the event type names and their serialized shapes remain compatible, the system works. This is a much more stable contract than a database schema.

**Commands are validated, events are trusted** — Command handlers check preconditions (`isActive()`, `currentState() != null`) and reject invalid requests. Event handlers (`applyEvent`) assume the event is valid — it was already validated when the command was accepted. This separation keeps event application simple and deterministic.

**Sealed interfaces for exhaustiveness** — Using sealed interfaces for events means the compiler catches unhandled event types. When you add a new event to the system, every `switch` statement that handles events will fail to compile until you add the new case. This is a powerful safety net during evolution.

**Idempotency by design** — The `create` methods check for existing state and return success without emitting events. This is not defensive programming — it is a design requirement. In distributed systems, at-least-once delivery is common, and idempotent handlers ensure that retries do not corrupt state.

## What These Foundations Enable

The patterns in this post — event sourcing, CQRS, sealed events, tombstone deletes, idempotent commands — are not isolated techniques. They are the foundation that makes everything in the rest of this series possible:

**Cross-service communication without shared state** — Because each entity owns its event stream and state is never shared through a database, services can communicate through well-defined APIs without hidden coupling. In [Part 2]({{< ref "/blog/akka/cross-service-communication-agentic-ai" >}}), the analysis-service will call the statement-service using `HttpClientProvider` — platform-managed service discovery by name, no URLs, no configuration. The same event-driven architecture also enables an LLM-powered Akka Agent that uses function tools to orchestrate services, demonstrating AI as a peer component rather than a bolt-on layer.

**Fearless deployment and multi-region replication** — Because state is derived from events through a pure fold, deploying a new version of a service does not require data migration. The new code replays the same events and builds its own state. This same property enables multi-region replication: events replicated to another region are applied by the same fold to produce consistent state. In [Part 3]({{< ref "/blog/akka/deployment-resilience-multi-region" >}}), we will deploy to the Akka Platform and explore how entity distribution, failure recovery, and global replication all rest on the event journal we built here.

**Frontend independence** — Because the backend services are truly independent — no shared database, no coordinated releases — the frontend can be decomposed to match. In [Part 4]({{< ref "/blog/akka/micro-frontends-independently-deployable" >}}), we build micro-frontends as Web Components loaded from a manifest, completing the independence story from event journal to UI pixel.

The architectural choices compound. The immutability established here is not a local optimization — it is the property that makes distribution, replication, and independent deployment viable at every layer of the stack.

The [complete source code](https://github.com/PradeepLoganathan/microsvs-microapp) is available on GitHub.
