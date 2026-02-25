---
title: "Building Resilient Microservices with Akka — Part 2: Views, CQRS & the Art of Optimizing Reads and Writes"
date: 2026-02-19T10:00:00+10:00
draft: true
Author: Pradeep Loganathan
tags:
  - akka
  - microservices
  - cqrs
  - event-sourcing
  - views
  - distributed-systems
  - java
categories:
  - akka
  - architecture
description: "Why reads and writes are fundamentally different concerns, how CQRS separates them, and how Akka Views create read-optimized projections from event streams — with patterns for denormalization, eventual consistency, and retroactive queries."
summary: "Separate reads from writes with CQRS and Akka Views — materialized projections from event streams, denormalization strategies, eventually consistent reads, retroactive projections, and the patterns that make read and write performance independently optimizable."
ShowToc: true
TocOpen: true
images:
  - "images/cover.png"
cover:
  image: "images/cover.png"
  alt: "CQRS and Views with Akka SDK"
  caption: "Optimizing reads and writes independently with CQRS and materialized views"
  relative: true
series: ["Building Resilient Microservices with Akka"]
weight: 3
---

{{< series-toc >}}

In [Part 1]({{< ref "/blog/akka/event-sourcing-cqrs-with-akka" >}}), we built entities optimized for writes — append-only events, sequential processing, single-writer per entity. Every command is validated, every state change is an immutable event, and the entity's state is a pure left fold over its event log.

But writes are only half the story. Your entity is keyed by `statementId`. But your user wants to see all statements for `accountId`. Your product catalog is keyed by `productId`. But your search page needs products filtered by category. The write model's key is not the read model's query.

This is not a shortcoming of event sourcing — it is the insight that leads to CQRS. Reads and writes have fundamentally different requirements. Trying to serve both through the same model forces a compromise that serves neither concern well. CQRS separates the concerns. Akka Views provide the read-side implementation. Together, they allow independent optimization of reads and writes — different schemas, different scaling strategies, different performance characteristics, each tuned for its purpose.

## The Read/Write Impedance Mismatch

Writes and reads are different operations with different requirements, and most architectures pretend otherwise.

**Writes capture what happened.** Commands are validated, events are persisted. The write path must be consistent, durable, and ordered. It is optimized for correctness. In our banking demo, writing a transaction means validating the statement exists, persisting a `TransactionAdded` event, and updating the entity's in-memory state. The entity is keyed by `statementId` because that is the natural unit of consistency — one statement, one event stream, no contention.

**Reads answer questions.** Queries retrieve shaped data for a consumer. The read path must be fast, flexible, and shaped for the use case. It is optimized for access patterns. The account overview page does not care about individual entity streams. It needs all statements for a given account, summarized as period dates, total debits, and transaction counts. No full transaction lists. No event replay. Just a table lookup.

**CRUD conflates them.** In a traditional architecture, a single table schema must serve both concerns. Normalize for write integrity? Reads require joins. Denormalize for read speed? Writes must update multiple locations. Add an index for a new query pattern? Write performance degrades. The more you optimize for one concern, the worse the other becomes.

This is the performance tax that most teams pay without realizing it. In a CRUD system, every read pays for write integrity (joins, normalization), and every write pays for read performance (index maintenance, denormalization updates). Neither concern is served well. The compromise is invisible until you profile — and then you discover that the database is spending more time maintaining indexes for read queries than it spends processing the writes themselves.

In our banking demo, the statement entity is keyed by `statementId` — write-optimized, one entity per statement, sequential processing, no contention. But the account overview page needs all statements for an account — read-optimized, query by `accountId`, return summaries. These are different access patterns with different performance requirements. CQRS recognizes this mismatch and eliminates it.

## CQRS: Separate the Models

CQRS — Command Query Responsibility Segregation — separates the write model (entities) from the read model (views/projections).

The entity handles commands and persists events. It is optimized for consistency and durability: validate the command, emit events, apply the fold. The write path is simple, fast, and correct.

The view consumes events and maintains a read-optimized projection. It is optimized for query performance: denormalized tables, pre-computed aggregates, purpose-built indexes. The read path is a table lookup — no joins, no event replay.

This separation produces three important properties:

**Independent optimization.** Add indexes to views without affecting entity write performance. Change view schema without touching entity code. Tune read and write paths separately, because they *are* separate.

**Multiple views per entity.** The same `StatementEntity` event stream can feed a `StatementsByAccountView`, a `MonthlyAggregateView`, a `MerchantFrequencyView`, and a `CategoryBreakdownView`. Each view answers a different question. Each is independently deployable and rebuildable.

**Independent scaling.** Scale read replicas without scaling write replicas. Scale writes without scaling reads. A spike in read traffic does not slow down write processing, because they share no storage, no locks, no connection pool.

