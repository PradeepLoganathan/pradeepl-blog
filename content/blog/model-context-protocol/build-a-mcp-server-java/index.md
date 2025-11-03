---
title: "Building an MCP Server in Java"
lastmod: 2025-01-14T14:29:22+10:00
date: 2025-01-14T14:29:22+10:00
draft: true
Author: Pradeep Loganathan
tags: 
  - ai
  - llm
  - integration
  - model-context-protocol
  - developer-tools
  - java
categories:
  - AI Architecture
  - Agent Systems
  - DevTools
description: "Learn how to build an MCP server in Java using the official Java SDK, with both STDIO and HTTP transport options for log aggregation tools."
summary: "This guide demonstrates building an MCP server in Java with Maven, implementing log aggregation tools, and integrating with MCP clients using both STDIO and HTTP transports."
ShowToc: true
TocOpen: true
cover:
    image: "images/mcp-server-java-cover.webp"
    alt: "Building MCP Server in Java"
    caption: "Building MCP Server in Java"
    relative: true
series: ["Model Context Protocol"]
---

## Introduction

In the [previous post]({{< relref "/blog/model-context-protocol/build-a-mcp-server/" >}}) of this [series]({{< relref "/series/model-context-protocol/" >}}), we looked at the basics of the Model context protocol and also built an MCP server using C# (.NET) with string manipulation tools. Now let's explore how to build an MCP server using Java and the official MCP Java SDK.

We'll create a log aggregation MCP server that provides tools to fetch logs from different sources like Datadog, Elasticsearch, or local files. This server will demonstrate both STDIO and HTTP transport options, making it versatile for different deployment scenarios.

## What You'll Build

Our Java MCP server will provide:
- A `get_logs` tool that can fetch logs from multiple sources (Datadog, Elasticsearch, local files)
- Support for both STDIO and HTTP/SSE transports
- Mock implementations for external log sources
- Real file reading capabilities for local log files
- Integration with VS Code (GitHub Copilot) and Claude Desktop

