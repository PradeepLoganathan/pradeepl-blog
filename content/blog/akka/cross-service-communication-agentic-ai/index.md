---
title: "Building Resilient Microservices with Akka — Part 2: Cross-Service Communication & Agentic AI"
lastmod: 2026-02-18T16:00:00+10:00
date: 2026-02-18T16:00:00+10:00
draft: true
Author: Pradeep Loganathan
tags:
  - akka
  - microservices
  - agentic-ai
  - distributed-systems
  - java
  - cross-service-communication
categories:
  - akka
  - architecture
description: "How Akka SDK handles inter-service communication with HttpClientProvider, rules-based processing, and LLM-powered agents with function tools — all within the same event-driven architecture."
summary: "Explore Akka SDK's HttpClientProvider for platform-managed service discovery, dual-mode analysis with deterministic heuristics and LLM-powered agents, and rules-based recommendation engines across microservice boundaries."
ShowToc: true
TocOpen: true
images:
  - "images/cover.png"
cover:
  image: "images/cover.png"
  alt: "Cross-service communication and agentic AI with Akka SDK"
  caption: "Platform-managed service discovery and AI-powered analysis with Akka SDK"
  relative: true
series: ["Building Resilient Microservices with Akka"]
weight: 3
---

{{< series-toc >}}

In [Part 1]({{< ref "/blog/akka/event-sourcing-cqrs-with-akka" >}}), we built event-sourced entities with CQRS views, the foundational data layer of our banking demo. But microservices do not exist in isolation. The real value of a decomposed architecture comes from services collaborating: the analysis-service needs transaction data from the statement-service, and the recommendation-service needs analysis results to suggest financial products.

This is where distributed systems get interesting, and where many architectures stumble. Hardcoded URLs break in production. Service meshes add operational complexity. Message brokers introduce eventual consistency that requires careful design.

Akka SDK takes a different approach. Services in the same Akka project discover each other through the platform. The `HttpClientProvider` gives you an HTTP client that routes by service name, no URLs, no service registries, no DNS hacks. The platform handles TLS, authentication, and routing transparently.

In this post, we'll build two services that demonstrate this: an **analysis-service** that categorizes transactions with both a deterministic heuristic engine and an LLM-powered Akka Agent, and a **recommendation-service** that applies rules against the analysis to suggest products.

![Analysis Service Architecture](images/analysis-service-architecture.png)

## Three Types of Clients in Akka SDK

Before diving into the services, it is worth understanding Akka SDK's client model. There are three distinct mechanisms for communication, each designed for a specific scope:

**ComponentClient**, For intra-service communication. This is what we used in Part 1 to call entities and views from endpoints. It routes within the same service, and the Akka runtime handles entity location transparently.

```java
componentClient
    .forEventSourcedEntity(statementId)
    .method(StatementEntity::getStatement)
    .invoke();
```

**HttpClientProvider**, For inter-service HTTP communication. When your service needs to call another service deployed in the same Akka project, you use `HttpClientProvider.httpClientFor("service-name")`. The platform resolves the service name to the correct endpoint, handling TLS and routing automatically.

```java
HttpClient statementClient = httpClientProvider.httpClientFor("statement-service");
var response = statementClient
    .GET("/accounts/" + accountId + "/statements/" + statementId)
    .responseBodyAs(String.class)
    .invoke();
```

**GrpcClientProvider**, For inter-service gRPC communication. Same concept as HttpClientProvider but for gRPC services.

The key insight is that inter-service calls use the service's deployed name as the only addressing mechanism. This deserves emphasis, because what it eliminates is substantial.

In a typical Kubernetes-based microservices deployment, connecting service A to service B requires: a Kubernetes Service resource, a DNS name or environment variable that A reads, environment-specific configuration (the URL differs between dev, staging, and production), possibly a service mesh like Istio or Linkerd for mTLS and retries, and health checks to detect when B is unavailable. Each of these is a configuration surface, a thing that can be wrong, stale, or misconfigured. Every production incident postmortem folder contains at least one story about a wrong URL, a missing environment variable, or a DNS record that pointed to a decommissioned host.