CQRS is not an optimization technique. It is a recognition that reads and writes are different architectural concerns with different requirements, and forcing them through the same model creates unnecessary compromise.

## Akka Views: Materialized Projections from Event Streams

A View in Akka SDK is a component that subscribes to an entity's event stream and maintains a read-optimized table.

The mechanism is straightforward:

1. The View subscribes to an entity's events via `@Consume.FromEventSourcedEntity`
2. Each event flows through a `TableUpdater`, which transforms the event into a table row operation
3. Queries are exposed via `@Query` annotations with SQL-like syntax

The View is eventually consistent — events are processed asynchronously after they are persisted by the entity. There is a window, typically milliseconds, where the entity reflects a new event but the view does not. This is the right trade-off: synchronous consistency would couple the write path to the read path, meaning a slow view could stall entity processing.

The View's table is managed by the Akka runtime — no external database to provision, no connection pool to configure, no schema migration to manage. If a View's schema needs to change, deploy the new version. The runtime replays the full event history to rebuild the table. No data migration. No SQL ALTER TABLE. The events are the schema.

A View is a materialized question. You define the question ("what are the statements for this account?"), and the runtime maintains the answer as events flow in.

## The StatementsByAccountView

The statement-service needs to list all statements for a given account. The entity is keyed by `statementId`, so there is no built-in way to query by `accountId`. The View provides this:

```java
@Component(id = "statements-by-account")
public class StatementsByAccountView extends View {

    private static final Logger logger = LoggerFactory.getLogger(StatementsByAccountView.class);

    @Consume.FromEventSourcedEntity(StatementEntity.class)
    public static class StatementSummaryUpdater extends TableUpdater<StatementSummary> {

        public Effect<StatementSummary> onEvent(StatementEvent event) {
            return switch (event) {
                case StatementCreated created -> {
                    logger.info("View indexing statement '{}' for account '{}'",
                        created.statementId(), created.accountId());
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
                    logger.info("View updating statement '{}' with new transaction '{}'",
                        current.statementId(), added.transaction().id());
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

The `@Consume.FromEventSourcedEntity` annotation wires the View to the entity's event stream. Every event persisted by any `StatementEntity` instance flows into this updater.

Walk through the event handling:

- **`StatementCreated`** initializes the view row. The `StatementSummary` projection contains only what the read side needs — no full transaction lists, just the statement ID, account ID, period dates, total debits, and transaction count. The entity stores everything; the view stores only what this query needs.

- **`TransactionAdded`** updates the existing row. The `rowState()` method retrieves the current view row, and we create a new `StatementSummary` with the incremented totals and count. No need to read from the entity — the view maintains its own state, updated incrementally with each event.

The `@Query` method defines a SQL-like query over the View's table. `SELECT * AS statements FROM statements_by_account WHERE accountId = :accountId` returns all statement summaries for a given account. The Akka runtime manages the underlying storage, indexing, and query execution.

This is denormalization by design. The view's table has each row containing the account ID, statement ID, period dates, total debits, and transaction count. No joins. No event replay on read. The read path is a simple table lookup.

## The AllProductsView: Filtering and Lifecycle

The product-service needs to list all *active* products. The `AllProductsView` demonstrates how views handle the full entity lifecycle — including deletion:

```java
@Component(id = "all-products")
public class AllProductsView extends View {

    private static final Logger logger = LoggerFactory.getLogger(AllProductsView.class);

    @Consume.FromEventSourcedEntity(ProductEntity.class)
    public static class ProductTableUpdater extends TableUpdater<ProductSummary> {

        public Effect<ProductSummary> onEvent(ProductEvent event) {
            return switch (event) {
                case ProductCreated created -> {
                    logger.info("View indexing product '{}'", created.productId());
                    yield effects().updateRow(new ProductSummary(
                        created.productId(),
                        created.productName(),
                        created.category(),
                        created.description(),
                        created.eligibility()
                    ));
                }
                case ProductUpdated updated -> {
                    var current = rowState();
                    logger.info("View updating product '{}'", current.productId());
                    yield effects().updateRow(new ProductSummary(
                        current.productId(),
                        updated.productName(),
                        updated.category(),
                        updated.description(),
                        updated.eligibility()
                    ));
                }
                case ProductDeleted deleted -> {
                    logger.info("View removing product '{}'", rowState().productId());
                    yield effects().deleteRow();
                }
            };
        }
    }

