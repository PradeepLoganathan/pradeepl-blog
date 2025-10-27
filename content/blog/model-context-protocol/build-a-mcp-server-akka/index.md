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

In previous posts of this [series]({{< relref "/series/model-context-protocol/" >}}), we explored building MCP servers using [.NET]({{< relref "/blog/model-context-protocol/build-a-mcp-server/" >}}) and [Java]({{< relref "/blog/model-context-protocol/build-a-mcp-server-java/" >}}). Now, let's explore a more enterprise-focused approach using the Akka Java SDK, which brings distributed systems capabilities and production-grade features to MCP server development.

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

We'll create an evidence gathering MCP server for an agentic AI triage system that provides:

- **Tools**: `fetch_logs`, `query_metrics`, and `correlate_evidence` for incident analysis
- **Resources**: Service runbooks accessible via URI templates (`kb://runbooks/{serviceName}`)
- **HTTP Endpoint**: Automatic JSON-RPC 2.0 endpoint at `/mcp`
- **Service Discovery**: Integration with Akka's dev-mode and production service discovery
- **Client Support**: Compatible with Claude Desktop, VS Code, and Akka agents

**Repository:** The code for this tutorial is available at [akka-spovs/agenticai-triage-mcp-tools](https://github.com/PradeepLoganathan/akka-kata/tree/main/akka-spovs/agenticai-triage-mcp-tools)

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

## Step 2: Implementing the MCP Endpoint

Create `src/main/java/com/pradeepl/evidence/EvidenceToolsEndpoint.java`:

```java
package com.pradeepl.evidence;

import akka.javasdk.annotations.Acl;
import akka.javasdk.annotations.Description;
import akka.javasdk.annotations.mcp.McpEndpoint;
import akka.javasdk.annotations.mcp.McpResource;
import akka.javasdk.annotations.mcp.McpTool;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * MCP Endpoint for Agentic AI Triage System - Evidence Gathering Tools
 */
@Acl(allow = @Acl.Matcher(principal = Acl.Principal.ALL))
@McpEndpoint(serverName = "evidence-tools", serverVersion = "1.0.0")
public class EvidenceToolsEndpoint {

    private static final Logger logger = LoggerFactory.getLogger(EvidenceToolsEndpoint.class);
    private static final ObjectMapper mapper = new ObjectMapper();

    @McpTool(
        name = "fetch_logs",
        description = "Fetch logs from the agentic AI triage system services (payment-service, checkout-service, auth-service, etc.). Returns recent log lines with automatic error analysis and anomaly detection."
    )
    public String fetchLogs(
            @Description("Service name to fetch logs from (e.g., payment-service, checkout-service)")
            String service,
            @Description("Number of log lines to fetch (default: 200)")
            int lines
    ) {
        logger.info("📝 MCP Tool: fetch_logs called - Service: {}, Lines: {}", service, lines);

        try {
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

            // Analyze logs for errors and patterns
            LogAnalysis analysis = analyzeLogs(recentLogs.toString());

            // Build structured JSON response
            ObjectNode response = mapper.createObjectNode();
            response.put("logs", recentLogs.toString());
            response.put("source", "classpath");
            response.put("service", service);
            response.put("linesReturned", actualLines);
            response.put("linesRequested", lines);

            // Add analysis
            ObjectNode analysisNode = mapper.createObjectNode();
            analysisNode.put("errorCount", analysis.errorCount);
            analysisNode.set("errorPatterns", mapper.valueToTree(analysis.errorPatterns));
            analysisNode.set("httpStatusCounts", mapper.valueToTree(analysis.statusCodeCounts));
            analysisNode.set("anomalies", mapper.valueToTree(analysis.anomalies));
            analysisNode.set("sampleErrorLines", mapper.valueToTree(analysis.sampleErrorLines));
            response.set("analysis", analysisNode);

            return mapper.writerWithDefaultPrettyPrinter().writeValueAsString(response);

        } catch (Exception e) {
            logger.error("📝 Error in fetch_logs", e);
            try {
                ObjectNode errorResponse = mapper.createObjectNode();
                errorResponse.put("error", "Failed to fetch logs: " + e.getMessage());
                errorResponse.put("service", service);
                return mapper.writeValueAsString(errorResponse);
            } catch (Exception jsonError) {
                return String.format("{\"error\":\"Failed to fetch logs: %s\"}", e.getMessage());
            }
        }
    }

    @McpTool(
        name = "query_metrics",
        description = "Query performance metrics for the agentic AI triage system services. Returns parsed metrics with insights and alerts."
    )
    public String queryMetrics(
            @Description("Metrics expression to query (e.g., error_rate, latency, cpu_usage)")
            String expr,
            @Description("Time range for the query (e.g., 1h, 30m, 5m)")
            String range
    ) {
        logger.info("📊 MCP Tool: query_metrics called - Expr: {}, Range: {}", expr, range);

        try {
            String fileName = determineMetricsFile(expr);
            InputStream inputStream = getClass().getClassLoader().getResourceAsStream(fileName);

            if (inputStream == null) {
                ObjectNode errorResponse = mapper.createObjectNode();
                errorResponse.put("error", String.format("No metrics file found for query: %s", expr));
                errorResponse.put("expr", expr);
                errorResponse.put("range", range);
                return mapper.writeValueAsString(errorResponse);
            }

            String metricsJson = new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
            JsonNode metricsData = mapper.readTree(metricsJson);

            // Parse and format metrics
            String formattedMetrics = formatMetricsOutput(metricsData, expr, range);
            List<String> insights = analyzeMetrics(metricsJson, expr);

            // Build structured response
            ObjectNode response = mapper.createObjectNode();
            response.put("raw", metricsJson);
            response.put("formatted", formattedMetrics);
            response.put("source", "classpath");
            response.put("expr", expr);
            response.put("range", range);
            response.set("insights", mapper.valueToTree(insights));

            return mapper.writerWithDefaultPrettyPrinter().writeValueAsString(response);

        } catch (Exception e) {
            logger.error("📊 Error in query_metrics", e);
            try {
                ObjectNode errorResponse = mapper.createObjectNode();
                errorResponse.put("error", "Failed to query metrics: " + e.getMessage());
                errorResponse.put("expr", expr);
                errorResponse.put("range", range);
                return mapper.writeValueAsString(errorResponse);
            } catch (Exception jsonError) {
                return String.format("{\"error\":\"Failed to query metrics: %s\"}", e.getMessage());
            }
        }
    }

    @McpTool(
        name = "correlate_evidence",
        description = "Correlate findings from logs and metrics to identify patterns, timeline alignment, and root causes."
    )
    public String correlateEvidence(
            @Description("Description of log findings") String logFindings,
            @Description("Description of metric findings") String metricFindings
    ) {
        logger.info("🔗 MCP Tool: correlate_evidence called");

        try {
            ObjectNode response = mapper.createObjectNode();
            response.put("logFindings", logFindings);
            response.put("metricFindings", metricFindings);

            // Build correlation analysis
            ObjectNode correlation = mapper.createObjectNode();
            correlation.put("timelineAlignment",
                "Analyze temporal alignment between error spikes and performance degradation");
            correlation.put("dependencyFailures",
                "Check if service dependency failures coincide with error increases");
            correlation.put("resourceExhaustion",
                "Correlate resource exhaustion patterns with error patterns");

            ObjectNode confidence = mapper.createObjectNode();
            confidence.put("level", "Medium");
            confidence.put("reasoning",
                "Confidence is HIGH if patterns align temporally, MEDIUM if partial alignment, LOW if no clear correlation");

            response.set("potentialCorrelations", correlation);
            response.set("confidence", confidence);

            return mapper.writerWithDefaultPrettyPrinter().writeValueAsString(response);

        } catch (Exception e) {
            logger.error("🔗 Error in correlate_evidence", e);
            return String.format("{\"error\":\"Failed to correlate evidence: %s\"}", e.getMessage());
        }
    }

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

    // Helper record for log analysis
    private record LogAnalysis(
        int errorCount,
        List<String> errorPatterns,
        Map<String, Integer> statusCodeCounts,
        List<String> anomalies,
        List<String> sampleErrorLines
    ) {}

    // Helper methods for log analysis, metrics parsing, etc.
    // (Implementation details omitted for brevity - see full code in repository)

    private LogAnalysis analyzeLogs(String logs) {
        // Analysis implementation...
        return new LogAnalysis(0, List.of(), Map.of(), List.of(), List.of());
    }

    private String determineMetricsFile(String expr) {
        // Route to appropriate metrics file based on expression
        return "metrics/payment-service-errors.json";
    }

    private String formatMetricsOutput(JsonNode metricsData, String expr, String range) {
        // Format metrics for display
        return "Metrics summary...";
    }

    private List<String> analyzeMetrics(String metrics, String expr) {
        // Extract insights from metrics
        return List.of("Analysis insights...");
    }
}
```

### Understanding the Annotations

Let's break down the key annotations that make this an MCP endpoint:

**`@McpEndpoint(serverName = "evidence-tools", serverVersion = "1.0.0")`**
- Declares this class as an MCP server endpoint
- `serverName`: Identifier used by clients and service discovery
- `serverVersion`: Version information exposed to clients
- Automatically creates an HTTP endpoint at `/mcp`

**`@Acl(allow = @Acl.Matcher(principal = Acl.Principal.ALL))`**
- Access Control List allowing all clients to access this endpoint
- In production, you'd restrict this to authenticated principals

**`@McpTool(name = "...", description = "...")`**
- Marks a method as an MCP tool
- `name`: Tool identifier used by clients
- `description`: Helps AI models understand when to use this tool
- Method parameters become tool arguments
- Return value becomes tool response

**`@Description("...")`**
- Documents individual parameters
- Critical for AI models to understand argument purpose
- Similar to JSON schema descriptions in other MCP implementations

**`@McpResource(uriTemplate = "...", ...)`**
- Exposes data through URI-based access
- `uriTemplate`: Path pattern with variables (e.g., `kb://runbooks/{serviceName}`)
- `mimeType`: Content type of the resource
- Method parameters are extracted from URI template variables

## Step 3: Creating Sample Data

Create directory structure for sample logs and metrics:

```bash
mkdir -p src/main/resources/logs
mkdir -p src/main/resources/metrics
mkdir -p src/main/resources/knowledge_base
```

Create `src/main/resources/logs/payment-service.log`:

```
2025-01-15 14:28:45.123 INFO  [payment-service] Processing payment request
2025-01-15 14:28:45.234 ERROR [payment-service] Payment gateway timeout
2025-01-15 14:28:50.567 ERROR [payment-service] Payment gateway timeout
2025-01-15 14:29:15.789 ERROR [payment-service] Database connection refused
```

Create `src/main/resources/metrics/payment-service-errors.json`:

```json
{
  "query": "errors:rate5m",
  "time_range": "1h",
  "timestamp": "2025-01-15T14:30:00Z",
  "metrics": {
    "error_rate": {
      "current": 15.3,
      "previous_hour": 2.1,
      "threshold": 5.0,
      "status": "elevated"
    },
    "error_count": {
      "total": 342,
      "by_type": {
        "connection_timeout": 156,
        "database_error": 89,
        "payment_gateway_error": 67
      }
    }
  }
}
```

Create `src/main/resources/knowledge_base/payment-runbook.md`:

```markdown
# Payment Service Runbook

## Common Issues

### Gateway Timeouts
- Check gateway health endpoint
- Review connection pool settings
- Verify network connectivity

### Database Connection Errors
- Check connection pool capacity
- Review active connections
- Verify database health
```

## Step 4: Running the MCP Server

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

## Step 5: Integration with MCP Clients

### Claude Desktop Integration

Create or edit `claude_desktop_config.json`:

**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows:** `%APPDATA%/Claude/claude_desktop_config.json`

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

This configuration uses a Node.js one-liner to bridge STDIO (which Claude Desktop uses) to our HTTP endpoint.

Restart Claude Desktop and test with prompts like:
- "Fetch logs for the payment service and analyze errors"
- "Query error rate metrics for the last hour"
- "Correlate the log and metric findings"

### VS Code Integration

Create `.vscode/mcp.json`:

```json
{
  "servers": {
    "evidence-tools": {
      "type": "http",
      "url": "http://localhost:9200/mcp"
    }
  }
}
```

Or use the Node.js bridge approach similar to Claude Desktop:

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

Reload VS Code, open Copilot Chat in Agent mode, and the evidence tools should be available.

## Step 6: Integration with Akka Agents

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
- [Previous: Building MCP Server in Java]({{< relref "/blog/model-context-protocol/build-a-mcp-server-java/" >}})
- [Previous: Building MCP Server in .NET]({{< relref "/blog/model-context-protocol/build-a-mcp-server/" >}})
- [GitHub Repository: agenticai-triage-mcp-tools](https://github.com/PradeepLoganathan/akka-kata/tree/main/akka-spovs/agenticai-triage-mcp-tools)