Akka's model eliminates this entire category. `httpClientProvider.httpClientFor("statement-service")` is not a convenience wrapper around the same infrastructure. It is a fundamentally different approach: the application expresses *intent* ("I need to talk to statement-service") and the platform handles *mechanism* (TLS, load balancing, service resolution, retries, circuit breaking). The same code works in local development and in production with zero configuration changes. There is no `application-dev.yml` with different URLs.

## The Analysis Service: Dual-Mode Processing

The analysis-service has an interesting design challenge. It needs to categorize transactions and generate spending insights, a task that can be solved both deterministically (keyword matching, threshold rules) and with AI (an LLM analyzing patterns). We implement both approaches, switchable via configuration.

### The Endpoint: Routing by Mode

The `AnalysisEndpoint` injects both a `ComponentClient` (for the agent) and an `HttpClientProvider` (for cross-service calls):

```java
@HttpEndpoint("/accounts")
public class AnalysisEndpoint extends AbstractHttpEndpoint {

    private static final String ANALYSIS_MODE =
        ConfigFactory.load().getString("analysis.mode");

    private final ComponentClient componentClient;
    private final HttpClient statementClient;

    public AnalysisEndpoint(ComponentClient componentClient,
                            HttpClientProvider httpClientProvider) {
        this.componentClient = componentClient;
        this.statementClient = httpClientProvider.httpClientFor("statement-service");
    }
```

The `httpClientProvider.httpClientFor("statement-service")` call creates an HTTP client bound to the statement-service. In local development, Akka's dev mode handles routing. In production on the Akka Platform, the service name is resolved to the deployed instance. The same code works in both environments with zero configuration changes.

### Cross-Service Data Fetching

When the analysis is triggered, the endpoint fetches statement data from the statement-service:

```java
private String fetchStatement(String accountId, String statementId) {
    var response = statementClient
        .GET("/accounts/" + accountId + "/statements/" + statementId)
        .responseBodyAs(String.class)
        .invoke();
    return response.body();
}
```

This is a synchronous call using Akka's `HttpClient`, not `java.net.http.HttpClient`. The distinction matters. Akka's client integrates with the platform's connection pooling, circuit breaking, and observability. It returns the response body as a typed object, and exceptions propagate naturally.

The fetched JSON is then passed to whichever analysis mode is configured:

```java
@Get("/{accountId}/analysis/summary")
public HttpResponse getSummary(String accountId) {
    String statementId = requestContext().queryParams()
        .getString("statementId").orElse("stmt-2025-12");

    AnalysisSummary summary = AnalysisStore.get(accountId, statementId);
    if (summary == null) {
        String statementJson = fetchStatement(accountId, statementId);
        summary = HeuristicCategorizer.analyze(
            accountId, statementId, statementJson);
        AnalysisStore.save(accountId, statementId, summary);
    }
    return HttpResponses.ok(summary);
}
```

The summary endpoint auto-runs analysis if no cached result exists. This lazy computation pattern avoids a separate "trigger then fetch" workflow for the common case.

### The Heuristic Categorizer

The default analysis mode uses a deterministic categorizer that processes transaction JSON directly:

```java
public static AnalysisSummary analyze(String accountId,
        String statementId, String statementJson) {
    JsonNode root = mapper.readTree(statementJson);
    JsonNode txnArray = root.get("transactions");

    Map<String, Double> categoryTotals = new LinkedHashMap<>();
    Map<String, Integer> categoryCounts = new LinkedHashMap<>();
    Map<String, Double> merchantTotals = new LinkedHashMap<>();
    double totalSpend = 0;

    for (JsonNode txn : txnArray) {
        String category = txn.get("category").asText();
        double amount = txn.get("amount").asDouble();
        String merchant = txn.get("merchant").asText();

        totalSpend += amount;
        categoryTotals.merge(category, amount, Double::sum);
        categoryCounts.merge(category, 1, Integer::sum);
        merchantTotals.merge(merchant, amount, Double::sum);
    }
    // ... build categories, top merchants, insights
}
```