    @Query("SELECT * AS products FROM all_products")
    public QueryEffect<ProductList> getAllProducts() {
        return queryResult();
    }
}
```

The delete handling is the most interesting part. When a `ProductDeleted` event arrives, the view calls `effects().deleteRow()` — removing the product from the read-side entirely.

Compare this with the entity's behavior from [Part 1]({{< ref "/blog/akka/event-sourcing-cqrs-with-akka" >}}). The entity keeps the tombstoned state — `deleted = true` — because the event journal is append-only and the entity must be able to reject subsequent commands on a deleted product. The view removes the row because the read side only needs to show *active* products.

Different concerns, different behaviors. The entity preserves the full lifecycle; the view reflects current reality. This is CQRS in action — the write side maintains history, and the read side maintains a purpose-built projection.

The `ProductUpdated` handler uses `rowState()` to preserve the `productId` from the existing view row. The update event carries the new name, category, description, and eligibility, but the product ID is immutable — it comes from the original `ProductCreated` event. The view preserves it from its own state rather than depending on the update event to carry it.

## Designing Views for Your Read Patterns

The key insight for designing views: start from the question, not from the entity schema.

Do not ask "what data does the entity have?" Ask "what questions does the application need to answer?"

- **Q: "What are the statements for account X?"** → `StatementsByAccountView` keyed on `accountId`
- **Q: "What are all active products?"** → `AllProductsView` with `deleteRow()` on deletion
- **Q: "What is the total spending by category this month?"** → A view that aggregates by category and period
- **Q: "Which merchants appear most frequently?"** → A view that counts merchant occurrences across statements

One entity can feed many views. The same `StatementEntity` event stream could feed a `StatementsByAccountView`, a `MonthlyAggregateView`, a `MerchantFrequencyView`, and a `CategoryBreakdownView`. Each view answers a different question. Each is independently deployable and rebuildable. Adding a new view does not require modifying the entity.

The view is not the entity's API. Entities receive commands and emit events. Views consume events and serve queries. They communicate through the event stream, not through code dependencies.

**When NOT to use a view:** If the query is by entity ID — "get statement `stmt-2025-12`" — use the entity directly via `ComponentClient.forEventSourcedEntity(id)`. The entity serves this lookup from memory. Views are for queries that span entities or use a different key than the entity ID.

## Eventually Consistent Projections

Views are eventually consistent with their source entities. When the entity persists a `TransactionAdded` event, the `StatementsByAccountView` does not update instantly. The event flows asynchronously to the view, which processes it and updates its table. There is a window — typically milliseconds — where the entity reflects the new transaction but the view does not.

Why is this acceptable? The alternative is synchronous consistency — the entity blocks until every view is updated. This creates tight coupling between write and read paths, hurts write performance, and means a slow or failing view can stall entity processing. The trade-off is clear: eventual consistency gives you independent performance and failure isolation. A broken view does not break writes.

### Testing Eventual Consistency with Awaitility

Testing eventually consistent projections requires a different pattern than testing synchronous operations. You cannot assert immediately after a write — you must wait for the view to catch up:

```java
// Create two statements for the same account
createViaEntity(stmtId1, new Statement(stmtId1, accountId, ...));
createViaEntity(stmtId2, new Statement(stmtId2, accountId, ...));

// Wait for the view to process the events
Awaitility.await()
    .ignoreExceptions()
    .atMost(20, TimeUnit.SECONDS)
    .untilAsserted(() -> {
        var summaries = componentClient.forView()
            .method(StatementsByAccountView::getByAccount)
            .invoke(accountId)
            .statements();
        assertThat(summaries).hasSize(2);
    });
```

The `Awaitility` library polls until the assertion passes or the timeout expires. You write the assertion you want, wrap it in `await()`, and the framework handles the polling. This makes async testing feel synchronous in the test code while respecting the eventually consistent nature of the system.

The integration tests from the sample project verify view behavior end-to-end — creating entities, adding transactions, and asserting that the view reflects the changes:

```java
// Add a transaction to an existing statement
componentClient.forEventSourcedEntity(stmtId)
    .method(StatementEntity::addTransaction)
    .invoke(new Transaction("txn-new", "2025-12-10", "Netflix", 15.99, "Entertainment", "Sub"));

// View should reflect the updated totals
Awaitility.await()
    .ignoreExceptions()
    .atMost(20, TimeUnit.SECONDS)
    .untilAsserted(() -> {
        var summary = componentClient.forView()
            .method(StatementsByAccountView::getByAccount)
            .invoke(accountId)
            .statements().iterator().next();
        assertThat(summary.transactionCount()).isEqualTo(3);
        assertThat(summary.totalDebits()).isCloseTo(571.29, offset(0.01));
    });
