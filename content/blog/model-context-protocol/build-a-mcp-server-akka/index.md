---
title: "Building an MCP Server with Akka"
lastmod: 2025-10-27T14:29:22+10:00
date: 2025-10-27T14:29:22+10:00
draft: false
Author: Pradeep Loganathan
tags:
  - ai
  - llm
  - integration
  - model-context-protocol
  - developer-tools
  - java
  - akka
categories:
  - AI Architecture
  - Agent Systems
  - DevTools
description: "Learn how to build production-ready MCP servers using Akka Java SDK with declarative annotations, built-in service discovery, and seamless agent integration."
summary: "This guide demonstrates building an MCP server using Akka Java SDK with annotation-based tool definitions, service discovery, and integration with both external MCP clients and Akka agents."
ShowToc: true
TocOpen: true
cover:
    image: "images/mcp-server-akka-cover.webp"
    alt: "Building MCP Server with Akka"
    caption: "Building MCP Server with Akka"
    relative: true
series: ["Model Context Protocol"]
---

## Introduction

In previous posts of this [series]({{< relref "/series/model-context-protocol/" >}}), we explored the Model Context Protocol and also built an MCP server using [.NET]({{< relref "/blog/model-context-protocol/build-a-mcp-server/" >}}). Now, let's explore a more enterprise-focused approach to building MCP servers using the Akka Java SDK, which brings distributed systems capabilities and production-grade features to MCP server development.

Akka's MCP implementation stands out with its declarative annotation-based approach, built-in service discovery, and seamless integration with Akka's agent system. This makes it particularly well-suited for building MCP servers that need to scale, integrate with existing microservices, or serve as tools for AI-powered agent workflows.

## What Makes Akka's MCP Implementation Different?

Unlike the traditional MCP SDK implementations we've seen, Akka's approach offers several unique advantages:

1. **Declarative Tool Definition**: Tools are defined using simple annotations (`@McpTool`, `@McpResource`) rather than manual registration
2. **Built-in HTTP Server**: Automatic HTTP/JSON-RPC endpoint exposure at `/mcp`
3. **Service Discovery**: Seamless integration with Akka's service discovery for distributed deployments
4. **Agent Integration**: Direct consumption by Akka agents using `RemoteMcpTools.fromService()`
5. **Production Ready**: Built on Akka's battle-tested distributed systems framework
6. **Multi-Client Support**: Serves both external MCP clients (Claude Desktop, VS Code) and internal Akka agents simultaneously

## What You'll Build

### The Bigger Picture: Agentic AI Triage System

Imagine you're running a production microservices platform with dozens of services. When an incident occurs - payment gateway timeouts, database connection failures, authentication errors - you need rapid, intelligent triage. This is where our **Agentic AI Triage System** comes in.