The categorizer aggregates spending by category and merchant, calculates percentages, identifies the top 5 merchants, and generates insights based on threshold rules:

- **travel_alert**, Travel spending exceeds 30% of total
- **health_alert**, Health spending exceeds 20%
- **everyday_tip**, Groceries plus utilities exceed 30%
- **recurring**, Merchants appearing two or more times

Each insight is a typed record with a `type` and `message`:

```java
public record Insight(String type, String message) {}
```

The output is an `AnalysisSummary` containing categories, top merchants, and insights, a self-contained analysis result that downstream services can consume.

### The Akka Agent: LLM-Powered Analysis

The same analysis can be performed by an LLM agent. Akka SDK's `Agent` construct provides a structured way to integrate LLMs with tool use:

```java
@Component(id = "transaction-analysis-agent")
public class TransactionAnalysisAgent extends Agent {

    private static final String SYSTEM_MESSAGE = """
        You are a financial analyst AI agent. Your task is to analyze
        bank transactions and provide spending insights.

        When given an account and statement, you should:
        1. Use the fetchTransactions tool to get transaction data
        2. Use the categorizeTransactions tool to categorize spending
        3. Identify the top spending categories and merchants
        4. Generate actionable financial insights
        5. Use the persistAnalysis tool to save your results
        """;

    public Effect<String> analyze(AnalyzeRequest request) {
        String userMessage = "Analyze the transactions for account "
            + request.accountId() + ", statement " + request.statementId();

        return effects()
            .systemMessage(SYSTEM_MESSAGE)
            .userMessage(userMessage)
            .thenReply();
    }
}
```

The agent is invoked from the endpoint through the `ComponentClient`:

```java
if ("agent".equals(mode)) {
    String sessionId = accountId + "-" + statementId;
    var result = componentClient.forAgent()
        .inSession(sessionId)
        .method(TransactionAnalysisAgent::analyze)
        .invoke(new AnalyzeRequest(accountId, statementId));
}
```

The `.inSession(sessionId)` call is required, agents maintain conversational state within sessions, enabling multi-turn interactions and memory across tool calls.

### Function Tools: Giving the Agent Capabilities

The agent's power comes from its tools, functions annotated with `@FunctionTool` that the LLM can invoke during its reasoning:

```java
@FunctionTool(description = "Fetch transactions from the statement service")
public String fetchTransactions(
    @Description("The account ID") String accountId,
    @Description("The statement ID") String statementId) {
    // ... HTTP call to statement-service
    return response.body();
}

@FunctionTool(description = "Categorize a transaction based on merchant name")
public String categorizeTransaction(
    @Description("The merchant name") String merchant,
    @Description("The transaction amount") double amount,
    @Description("The transaction description") String description) {

    String combined = (merchant + " " + description).toLowerCase();
    if (combined.contains("airline") || combined.contains("hotel")) {
        return "Travel";
    } else if (combined.contains("pharmacy") || combined.contains("doctor")) {
        return "Health";
    }
    // ... more categories
    return "Shopping";
}
```

The `@Description` annotations provide the LLM with parameter semantics. The LLM reads the function descriptions and parameter descriptions to decide when and how to call each tool. This is the standard function-calling pattern, but embedded within Akka's runtime, the tools benefit from the platform's supervision, logging, and lifecycle management.

### AI as Peer, Not Layer

The dual-mode design reveals something important about how AI should fit into enterprise architectures.

Most organizations add AI as a separate layer, an "AI service" that wraps an LLM API, called by other services as a special case. The AI service has different deployment patterns, different failure modes, different scaling characteristics. It is architecturally foreign.

In this design, the agent is a first-class Akka component. It is invoked through the `ComponentClient`, the same mechanism used for entities and views. It uses `@FunctionTool` methods that call other services through the same `HttpClientProvider` used for any inter-service communication. Its tools include the same deterministic categorization logic used by the heuristic mode. The LLM is not replacing the existing architecture, it is *orchestrating* it.