```

### Eventual Consistency in Practice

For user-facing reads, eventual consistency is usually invisible — the view updates in milliseconds. For the rare case where a caller must see their own write immediately, read from the entity directly (strong consistency via `ComponentClient.forEventSourcedEntity`). Use views for listing, searching, and aggregation where slight staleness is acceptable.

The key mental model: the entity is the authority, the view is the index. You trust the authority for precision; you use the index for speed.

## Retroactive Projections: New Questions, Old Data

This is the killer feature of event sourcing combined with CQRS.

Need a dashboard that shows spending trends by merchant over the last 12 months? You did not build that view when you launched. With CRUD, you are out of luck — the historical data was overwritten. With event sourcing, you deploy a new view, and the runtime replays the full event history to materialize the answers. The data was always there; you just had not asked that question yet.

When a new View is deployed, the Akka runtime processes the entity's event journal from the beginning. Each event flows through the `TableUpdater` exactly as if it had been processed in real-time. The view builds up its table row by row, event by event, until it reaches the present. From that point forward, it processes new events as they arrive.

If you need to change a view's schema — add a field, change the denormalization, restructure the table — deploy the new version. The runtime drops the old table and replays from the event journal. No data migration script. No SQL ALTER TABLE. No coordinated release. The events are the source; the view schema is just the current interpretation.

This is impossible in CRUD systems. Once data is UPDATE'd, the history is gone. There is nothing to replay, nothing to reproject. Event sourcing preserves the raw material — the complete sequence of facts — and CQRS lets you reshape it into any view at any time.

## Read Performance at Scale

Views deliver predictable read performance because of deliberate architectural choices:

**No joins.** View tables are denormalized by design. A query hits a single table with no joins. In a normalized CRUD database, listing all statements for an account might require joining statements, transactions, and accounts tables. In CQRS, it is a single-table lookup on a pre-computed projection.

**No event replay on read.** The view maintains a materialized table. Reads are table lookups, not event replays. Even if an entity has 10,000 events, the view's query is constant-time — the view has already processed those events incrementally.

**Independent scaling.** Views are stateless consumers. Scale read replicas without affecting entity write capacity. A spike in read traffic does not touch the write path.

The read path is O(1) relative to the entity's event count. The view has already done the work of folding events into denormalized rows. The query simply retrieves those rows.

## Write Performance: The Append-Only Advantage

The write side benefits equally from the separation:

**Writes are appends.** Persisting an event is an append to a journal — the fastest possible storage operation. No read-modify-write cycle. No lock acquisition. No index maintenance on the write path. The entity processes a command, validates it against in-memory state, emits an event, and the runtime appends it to the journal.

**No contention between reads and writes.** The entity processes writes. The view processes reads. They share no storage, no locks, no connection pool. A spike in read traffic does not slow down writes. A burst of writes does not degrade read latency (beyond the brief eventual consistency window).

**Snapshot optimization.** Akka's `snapshot-every` configuration (set to `10` in our sample project's `application.conf`) takes periodic snapshots to avoid replaying the full event history on entity recovery. The snapshot is a cached fold result — it accelerates recovery without affecting the event journal's integrity or the view's event processing.

```
# application.conf
akka.javasdk.event-sourced-entity.snapshot-every = 10
```

After every 10 events, the runtime snapshots the entity's current state. On recovery, it loads the latest snapshot and replays only the events after it. An entity with 10,000 events recovers from the last snapshot plus at most 9 events — effectively constant-time recovery regardless of event count.

## Patterns That Compound

Looking across the first two posts, a pattern emerges. Each architectural choice reinforces the others:

**Immutability enables caching.** An immutable event or state snapshot can be cached indefinitely. It never becomes stale. Cache invalidation — one of the hardest problems in computer science — becomes trivial when the cached objects are immutable.

**Idempotency enables retries.** If a command handler is idempotent, the platform can retry failed requests without risking duplicate events. This makes the system self-healing under transient failures — a property we will lean on heavily in [Part 5]({{< ref "/blog/akka/platform-internals-multi-region-resilience" >}}).

**Event sourcing enables replay.** If state is derived from events, it can be reconstructed anywhere — a new replica, a new region, a new version. Recovery is mechanical, not manual. This is why deployment in [Part 4]({{< ref "/blog/akka/deployment-resilience-multi-region" >}}) is a single command with no migration scripts.

**CQRS enables independent scaling.** Separate read and write models means you can scale each independently. High read load? Add view replicas. High write load? Add entity replicas. No compromise, no shared resources.

**Each pattern reinforces the others.** Immutability makes events safe to replicate. Idempotency makes commands safe to retry. Event sourcing makes state safe to rebuild. CQRS makes performance safe to optimize independently. Remove any one pattern, and the others lose their power. Together, they form a self-reinforcing architecture where correctness and performance are not at odds — they are the same thing.

These compounding patterns are why the entities we built in Part 1, with no awareness of multi-region replication, will work across regions without code changes. The immutability, the idempotency, the pure event application — these are exactly the properties that multi-region distribution requires. We did not design for it explicitly; the architecture produces it as a natural consequence.

In [Part 3]({{< ref "/blog/akka/cross-service-communication-agentic-ai" >}}), we wire services together using platform-managed HTTP and explore how AI fits into this architecture as a peer component.

The [complete source code](https://github.com/PradeepLoganathan/microsvs-microapp) is available on GitHub.