The complete triage system (available at [agentic-triage-system](https://github.com/PradeepLoganathan/akka-kata/tree/main/akka-spovs/agentic-triage-system)) is a production-ready multi-agent incident response platform that orchestrates six specialized AI agents:

1. **ClassifierAgent**: Classifies incidents by service, severity, and domain with confidence scores
2. **EvidenceAgent**: Gathers evidence from logs, metrics, and observability tools
3. **TriageAgent**: Performs systematic diagnosis using 5 Whys methodology and pattern analysis
4. **KnowledgeBaseAgent**: Searches runbooks and historical incident reports
5. **RemediationAgent**: Proposes staged remediation plans with rollback strategies
6. **SummaryAgent**: Generates multi-audience summaries (executive, technical, customer support)

The workflow orchestrates these agents in a systematic pipeline: **classify → gather_evidence → triage → query_knowledge_base → remediate → summarize → finalize**.

### Where MCP Tools Fit In

Here's the critical insight: **The EvidenceAgent needs access to real-world observability data** - logs from services, metrics from monitoring systems, correlation analysis across data sources. But we don't want to hardcode integrations with Datadog, Elasticsearch, Splunk, or other tools directly into our agent logic.

This is where the **Model Context Protocol** shines. By exposing evidence gathering capabilities as MCP tools, we create a clean separation:

- **The Agent**: Focuses on intelligent evidence collection strategy and analysis
- **The MCP Server**: Handles the mechanics of fetching data from various sources

The EvidenceAgent connects to our MCP server using Akka's native integration:

```java
@Component(id = "evidence-agent")
public class EvidenceAgent extends Agent {
    public Effect<String> gather(Request req) {
        return effects()
            .model(ModelProvider.openAi().withModelName("gpt-4o-mini"))
            .mcpTools(
                RemoteMcpTools.fromService("evidence-tools")
                    .withAllowedToolNames("fetch_logs", "query_metrics", "correlate_evidence")
            )
            .systemMessage("You are an expert evidence collection agent...")
            .userMessage("Gather evidence for incident in " + req.service())
            .thenReply();
    }
}
```

When the AI model needs evidence, it can call these tools through the MCP protocol - completely abstracted from whether the data comes from local files, Datadog APIs, Elasticsearch queries, or SIEM systems.

### What This Tutorial Builds

In this tutorial, we'll build the **Evidence Tools MCP Server** that provides:

**MCP Tools (Callable Functions):**
- `fetch_logs`: Retrieve service logs with automatic error analysis and anomaly detection
- `query_metrics`: Query performance metrics (error rates, latency, throughput, resource utilization)
- `correlate_evidence`: Analyze relationships between logs and metrics to identify patterns

**MCP Resources (URI-based Data Access):**
- `kb://runbooks/{serviceName}`: Access troubleshooting runbooks and operational documentation

**Infrastructure:**
- HTTP endpoint at `/mcp` with JSON-RPC 2.0 protocol
- Akka service discovery integration for seamless agent connection
- Support for external MCP clients (Claude Desktop, VS Code)

### From Sample to Production

**In this sample**, we use file-based data sources (JSON files in `src/main/resources/`) to demonstrate the pattern. This makes the tutorial self-contained and easy to run locally without external dependencies.

**In production**, you would replace these file-based implementations with secure API integrations:

- **Datadog Integration**: Replace `fetch_logs` with Datadog Logs API calls using API keys
- **Elasticsearch/OpenSearch**: Query logs and traces using the Elasticsearch REST API
- **Prometheus/Grafana**: Fetch metrics using PromQL queries
- **SIEM Systems**: Integrate with Splunk, Sumo Logic, or Azure Sentinel for security events
- **APM Tools**: Connect to New Relic, Dynatrace, or AppDynamics for application performance data
- **Cloud Provider APIs**: AWS CloudWatch, Azure Monitor, GCP Cloud Logging

The beauty of the MCP architecture is that **agents don't need to change** when you swap implementations. The tools maintain the same interface - same names, same parameters, same response structure - whether reading from files or calling production APIs.

**Why Build These as MCP Servers?**

1. **Reusability**: These tools can be used by any MCP client - not just our triage system
2. **Isolation**: Evidence gathering runs in its own service, with independent scaling and deployment
3. **Security**: Centralized access control to sensitive observability data and API credentials
4. **Flexibility**: Swap implementations (mock → staging → production) without changing agent code
5. **Multi-Client**: The same MCP server serves both Akka agents and external tools like Claude Desktop

**Repositories:**
- **This Tutorial**: [agenticai-triage-mcp-tools](https://github.com/PradeepLoganathan/akka-kata/tree/main/akka-spovs/agenticai-triage-mcp-tools) - MCP server for evidence gathering
- **Triage System**: [agentic-triage-system](https://github.com/PradeepLoganathan/akka-kata/tree/main/akka-spovs/agentic-triage-system) - Complete multi-agent incident response platform

## Prerequisites

Before starting, ensure you have:

- **JDK 21** (Akka Java SDK requires Java 21)
- **Maven 3.8+** for dependency management
- **VS Code** or **Claude Desktop** for testing
- Basic familiarity with Java annotations and Maven
- Understanding of MCP concepts from previous posts in this series

## Architecture Overview

The Akka MCP implementation follows a microservices-oriented architecture:

```
┌─────────────────────────────────────┐
│  Triage Service (port 9100)         │
│                                     │
│  EvidenceAgent uses:                │
│  RemoteMcpTools.fromService(        │
│    "evidence-tools"                 │
│  )                                  │
└──────────────┬──────────────────────┘
               │
               │ Service Discovery
               │ (dev-mode)
               ↓
┌─────────────────────────────────────┐
│  Evidence Tools Service (port 9200) │
│                                     │
│  @McpEndpoint                       │
│  - fetch_logs                       │
│  - query_metrics                    │
│  - correlate_evidence               │
│  - kb://runbooks/{service}          │
└─────────────────────────────────────┘
               │
               │ JSON-RPC 2.0
               │ HTTP POST /mcp
               ↓
┌─────────────────────────────────────┐
│  External MCP Clients               │
│  - Claude Desktop                   │
│  - VS Code / GitHub Copilot         │
│  - Other MCP clients                │
└─────────────────────────────────────┘
```

## Step 1: Project Setup

### Maven Configuration

Create a new Maven project with the Akka Java SDK parent:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>io.akka</groupId>
        <artifactId>akka-javasdk-parent</artifactId>
        <version>3.5.4</version>
    </parent>

    <groupId>com.example.evidence</groupId>
    <artifactId>agenticai-triage-mcp-tools</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>AgenticAI Triage MCP Tools</name>
    <description>MCP service for incident triage evidence gathering</description>
</project>
```

The `akka-javasdk-parent` POM provides all necessary dependencies including:
- Akka HTTP server
- MCP protocol support
- JSON serialization (Jackson)
- Service discovery
- Logging infrastructure

### Service Configuration

Create `src/main/resources/application.conf`:

```hocon
# Service identification (critical for service discovery)
akka.javasdk.dev-mode {
  service-name = "evidence-tools"  # Must match RemoteMcpTools.fromService("evidence-tools")
  http-port = 9200  # Unique port for this service
}

# Logging configuration
akka.loglevel = "INFO"
loggers = ["akka.event.slf4j.Slf4jLogger"]
logging-filter = "akka.event.slf4j.Slf4jLoggingFilter"

# HTTP server timeouts
akka.http.server {
  request-timeout = 60s
  idle-timeout = 120s
}
```

Key configuration points:
- `service-name`: Used by service discovery to locate this MCP server
- `http-port`: The port where the MCP endpoint will be available
- Timeouts are important for long-running tool calls

## Step 2: Building the MCP Endpoint

Let's build the MCP endpoint incrementally, starting with the basic structure and adding tools one by one. This approach will help you understand each component clearly.

> **Note:** The complete implementation is available on [GitHub](https://github.com/PradeepLoganathan/akka-kata/blob/main/akka-spovs/agenticai-triage-mcp-tools/src/main/java/com/pradeepl/evidence/EvidenceToolsEndpoint.java). Here we'll walk through the key parts step by step.

### Step 2.1: Create the Basic MCP Endpoint Class

First, create the file `src/main/java/com/pradeepl/evidence/EvidenceToolsEndpoint.java` with the basic endpoint structure:

```java
package com.pradeepl.evidence;

import akka.javasdk.annotations.Acl;
import akka.javasdk.annotations.Description;
import akka.javasdk.annotations.mcp.McpEndpoint;
import akka.javasdk.annotations.mcp.McpTool;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Acl(allow = @Acl.Matcher(principal = Acl.Principal.ALL))
@McpEndpoint(serverName = "evidence-tools", serverVersion = "1.0.0")
public class EvidenceToolsEndpoint {

    private static final Logger logger = LoggerFactory.getLogger(EvidenceToolsEndpoint.class);
    private static final ObjectMapper mapper = new ObjectMapper();

    // Tools will be added here
}
```

**Understanding the Annotations:**

- **`@McpEndpoint(serverName = "evidence-tools", serverVersion = "1.0.0")`**
  - Declares this class as an MCP server endpoint
  - `serverName`: Identifier used by clients and service discovery (must match the `service-name` in `application.conf`)
  - `serverVersion`: Version information exposed to clients via the MCP protocol
  - Akka automatically creates an HTTP endpoint at `/mcp` that implements JSON-RPC 2.0

- **`@Acl(allow = @Acl.Matcher(principal = Acl.Principal.ALL))`**
  - Access Control List that allows all clients to access this endpoint
  - In production, you'd restrict this to authenticated principals
  - Example: `@Acl(allow = @Acl.Matcher(principal = Acl.Principal.INTERNET))` for internet-facing endpoints

### Step 2.2: Add Your First MCP Tool - fetch_logs

> **Understanding MCP Tools vs Resources**: If you're new to MCP concepts, review the fundamentals in our [.NET MCP post]({{< relref "/blog/model-context-protocol/build-a-mcp-server/" >}}) which explains tools (executable functions) and resources (data access). The key difference: **Tools** are functions that AI agents can invoke to perform actions or computations, while **Resources** provide URI-based access to data or documents.

Now let's add our first tool. Add this method to the `EvidenceToolsEndpoint` class:

```java
@McpTool(
    name = "fetch_logs",
    description = "Fetch logs from the agentic AI triage system services. Returns recent log lines with automatic error analysis and anomaly detection."
)
public String fetchLogs(
        @Description("Service name to fetch logs from (e.g., payment-service, checkout-service)")
        String service,
        @Description("Number of log lines to fetch (default: 200)")
        int lines
) {
    logger.info("📝 MCP Tool: fetch_logs called - Service: {}, Lines: {}", service, lines);

    try {
        // Read log file from classpath resources
        String fileName = String.format("logs/%s.log", service);
        InputStream inputStream = getClass().getClassLoader().getResourceAsStream(fileName);

        if (inputStream == null) {
            ObjectNode errorResponse = mapper.createObjectNode();
            errorResponse.put("error", String.format("No log file found for service: %s", service));
            errorResponse.put("service", service);
            return mapper.writeValueAsString(errorResponse);
        }

        String fullLogs = new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
        String[] allLines = fullLogs.split("\n");

        // Return last N lines (most recent logs)
        int startIndex = Math.max(0, allLines.length - lines);
        int actualLines = Math.min(lines, allLines.length);

        StringBuilder recentLogs = new StringBuilder();
        for (int i = startIndex; i < allLines.length; i++) {
            recentLogs.append(allLines[i]).append("\n");
        }

        // Build structured JSON response
        ObjectNode response = mapper.createObjectNode();
        response.put("logs", recentLogs.toString());
        response.put("service", service);
        response.put("linesReturned", actualLines);
        response.put("linesRequested", lines);

        return mapper.writerWithDefaultPrettyPrinter().writeValueAsString(response);

    } catch (Exception e) {
        logger.error("📝 Error in fetch_logs", e);
        return String.format("{\"error\":\"Failed to fetch logs: %s\"}", e.getMessage());
    }
}
```

**Understanding `@McpTool`:**

- **`@McpTool`** marks a method as an MCP tool that clients can invoke
- **`name`**: The identifier clients use to call this tool (e.g., `"fetch_logs"`)
- **`description`**: Critical for AI models - describes what the tool does and when to use it
- **Method parameters** automatically become tool arguments in the MCP protocol
- **`@Description`** on parameters helps AI understand what each argument is for
- **Return value** becomes the tool's response to the client (typically JSON string)

This tool fetches service logs from the classpath, returns the most recent N lines, and wraps them in a structured JSON response.

### Step 2.3: Add Two More Tools

Following the same pattern, add two additional tools to the endpoint class:

**`query_metrics`** - Queries performance metrics (error rates, latency, CPU usage, etc.) based on a metrics expression and time range. It reads from pre-configured metrics JSON files and returns parsed data with insights.

```java
@McpTool(name = "query_metrics", description = "Query performance metrics...")
public String queryMetrics(
    @Description("Metrics expression") String expr,
    @Description("Time range") String range
) {
    // Implementation: reads metrics JSON files, formats output
    // See full code on GitHub
}
```

**`correlate_evidence`** - Analyzes relationships between log findings and metric findings to identify temporal patterns, dependency failures, and resource exhaustion correlations. This demonstrates a tool that combines data from multiple sources.

```java
@McpTool(name = "correlate_evidence", description = "Correlate findings from logs and metrics...")
public String correlateEvidence(
    @Description("Description of log findings") String logFindings,
    @Description("Description of metric findings") String metricFindings
) {
    // Implementation: analyzes correlations, timeline alignment
    // See full code on GitHub
}
```

**Key Points:**

- Multiple tools can coexist in the same endpoint class
- Each tool is independent with its own name, description, and parameters
- Helper methods don't need annotations - they're just regular Java methods
- The complete implementation with error handling is in the [GitHub repository](https://github.com/PradeepLoganathan/akka-kata/blob/main/akka-spovs/agenticai-triage-mcp-tools/src/main/java/com/pradeepl/evidence/EvidenceToolsEndpoint.java)

### Step 2.4: Add an MCP Resource - Service Runbooks

**MCP Resources vs Tools**: As explained in our [earlier posts]({{< relref "/blog/model-context-protocol/build-a-mcp-server/" >}}), MCP defines two distinct concepts:

- **Tools**: Executable functions that perform actions or computations (like `fetch_logs`, `query_metrics`)
- **Resources**: URI-based access to data, documents, or content (like runbooks, configuration files, documentation)

Resources are ideal for providing static or semi-static information that agents can reference. Let's add a resource for service runbooks:

```java
import akka.javasdk.annotations.mcp.McpResource;

@McpResource(
    uriTemplate = "kb://runbooks/{serviceName}",
    name = "Service Runbook",
    description = "Get troubleshooting runbook for a specific service",
    mimeType = "text/markdown"
)
public String getRunbook(String serviceName) {
    logger.info("📚 MCP Resource: getRunbook called - Service: {}", serviceName);

    try {
        String path = String.format("knowledge_base/%s-runbook.md", serviceName);
        InputStream in = getClass().getClassLoader().getResourceAsStream(path);

        if (in == null) {
            return String.format("# Runbook Not Found\n\nNo runbook available for service: %s", serviceName);
        }

        return new String(in.readAllBytes(), StandardCharsets.UTF_8);

    } catch (Exception e) {
        logger.error("📚 Error in getRunbook", e);
        return String.format("# Error\n\nFailed to load runbook: %s", e.getMessage());
    }
}
```

**Understanding `@McpResource`:**

- **`@McpResource`** exposes data through URI-based access (different from executable tools)
- **`uriTemplate`**: URI pattern with variables (e.g., `kb://runbooks/{serviceName}`)
  - Clients can access: `kb://runbooks/payment`, `kb://runbooks/checkout`, etc.
- **`mimeType`**: Content type of the resource (e.g., `text/markdown`, `application/json`)
- **Method parameters** are extracted from the URI template variables
- Resources are ideal for providing documentation, configuration, or reference data

### Step 2 Complete: What We've Built

We've now created a complete MCP endpoint with multiple tools and resources. The full implementation with helper methods, error handling, log analysis, and metrics parsing is available in the [GitHub repository](https://github.com/PradeepLoganathan/akka-kata/blob/main/akka-spovs/agenticai-triage-mcp-tools/src/main/java/com/pradeepl/evidence/EvidenceToolsEndpoint.java).

**Summary of components:**

- ✅ **MCP Endpoint** with `@McpEndpoint` annotation and service discovery integration
- ✅ **Three MCP Tools** (executable functions):
  - `fetch_logs` - Retrieves service logs with error analysis (shown in detail)
  - `query_metrics` - Queries performance metrics and alerts
  - `correlate_evidence` - Analyzes relationships between logs and metrics
- ✅ **One MCP Resource** (URI-based data access):
  - `kb://runbooks/{serviceName}` - Access service troubleshooting runbooks
- ✅ **HTTP Endpoint** automatically exposed at `/mcp` with JSON-RPC 2.0
- ✅ **Structured JSON responses** for all tools
- ✅ **Error handling** and comprehensive logging

The pattern is clear: define the endpoint class, add `@McpTool` methods for executable functions, and add `@McpResource` methods for data access. Akka handles the rest - HTTP server, JSON-RPC protocol, service discovery, and client integration.

## Step 3: Running the MCP Server

### Build and Run

```bash
mvn compile exec:java
```

Look for startup logs:

```
INFO  akka.runtime.DiscoveryManager - Akka Runtime started at 127.0.0.1:9200
INFO  ... - MCP endpoint component [...EvidenceToolsEndpoint], path [/mcp]
```

Your MCP server is now running and accessible at `http://localhost:9200/mcp`

### Testing with curl

Test the MCP endpoint directly:

```bash
# List available tools
curl -s http://localhost:9200/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"1","method":"tools/list","params":{}}' \
  | jq

# Call the fetch_logs tool
curl -s http://localhost:9200/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":"2",
    "method":"tools/call",
    "params":{
      "name":"fetch_logs",
      "arguments":{"service":"payment-service","lines":100}
    }
  }' | jq
```

## Step 4: Integration with MCP Clients

Now that our MCP server is running, let's integrate it with various MCP clients. The beauty of MCP is that the same server can be consumed by different clients - Claude CLI, Claude Desktop, VS Code, and even other Akka agents.

### Using Claude CLI

The simplest way to test your MCP server is with the Claude CLI tool. First, create an MCP configuration file in your project directory.

Create `claude-mcp-config.json` in your project root:

```json
{
  "mcpServers": {
    "evidence-tools": {
      "command": "node",
      "args": [
        "-e",
        "const http = require('http'); process.stdin.on('data', data => { const req = http.request('http://localhost:9200/mcp', {method: 'POST', headers: {'Content-Type': 'application/json'}}, res => { let body = ''; res.on('data', chunk => body += chunk); res.on('end', () => console.log(body)); }); req.write(data); req.end(); });"
      ],
      "env": {}
    }
  }
}
```

This configuration uses a Node.js one-liner to bridge STDIO (which Claude CLI uses) to our HTTP endpoint at `http://localhost:9200/mcp`.

Now you can use Claude CLI with your MCP tools:

```bash
# Make sure your MCP server is running (mvn compile exec:java)

# Start Claude CLI with your MCP configuration
claude --mcp-config claude-mcp-config.json

# In the Claude session, you can now use the tools:
# "Fetch logs for payment-service and analyze the errors"
# "Query error_rate metrics for the last 1 hour"
# "Correlate the evidence from logs and metrics to identify the root cause"
```

**What happens:**
1. Claude CLI loads your MCP configuration
2. It discovers the `fetch_logs`, `query_metrics`, and `correlate_evidence` tools
3. When you ask questions, Claude can intelligently decide to use these tools
4. The tools call your Akka MCP server via HTTP
5. Results are returned to Claude for analysis

**Example Session:**

```
You: Investigate the payment service issues

Claude: I'll help you investigate the payment service. Let me start by fetching
the recent logs and checking the error metrics.

[Uses fetch_logs tool with service="payment-service", lines=200]
[Uses query_metrics tool with expr="error_rate", range="1h"]

Based on the evidence gathered:

1. **Log Analysis**: Found 8 errors in recent logs, including:
   - Payment gateway timeouts (3 occurrences)
   - Database connection refused errors (3 occurrences)

2. **Metrics Analysis**:
   - Error rate: 15.3% (elevated, threshold: 5.0%)
   - 342 total errors in the last hour
   - Primary issues: connection timeouts (156), database errors (89)

Let me correlate these findings...

[Uses correlate_evidence tool with findings from logs and metrics]

**Root Cause Assessment**: The timeline shows payment gateway timeouts started
at 14:28:45, followed by database connection failures at 14:29:15. This suggests
a cascading failure pattern where gateway issues exhausted the connection pool...
```

### Claude Desktop Integration

For persistent integration with Claude Desktop, create or edit the configuration file:

**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows:** `%APPDATA%/Claude/claude_desktop_config.json`

Use the same configuration as `claude-mcp-config.json` above. Restart Claude Desktop after editing the file.

### VS Code / GitHub Copilot Integration

Create `.vscode/mcp.json` in your project:

```json
{
  "servers": {
    "evidence-tools": {
      "type": "stdio",
      "command": "node",
      "args": [
        "-e",
        "const http = require('http'); process.stdin.on('data', data => { const req = http.request('http://localhost:9200/mcp', {method: 'POST', headers: {'Content-Type': 'application/json'}}, res => { let body = ''; res.on('data', chunk => body += chunk); res.on('end', () => console.log(body)); }); req.write(data); req.end(); });"
      ]
    }
  }
}
```

Reload VS Code, open Copilot Chat in Agent mode, and the evidence tools will be available.

## Step 5: Integration with Akka Agents

One of Akka's unique features is seamless integration with its agent system. Here's how another Akka service can consume these MCP tools:

```java
package com.example.triage;

import akka.javasdk.agent.Agent;
import akka.javasdk.annotations.ComponentId;
import akka.javasdk.annotations.Description;
import akka.javasdk.client.RemoteMcpTools;

@ComponentId("evidence-agent")
public class EvidenceAgent extends Agent {

    @Description("Gather evidence from logs and metrics")
    public Effect<String> gatherEvidence(String incidentId, String serviceName) {
        // Reference the remote MCP service by its service-name
        var mcpTools = RemoteMcpTools.fromService("evidence-tools");

        // Agents can now use these tools as part of their workflow
        return effects()
            .updateState(state.withMcpTools(mcpTools))
            .reply("Evidence gathering configured for " + serviceName);
    }
}
```

The agent discovers the `evidence-tools` service automatically in dev-mode using the `service-name` from `application.conf`. In production, this works through Kubernetes service discovery or configured endpoints.

## Key Advantages of Akka's MCP Implementation

Compared to the .NET and Java SDK implementations from previous posts, Akka's approach offers:

### 1. Declarative vs. Imperative

**Traditional MCP SDK (Java):**
```java
var getLogsTool = new McpServerFeatures.SyncToolSpecification(
    new McpSchema.Tool("get_logs", "Return logs", schemaJson),
    (exchange, arguments) -> {
        // Handler implementation
    }
);
server.tools(getLogsTool);
```

**Akka MCP:**
```java
@McpTool(name = "fetch_logs", description = "Fetch logs from services")
public String fetchLogs(String service, int lines) {
    // Implementation
}
```

The Akka approach is more concise and maintainable.

### 2. Built-in HTTP Server

Traditional MCP servers require external HTTP servers (Jetty, Kestrel). Akka includes its HTTP server, automatically exposing your endpoint at `/mcp`.

### 3. Service Discovery

Akka's service discovery allows distributed services to find and consume MCP tools without hardcoded URLs:

```java
// Automatically discovers service in dev-mode or production
RemoteMcpTools.fromService("evidence-tools")
```

### 4. Resources Support

Akka's `@McpResource` provides URI-based access to data:

```java
@McpResource(uriTemplate = "kb://runbooks/{serviceName}", ...)
public String getRunbook(String serviceName) {
    // Return runbook content
}
```

Clients can access this as: `kb://runbooks/payment`

### 5. Production-Grade Features

- **Event Sourcing**: Tools can interact with event-sourced entities
- **CQRS**: Separate read/write models for tool data
- **Clustering**: Deploy multiple instances with built-in clustering
- **Resilience**: Circuit breakers, timeouts, and retry policies
- **Observability**: Built-in metrics, tracing, and logging

## Deployment Considerations

### Local Development

```bash
mvn compile exec:java
```

Services discover each other via `localhost` and configured ports.

### Production Deployment

1. **Containerize** the service:
```bash
mvn clean package
docker build -t evidence-tools:1.0.0 .
```

2. **Deploy to Kubernetes** with service discovery:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: evidence-tools
spec:
  selector:
    app: evidence-tools
  ports:
    - protocol: TCP
      port: 9200
      targetPort: 9200
```

3. **Configure service discovery**:
```hocon
akka.javasdk.production {
  service-discovery {
    method = "kubernetes-api"
  }
}
```

Akka automatically discovers services via Kubernetes DNS.

### Multi-Instance Deployment

Akka's clustering allows multiple instances:

```bash
# Deploy 3 replicas
kubectl scale deployment evidence-tools --replicas=3
```

Requests are load-balanced automatically across instances.

## Troubleshooting

### Service Not Found

**Issue:** Akka agent can't find MCP service

**Solution:**
1. Verify `service-name` in `application.conf` matches `RemoteMcpTools.fromService("...")`
2. Check both services are running
3. Ensure both are in dev-mode or both in production mode
4. Check logs for service registration:
   ```
   INFO akka.runtime.DiscoveryManager - Service 'evidence-tools' registered
   ```

### Tools Not Appearing

**Issue:** MCP clients don't see tools

**Solution:**
1. Verify `@McpEndpoint` annotation is present
2. Check `@McpTool` methods are public
3. Ensure server started successfully (check `/mcp` endpoint)
4. Test with curl to verify tools are listed

### Connection Issues

**Issue:** Client can't connect to MCP endpoint

**Solution:**
1. Verify port is not blocked by firewall
2. Check service is listening: `netstat -an | grep 9200`
3. Verify HTTP endpoint: `curl http://localhost:9200/mcp`
4. Check `akka.http.server` timeout settings

## What's Next?

Your Akka MCP server is production-ready. Consider these enhancements:

- **Authentication**: Add JWT or API key authentication using Akka's ACL system
- **Event Sourcing**: Persist tool invocations for audit trails
- **Workflow Integration**: Combine MCP tools with Akka workflows
- **Advanced Resources**: Expose streaming data, database views, or real-time feeds
- **Multi-Tenancy**: Support multiple tenants with isolated data
- **Observability**: Add OpenTelemetry tracing for tool calls
- **Rate Limiting**: Protect tools with Akka's throttling capabilities

## Conclusion

Akka's MCP implementation brings enterprise-grade capabilities to MCP server development. The annotation-based approach is more concise than manual tool registration, the built-in HTTP server simplifies deployment, and service discovery enables true microservices architectures.

### Key Takeaways

1. **Declarative Tools**: `@McpTool` provides cleaner code than manual registration
2. **HTTP First**: Built-in JSON-RPC endpoint at `/mcp`
3. **Service Discovery**: Seamless integration across distributed services
4. **Agent Integration**: Direct consumption by Akka agents for AI workflows
5. **Production Ready**: Clustering, resilience, and observability built-in
6. **Resource Support**: URI-based data access via `@McpResource`

### Comparison Summary

| Feature | .NET SDK | Java SDK | Akka SDK |
|---------|----------|----------|----------|
| Tool Definition | Attributes | Manual Registration | Annotations |
| HTTP Server | Kestrel | Jetty | Akka HTTP (built-in) |
| Transport | STDIO, SSE | STDIO, HTTP | HTTP/JSON-RPC |
| Service Discovery | Manual | Manual | Automatic |
| Agent Integration | External | External | Built-in |
| Clustering | Manual | Manual | Built-in |
| Production Features | ASP.NET Core | Spring/Jakarta EE | Akka Platform |

Akka's approach is particularly well-suited for:
- **Microservices architectures** with distributed MCP tools
- **AI agent systems** needing tool orchestration
- **Enterprise applications** requiring production-grade features
- **Event-driven systems** with CQRS and event sourcing

In the next post, we'll explore building a complete agentic workflow that orchestrates multiple MCP tools across distributed services using Akka's workflow engine.

## Resources

- [Akka Java SDK Documentation](https://doc.akka.io/java/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Previous: Building MCP Server in .NET]({{< relref "/blog/model-context-protocol/build-a-mcp-server/" >}})
- [GitHub Repository: agenticai-triage-mcp-tools](https://github.com/PradeepLoganathan/akka-kata/tree/main/akka-spovs/agenticai-triage-mcp-tools)