The critical proof point: both modes produce the same output contract. The recommendation-service calls the analysis-service and receives an `AnalysisSummary`. It does not know whether that summary was produced by keyword matching or by an LLM. The contract is identical. The demo uses OpenAI's GPT-4 as the backing model, but the architecture is LLM-agnostic, swap in Claude, Gemini, Mistral, or a self-hosted model and nothing outside the agent configuration changes. This means:

- **Testing is contract-based**, You test the output shape, not the implementation.
- **Fallback is trivial**, Switch from agent mode to heuristic mode via configuration. The rest of the system is unaffected.
- **Adoption is incremental**, Start with deterministic logic. Add the agent when you are ready. Swap back if the LLM is unreliable. No architectural changes.

This is what "AI as peer" means in practice: the LLM participates in the same service mesh, uses the same communication patterns, and produces the same contracts as every other component. It is a pluggable strategy, not a foundational dependency.

## The Recommendation Service: Rules Engine

The recommendation-service sits at the end of the processing chain. It fetches analysis results from the analysis-service and applies matching rules to suggest financial products.

### Cross-Service Communication

The endpoint follows the same `HttpClientProvider` pattern:

```java
@HttpEndpoint("/accounts")
public class RecommendationEndpoint extends AbstractHttpEndpoint {

    private final HttpClient analysisClient;

    public RecommendationEndpoint(HttpClientProvider httpClientProvider) {
        this.analysisClient = httpClientProvider.httpClientFor("analysis-service");
    }

    @Get("/{accountId}/recommendations")
    public HttpResponse getRecommendations(String accountId) {
        String statementId = requestContext().queryParams()
            .getString("statementId").orElse("stmt-2025-12");

        var analysisResponse = analysisClient
            .GET("/accounts/" + accountId
                + "/analysis/summary?statementId=" + statementId)
            .responseBodyAs(String.class)
            .invoke();

        List<Recommendation> recommendations =
            RecommendationEngine.generateRecommendations(
                accountId, statementId, analysisResponse.body());
        return HttpResponses.ok(recommendations);
    }
}
```

Notice the service call chain: a request to the recommendation-service triggers a call to the analysis-service, which in turn calls the statement-service. Three services collaborating through platform-managed HTTP, no message broker, no event bus, no shared database.

### The Rules Engine

The `RecommendationEngine` applies deterministic rules against the analysis summary:

```java
public static List<Recommendation> generateRecommendations(
        String accountId, String statementId, String analysisJson) {

    JsonNode analysis = mapper.readTree(analysisJson);
    JsonNode categories = analysis.get("categories");
    JsonNode insights = analysis.get("insights");
    List<Recommendation> recommendations = new ArrayList<>();

    // Rule: high travel spending -> travel rewards card
    double travelPct = getCategoryPercentage(categories, "Travel");
    if (travelPct > 30) {
        recommendations.add(new Recommendation(
            "travel_rewards_card",
            "Travel Rewards Platinum Card",
            "Your travel spending is " + travelPct
                + "% of total, earn 3x points on every trip"));
    }

    // Rule: high health spending -> health insurance
    double healthPct = getCategoryPercentage(categories, "Health");
    if (healthPct > 20) {
        recommendations.add(new Recommendation(
            "health_insurance_basic",
            "HealthGuard Basic Plan",
            "With " + healthPct
                + "% spent on health, comprehensive coverage "
                + "could reduce out-of-pocket costs"));
    }

    // Rule: high groceries + utilities -> cashback card
    double groceryPct = getCategoryPercentage(categories, "Groceries");
    double utilityPct = getCategoryPercentage(categories, "Utilities");
    if (groceryPct + utilityPct > 30) {
        recommendations.add(new Recommendation(
            "cashback_everyday_card",
            "Cashback Everyday Card",
            "Groceries and utilities are "
                + (groceryPct + utilityPct)
                + "% of spending, earn 2% cashback"));
    }

    // Rule: recurring payments detected -> bill pay assistant
    boolean hasRecurring = false;
    if (insights != null) {
        for (JsonNode insight : insights) {
            if ("recurring".equals(insight.get("type").asText())) {
                hasRecurring = true;
                break;
            }
        }
    }
    if (hasRecurring) {
        recommendations.add(new Recommendation(
            "bill_pay_assist",
            "SmartBill Pay Assistant",
            "Recurring payments detected, automate bills "
                + "and never miss a due date"));
    }

    return recommendations;
}
```