**Repository:** [https://github.com/PradeepLoganathan/spov-mcp-logs-server](https://github.com/PradeepLoganathan/spov-mcp-logs-server)

## Prerequisites

Before starting, ensure you have:
- **JDK 17+** (Java 21 recommended for optimal performance)
- **Maven 3.8+** for dependency management
- **VS Code** with GitHub Copilot Chat extension
- **Claude Desktop** (optional, for additional testing)
- Basic familiarity with Java and Maven

> **Transport Note:** The Java MCP SDK supports STDIO, SSE, and HTTP transports. We'll primarily use STDIO as it allows clients to spawn our server as a child process without network configuration.

## Step 1: Project Setup

Clone the sample and build it:

```bash
git clone https://github.com/PradeepLoganathan/spov-mcp-logs-server
cd spov-mcp-logs-server
mvn -q -DskipTests package
```

If you're creating a project from scratch, here's the essential `pom.xml` configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.spov.mcp</groupId>
  <artifactId>logs-server</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>

  <properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.modelcontextprotocol</groupId>
      <artifactId>server</artifactId>
      <version>0.5.0</version>
    </dependency>
    <dependency>
      <groupId>org.eclipse.jetty</groupId>
      <artifactId>jetty-server</artifactId>
      <version>11.0.24</version>
    </dependency>
    <dependency>
      <groupId>org.eclipse.jetty</groupId>
      <artifactId>jetty-servlet</artifactId>
      <version>11.0.24</version>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.5.1</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals><goal>shade</goal></goals>
            <configuration>
              <createDependencyReducedPom>false</createDependencyReducedPom>
              <transformers>
                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                  <mainClass>com.spov.mcp.logs.sdk.SdkMain</mainClass>
                </transformer>
              </transformers>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

## Step 2: Building the MCP Server

### Core Server Implementation (STDIO)

Create `src/main/java/com/spov/mcp/logs/sdk/SdkMain.java`:

```java
package com.spov.mcp.logs.sdk;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.modelcontextprotocol.server.McpServer;
import io.modelcontextprotocol.server.McpServerFeatures;
import io.modelcontextprotocol.server.McpSyncServer;
import io.modelcontextprotocol.server.transport.StdioServerTransportProvider;
import io.modelcontextprotocol.spec.McpSchema;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public final class SdkMain {
    public static void main(String[] args) {
        var transport = new StdioServerTransportProvider(new ObjectMapper());

        var getLogsSchema = """
            {
              "type": "object",
              "properties": {
                "source": {"type": "string", "enum": ["datadog","elastic","file"]}
              },
              "required": ["source"]
            }
        """;

        var getLogsTool = new McpServerFeatures.SyncToolSpecification(
                new McpSchema.Tool("get_logs", "Return logs from source (mock/file)", getLogsSchema),
                (exchange, arguments) -> {
                    String source = "file";
                    Object src = (arguments != null) ? arguments.get("source") : null;
                    if (src != null) source = String.valueOf(src);
                    String text = switch (source) {
                        case "datadog" -> sampleDatadog();
                        case "elastic" -> sampleElastic();
                        case "file" -> readLogFile();
                        default -> "Unknown source: " + source;
                    };
                    List<McpSchema.Content> contents = new ArrayList<>();
                    contents.add(new McpSchema.TextContent(text));
                    return new McpSchema.CallToolResult(contents, false);
                }
        );

        McpSyncServer server = McpServer.sync(transport)
                .serverInfo("spov-mcp-logs-server", "1.0.0")
                .capabilities(McpSchema.ServerCapabilities.builder()
                        .tools(true)
                        .logging()
                        .build())
                .tools(getLogsTool)
                .build();

        try {
            Thread.currentThread().join();
        } catch (InterruptedException e) {
            server.close();
        }
    }

    private static String readLogFile() {
        String path = System.getenv("LOGS_FILE_PATH");
        if (path == null || path.isBlank()) return "Set LOGS_FILE_PATH to read a local log file.";
        try {
            var p = Path.of(path).toAbsolutePath().normalize();
            if (!Files.exists(p) || !Files.isRegularFile(p)) return "File not found: " + path;
            return Files.readString(p).lines().skip(Math.max(0, Files.lines(p).count() - 1000))
                    .collect(java.util.stream.Collectors.joining(System.lineSeparator()));
        } catch (Exception e) {
            return "Error reading file: " + e.getMessage();
        }
    }

    private static String sampleDatadog() {
        return "{\n" +
                "  \"source\": \"datadog\",\n" +
                "  \"entries\": [\n" +
                "    { \"ts\": \"2025-01-14T11:00:00Z\", \"level\": \"INFO\", \"msg\": \"Service started\" },\n" +
                "    { \"ts\": \"2025-01-14T11:02:41Z\", \"level\": \"WARN\", \"msg\": \"Slow query detected\" }\n" +
                "  ]\n" +
                "}";
    }

    private static String sampleElastic() {
        return "{\n" +
                "  \"source\": \"elasticsearch\",\n" +
                "  \"entries\": [\n" +
                "    { \"ts\": \"2025-01-14T11:03:12Z\", \"level\": \"ERROR\", \"msg\": \"Index write failed\" },\n" +
                "    { \"ts\": \"2025-01-14T11:04:05Z\", \"level\": \"INFO\", \"msg\": \"Retry succeeded\" }\n" +
                "  ]\n" +
                "}";
    }
}
```

### How It Works

* **Transport:** `StdioServerTransportProvider` enables client-server communication over stdin/stdout
* **Tool Schema:** `get_logs` accepts a `source` enum parameter with precise allowed values
* **Handler:** Switches by source type and returns appropriate log data
* **Output:** Returns `CallToolResult` with `TextContent` for client compatibility
* **Capabilities:** Exposes tool metadata and enables server-side logging
* **Lifecycle:** Uses `Thread.currentThread().join()` to keep the server alive

### HTTP/SSE Transport Alternative

For remote hosting or multiple client scenarios, create `src/main/java/com/spov/mcp/logs/sdk/HttpMain.java`:

```java
package com.spov.mcp.logs.sdk;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.modelcontextprotocol.server.McpServer;
import io.modelcontextprotocol.server.McpServerFeatures;
import io.modelcontextprotocol.server.McpSyncServer;
import io.modelcontextprotocol.server.transport.HttpServletSseServerTransportProvider;
import io.modelcontextprotocol.spec.McpSchema;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public final class HttpMain {
    public static void main(String[] args) {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
        
        var transport = new HttpServletSseServerTransportProvider(
                new ObjectMapper(),
                "/mcp"
        );

        var getLogsSchema = """
            {
              "type": "object",
              "properties": {
                "source": {"type": "string", "enum": ["datadog","elastic","file"]}
              },
              "required": ["source"]
            }
        """;

        var getLogsTool = new McpServerFeatures.SyncToolSpecification(
                new McpSchema.Tool("get_logs", "Return logs from source (mock/file)", getLogsSchema),
                (exchange, arguments) -> {
                    String source = "file";
                    Object src = (arguments != null) ? arguments.get("source") : null;
                    if (src != null) source = String.valueOf(src);
                    String text = switch (source) {
                        case "datadog" -> sampleDatadog();
                        case "elastic" -> sampleElastic();
                        case "file" -> readLogFile();
                        default -> "Unknown source: " + source;
                    };
                    List<McpSchema.Content> contents = new ArrayList<>();
                    contents.add(new McpSchema.TextContent(text));
                    return new McpSchema.CallToolResult(contents, false);
                }
        );

        McpSyncServer mcpServer = McpServer.sync(transport)
                .serverInfo("spov-mcp-logs-server", "1.0.0")
                .capabilities(McpSchema.ServerCapabilities.builder()
                        .tools(true)
                        .logging()
                        .build())
                .tools(getLogsTool)
                .build();

        Server server = new Server(port);
        ServletContextHandler context = new ServletContextHandler(ServletContextHandler.SESSIONS);
        context.setContextPath("/");
        server.setHandler(context);
        context.addServlet(new ServletHolder(transport), "/mcp/*");

        try {
            server.start();
            System.out.println("MCP HTTP server started on http://localhost:" + port + "/mcp");
            server.join();
        } catch (Exception e) {
            throw new RuntimeException("Failed to start HTTP server", e);
        }
    }

    private static String readLogFile() {
        String path = System.getenv("LOGS_FILE_PATH");
        if (path == null || path.isBlank()) return "Set LOGS_FILE_PATH to read a local log file.";
        try {
            var p = Path.of(path).toAbsolutePath().normalize();
            if (!Files.exists(p) || !Files.isRegularFile(p)) return "File not found: " + path;
            return Files.readString(p).lines().skip(Math.max(0, Files.lines(p).count() - 1000))
                    .collect(java.util.stream.Collectors.joining(System.lineSeparator()));
        } catch (Exception e) {
            return "Error reading file: " + e.getMessage();
        }
    }

    private static String sampleDatadog() {
        return "{\n" +
                "  \"source\": \"datadog\",\n" +
                "  \"entries\": [\n" +
                "    { \"ts\": \"2025-01-14T11:00:00Z\", \"level\": \"INFO\", \"msg\": \"Service started\" },\n" +
                "    { \"ts\": \"2025-01-14T11:02:41Z\", \"level\": \"WARN\", \"msg\": \"Slow query detected\" }\n" +
                "  ]\n" +
                "}";
    }

    private static String sampleElastic() {
        return "{\n" +
                "  \"source\": \"elasticsearch\",\n" +
                "  \"entries\": [\n" +
                "    { \"ts\": \"2025-01-14T11:03:12Z\", \"level\": \"ERROR\", \"msg\": \"Index write failed\" },\n" +
                "    { \"ts\": \"2025-01-14T11:04:05Z\", \"level\": \"INFO\", \"msg\": \"Retry succeeded\" }\n" +
                "  ]\n" +
                "}";
    }
}
```

## Step 3: Testing and Building

### Building and Running

Build your server:
```bash
mvn clean package
```

Run the STDIO version:
```bash
export LOGS_FILE_PATH=/path/to/your/logfile.log
java -jar target/spov-mcp-logs-server-1.0.0.jar
```

Run the HTTP version:
```bash
PORT=8080 LOGS_FILE_PATH=/path/to/your/logfile.log java -cp target/spov-mcp-logs-server-1.0.0.jar com.spov.mcp.logs.sdk.HttpMain
```

## Step 4: Integration with VS Code and GitHub Copilot

### Configuring VS Code Integration

Create (or open) your user MCP config via **Command Palette → "MCP: Open User Configuration"** and add:

```json
{
  "servers": {
    "spov-mcp-logs": {
      "type": "stdio",
      "command": "java",
      "args": ["-jar", "/ABSOLUTE/PATH/TO/target/spov-mcp-logs-server-1.0.0.jar"],
      "env": {
        "LOGS_FILE_PATH": "/absolute/path/to/your/logs/app.log"
      }
    }
  }
}
```

Reload VS Code → open **Copilot Chat** → switch to **Agent mode**.

Try prompts like:
- "Run `get_logs` with `source=file` and summarize errors."
- "Call `get_logs` with `source=datadog` and extract WARN/ERROR counts."

### Integration with Claude Desktop

Create or edit `claude_desktop_config.json`:

* **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
* **Windows:** `%APPDATA%/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "spov-mcp-logs": {
      "command": "java",
      "args": ["-jar", "/full/path/to/target/spov-mcp-logs-server-1.0.0.jar"],
      "env": {
        "LOGS_FILE_PATH": "/path/to/your/logfile.log"
      }
    }
  }
}
```

Restart Claude Desktop and test with similar prompts.

## Step 5: Troubleshooting

### Common Issues

* **`Unknown source:` messages** → Only `datadog`, `elastic`, and `file` are supported
* **Client can't find the JAR** → Use **absolute paths** in configuration files
* **JDK mismatch** → Ensure `java -version` shows **17+** (prefer 21)
* **No tools listed** → Verify tool registration and JSON schema validity
* **`LOGS_FILE_PATH` not set** → Set the environment variable for file mode

## Key Differences from .NET Implementation

Compared to the C# version from our previous post, the Java implementation has several notable differences:

1. **Manual Tool Registration**: Java requires explicit tool registration using `McpServerFeatures.SyncToolSpecification`, whereas .NET uses attribute-based discovery with `[McpServerTool]`
2. **Schema Definition**: JSON schemas must be defined as string literals rather than being inferred from method signatures
3. **Transport Configuration**: More verbose setup for different transport types compared to .NET's fluent configuration API
4. **Lifecycle Management**: Manual thread management using `Thread.currentThread().join()` to keep the server alive
5. **Dependency Injection**: Less integrated DI support compared to .NET's built-in hosting framework

## What's Next?

Your Java MCP server is now ready for integration with MCP clients. Consider these enhancements:

- **Real Integrations**: Replace mock methods with actual Datadog/Elasticsearch clients
- **Configuration**: Add proper configuration management with properties files
- **Logging**: Implement structured logging with SLF4J and Logback
- **Error Handling**: Add comprehensive error handling and validation
- **Testing**: Create unit and integration tests
- **Resources**: Add MCP resources for streaming log data
- **Prompts**: Create server-provided templates for common log analysis tasks
- **Deployment**: Package as Docker containers for cloud deployment

## Conclusion

Building MCP servers in Java provides excellent performance and enterprise-grade capabilities. The official Java SDK offers flexibility in transport options and integrates well with existing Java ecosystems. Whether you choose STDIO for local development or HTTP for production deployments, Java's robust platform makes it an excellent choice for building scalable MCP servers.

Key takeaways from this implementation:
- Java MCP servers require more explicit configuration compared to .NET
- The SDK supports multiple transport protocols for different deployment scenarios
- Integration with development tools like VS Code and Claude Desktop is straightforward
- The server can easily be extended with additional tools and capabilities

In future posts, we'll explore advanced MCP concepts like resources and prompts, and discuss deployment strategies for production environments.

## Resources

- [Previous post: Building a simple MCP Server (.NET)]({{< relref "/blog/model-context-protocol/build-a-mcp-server/" >}})
- [GitHub Repository: spov-mcp-logs-server](https://github.com/PradeepLoganathan/spov-mcp-logs-server)
- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [Java MCP SDK Documentation](https://github.com/modelcontextprotocol/java-sdk)