Each rule evaluates a condition against the analysis data and produces a `Recommendation` with a product ID, name, and personalized reason. The confidence scores are logged for observability but excluded from the API response, they are an internal signal for monitoring and tuning, not a user-facing metric.

```java
public record Recommendation(
    String productId,
    String productName,
    String reason
) {}
```

![Recommendation Service Architecture](images/recommendation-service-architecture.png)

## Design Decisions Worth Examining

### Data Fetching in Endpoints, Not Utilities

An early version of this system had the `HeuristicCategorizer` and `RecommendationEngine` making their own HTTP calls to fetch data. This seemed clean, each component was self-contained. But it created a problem: `HttpClientProvider` is injectable in Akka endpoints (which participate in dependency injection), but not in plain utility classes.

The refactored design passes pre-fetched data into the utility classes:

```java
// Before (broken in production):
// HeuristicCategorizer fetches data itself using hardcoded URLs

// After (correct):
String statementJson = fetchStatement(accountId, statementId);  // in endpoint
summary = HeuristicCategorizer.analyze(accountId, statementId, statementJson);
```

This is a better design for several reasons. The endpoint controls the I/O boundary. The categorizer and engine are pure functions over data, easy to test, easy to reason about, no hidden dependencies. The unit tests pass JSON strings directly without needing HTTP mocking:

```java
@Test
void shouldRecommendTravelCardForHighTravelSpend() {
    String analysisJson = """
        {
          "totalSpend": 1000.0,
          "categories": [
            {"category": "Travel", "total": 500.0, "percentage": 50.0}
          ],
          "insights": []
        }
        """;

    List<Recommendation> recs = RecommendationEngine
        .generateRecommendations("acc-1001", "stmt-2025-12", analysisJson);

    assertTrue(recs.stream()
        .anyMatch(r -> "travel_rewards_card".equals(r.productId())));
}
```

### Synchronous Chains vs. Async Events

The recommendation-service makes synchronous HTTP calls to the analysis-service, which calls the statement-service. In a traditional microservices architecture, you might reach for a message broker here, publish analysis results to a topic, have the recommendation-service consume them asynchronously.

For this use case, synchronous is the right choice. The recommendation endpoint needs analysis results *now* to respond to the caller. There is no benefit to eventual consistency here, the user is waiting for recommendations. The synchronous chain is simpler to reason about, simpler to debug (one request ID flows through all three services), and the Akka platform provides the resilience guarantees (circuit breaking, retries, timeouts) that you would otherwise need a service mesh for.

> **Watch for tail-latency amplification.** In a synchronous chain, end-to-end latency is the *sum* of every hop. A p99 spike in the statement-service becomes a p99 spike for every upstream caller. Set explicit per-call timeouts (e.g., 2 s for statement-service, 5 s for analysis-service) so that one slow dependency fails fast instead of stalling the entire chain. Pair timeouts with a retry budget, for example, at most one retry per call and a circuit breaker that opens after a handful of consecutive failures. Without a budget, retries on every hop multiply geometrically: one retry at each of three hops turns a single request into eight attempts, amplifying load on an already struggling service.

Asynchronous communication shines when services need to react to events without blocking a caller, order fulfillment, notification dispatch, analytics ingestion. The choice is architectural, not ideological.

### Why Not a Message Broker?

Readers with Kafka experience will feel an itch here. Three services forming a call chain? Surely this should be an event pipeline: the statement-service publishes transactions to a topic, the analysis-service consumes and categorizes them, the recommendation-service consumes the analysis and generates recommendations. Decoupled, asynchronous, scalable.

For this use case, that would be the wrong architecture. Consider the user's experience: they open the recommendations tab and expect to see personalized product suggestions. With synchronous HTTP, they get a response in milliseconds. With an event pipeline, they see... nothing, until the pipeline catches up. The analysis might not have processed their latest statement yet. The recommendation might be based on stale data.

Asynchronous event pipelines excel when consumers do not need results immediately, analytics aggregation, notification dispatch, data warehouse ingestion. They excel when the producer and consumer have different lifecycles and should not block each other. But when the user is waiting for a response, synchronous is not just simpler, it is correct.

The Akka platform provides the resilience guarantees (circuit breaking, retries, timeouts) that would otherwise motivate a broker. And because each service is independently deployable with its own event journal, there is no shared-state coupling that a broker would decouple. The services are already decoupled through their API contracts. Adding a broker would add operational complexity (topic management, consumer groups, offset tracking, dead letter queues) without solving a problem that exists.

The principle: choose the communication pattern that matches the consistency requirement. Synchronous for request-response workflows where the caller needs the result. Asynchronous for fire-and-forget or fan-out workflows where the producer should not wait.

### In-Memory vs. Event-Sourced Storage

The analysis-service stores results in a `ConcurrentHashMap` rather than an event-sourced entity. This is a deliberate trade-off: analysis results are derivable. Given the same statement data and the same categorization rules, you get the same result. There is no value in maintaining an event journal for derived data.

If the analysis logic changes, you want to regenerate results, not replay old events that would produce outdated insights. The in-memory cache is appropriate for a demo; in production, you might use a time-limited cache or a view projection, but the principle holds: store events for authoritative state, use caches for derived computations.

### Testability as an Architectural Consequence

The refactoring that moved HTTP fetching into endpoints and made `HeuristicCategorizer` and `RecommendationEngine` into pure functions over data was not a testing convenience. It was an architectural decision with testing as a natural consequence.

The categorizer takes a JSON string and returns an `AnalysisSummary`. The engine takes a JSON string and returns a list of `Recommendation`. No HTTP clients to mock, no service dependencies to stub, no database connections to configure. Unit tests pass JSON literals directly:

```java
@Test
void shouldRecommendHealthInsuranceForHighHealthSpend() {
    String analysisJson = """
        {
          "totalSpend": 1000.0,
          "categories": [
            {"category": "Health", "total": 250.0, "percentage": 25.0}
          ],
          "insights": []
        }
        """;

    List<Recommendation> recs = RecommendationEngine
        .generateRecommendations("acc-1001", "stmt-2025-12", analysisJson);

    assertTrue(recs.stream()
        .anyMatch(r -> "health_insurance_basic".equals(r.productId())));
}
```

This testability is not unique to this codebase, it is a general consequence of the event-sourced, pure-function architecture. When state transitions are pure folds over events (Part 1), they are testable without infrastructure. When business logic is a pure function over data (this post), it is testable without mocking. When I/O is pushed to the edges (endpoints), the core logic is deterministic. The architecture *produces* testability. You do not need to engineer it separately.

## The Service Communication Graph

Stepping back, the full service graph looks like this:

```
                    recommendation-service (:8084)
                           |
                    HttpClientProvider
                    ("analysis-service")
                           |
                           v
                      analysis-service (:8083)
                           |
                    HttpClientProvider
                   ("statement-service")
                           |
                           v
                    statement-service (:8082)
                    [EventSourcedEntity]
                    [View: by account]

    product-service (:8085)
    [EventSourcedEntity]
    (standalone, called directly by clients)
```

Every arrow is a platform-managed HTTP call using service names. No hardcoded URLs, no environment variables, no service registry. The Akka Platform resolves service names to endpoints, handles TLS between services, and provides observability across the call chain.

## What's Next

We now have four services that communicate through platform-managed HTTP, with business logic isolated as pure functions and AI integrated as a peer component. The question that remains: does this hold up in production?

In [Part 3]({{< ref "/blog/akka/deployment-resilience-multi-region" >}}), we deploy to the Akka Platform and discover that the `httpClientProvider.httpClientFor("statement-service")` pattern works identically in production, zero configuration changes. We will examine how the runtime distributes entities across replicas, how failure recovery works through event replay, and how the same event-sourced entities we built in Part 1 become the foundation for multi-region replication.

The [complete source code](https://github.com/PradeepLoganathan/microsvs-microapp) is available on GitHub.
