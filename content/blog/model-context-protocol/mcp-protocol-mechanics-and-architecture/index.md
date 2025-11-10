---
title: "MCP - Protocol Mechanics and Architecture"
lastmod: 2025-05-01T19:03:33+10:00
date: 2025-05-01T19:03:33+10:00
draft: false # Ready for publishing
Author: Pradeep Loganathan
tags:
  - Model Context Protocol
  - AI Protocols
  - JSON-RPC
  - API Design
categories:
  - AI Development
#slug: kubernetes/introduction-to-open-policy-agent-opa/ # Commented out slug if not needed or incorrect
description: "Dive deep into the technical architecture and mechanics of the Model Context Protocol (MCP), an open standard for connecting AI models to external tools and data sources using JSON-RPC 2.0." # Example description
summary: "Part 2 of our MCP series explores the technical foundations: JSON-RPC communication, supported transports (STDIO, HTTP/SSE, WebSockets), capability discovery (tools, resources, prompts), invocation methods, and security principles." # Example summary
ShowToc: true
TocOpen: true
images:
  - images/MCP-technical-details.png
cover:
  image: "images/MCP-technical-details.png" 
  alt: "MCP - Protocol Mechanics and Architecture" 
  caption: "MCP - Protocol Mechanics and Architecture" 
  relative: true
series: ["Model Context Protocol"]
mermaid: true
weight: 2
aliases:
  - "/blog/model-context-protocol/protocol-mechanics-and-architecture/"
---

{{< series-toc >}} 


Welcome back to our series on the [Model Context Protocol (MCP)]({{< relref "/series/model-context-protocol/" >}})! In [Part 1]({{< relref "/blog/model-context-protocol/introduction-to-model-context-protocol/">}}), we established the 'why' behind MCP, starting with the complex 'M x N' integration problem. We introduced MCP as an open standard designed to simplify this landscape and foster a more interoperable ecosystem. But we didn't just cover the why. We also explored the **'what'**: the core primitives of tools, resources, and prompts. We saw how these building blocks provide a powerful and extensible framework for AI agents to plan, execute, and adapt.

This post, Part 2, shifts gears from the **'why' to the 'how'**. We'll dive deep into the technical architecture that powers MCP, dissecting the protocol's mechanics piece by piece. Understanding these underlying components is crucial for developers aiming to build robust MCP servers or integrate MCP clients into their AI applications. We will examine how MCP structures its messages, the data formats and transports it uses, and how it represents capabilities like tools and resources. By the end, you'll have a detailed understanding of MCP's architecture, preparing you for the step-by-step server implementation in Part 3. 

Before we dive into the message formats and transport layers, let's quickly recall the high-level architecture we introduced in [Part 1]({{< relref "/blog/model-context-protocol/introduction-to-model-context-protocol/">}}). The Model Context Protocol defines a clear client-server relationship:

{{< mermaid >}}

graph TD;

  subgraph MCP Host
    App[AI-Enabled Application];
    LLM[Large Language Model];
    MCPClient[MCP Client]; 

    
    App --> |Uses| LLM;
    App --> |Manages| MCPClient; 
    LLM --> |Requests Capability| MCPClient;
  end


  subgraph MCP Server Layer
    Ingress[/ HTTP Ingress / API Gateway/]
    Router[MCP Request Router];
    ContextStore[(Context & Schema Store)];
    Handler[MCP Core Handler];
    subgraph Adapters
      APIAdapter[API Adapter];
      DBAdapter[Database Adapter];
      ToolAdapter[Tool Adapter];
    end
  end
  subgraph External Systems
    ExternalAPI[External API Service];
    Database[Database];
    Tool[Third-Party Tool];
  end


  MCPClient --> |MCP Request| Ingress;

  
  Ingress -->|Route| Router;
  Router -->|Handle| Handler;
  Handler -->|Lookup| ContextStore;
  Handler -->|Call API| APIAdapter;
  Handler -->|Call DB| DBAdapter;
  Handler -->|Call Tool| ToolAdapter;


  APIAdapter -->|Invoke| ExternalAPI;
  DBAdapter -->|Query| Database;
  ToolAdapter -->|Invoke| Tool;

  ExternalAPI -->|Response| APIAdapter;
  Database -->|Response| DBAdapter;
  Tool -->|Response| ToolAdapter;


  Handler --> |Normalized Response| MCPClient;
  MCPClient --> |Provides Result| LLM; 
  LLM --> |Generates Answer| App; 
{{< /mermaid >}}

* The **MCP Host** is the AI-enabled application or runtime (like a chatbot or IDE) that needs external context.
* The **MCP Client** resides within the Host and acts as the intermediary, managing the connection and handling the MCP protocol specifics.
* The **MCP Server** exposes external capabilities (Tools, Resources, Prompts) and communicates with the client over a defined transport.

## Communication Foundation: JSON-RPC 2.0

Now that we've set the stage, let's begin our technical exploration by examining the very foundation of MCP communication: how do the different components – the Host application, the MCP Client, and the MCP Server – actually talk to each other?  To ensure consistency and interoperability across the diverse ecosystem of AI applications and tools, MCP relies on a well-established standard for structuring these conversations. This brings us to the protocol's core communication mechanism.

The communication between MCP Clients and Servers is built upon the **JSON-RPC 2.0** specification. This choice provides several advantages:

- **Standardization:** It leverages a well-defined, widely implemented, and understood remote procedure call protocol.
- **Simplicity:** JSON-RPC 2.0 defines a relatively straightforward structure for requests, responses, and notifications.
- **Data Format:** It utilizes JSON (JavaScript Object Notation) for message serialization, which is human-readable, easily parsed across numerous programming languages, and inherently compatible with web technologies.
- **Proven Foundation:** The protocol explicitly draws inspiration from the Language Server Protocol (LSP), which also successfully employs JSON-RPC to standardize communication between development tools and language servers.

By adopting JSON-RPC, MCP avoids reinventing fundamental RPC mechanisms. This strategic decision likely accelerated the development of MCP SDKs across various languages and lowers the adoption barrier, allowing the protocol's focus to remain on the specific semantics of AI context exchange.

## Structured JSON Messages in MCP

As discussed above, all MCP communications are built on structured messages following the JSON-RPC 2.0 standard. Let's look at a compact example, followed by an explanation of each field.

Example: JSON-RPC Request (tools/call)
```json
{
  "jsonrpc": "2.0",
  "id": 123,
  "method": "tools/call",
  "params": {
    "name": "search_web",
    "arguments": {
      "query": "latest AI news"
    }
  }
}
```

The above example is an MCP call for a tool called search_web with the parameter "latest AI news". Let us look at the key fields.

- **`jsonrpc` (version):** Specifies the protocol version (always "2.0" for JSON-RPC 2.0). This ensures both sides interpret the message format the same way.
- **`id` (identifier):** A unique ID for pairing requests with responses. It can be a number or string and is omitted for one‑way notifications.
- **`method`:** Name of the method or notification. Examples: `initialize`, `tools/list`, `tools/call`, `$/progress`, `$/cancelRequest`. Required for Requests and Notifications.
- **`params` (or `payload`/`data`):** Inputs needed to perform the method (object or array). Optional if not needed.
- **`result`:** Present on a successful Response; must not appear with `error`.
- **`error`:** Present on a failed Response; must not appear with `result`. Contains:
  - **`code`** (Integer): error type (standard JSON‑RPC codes or custom).
  - **`message`** (String): short description of the error.
  - **`data`** (optional): extra details.

These fields make MCP messages self-descriptive. The presence or absence of fields determines the message type: a message with `method` and `id` is a Request; a message with `result` or `error` and an `id` is a Response; a message with `method` but no `id` is a Notification.

## MCP Transport Layers and Connection Flows

The Model Context Protocol (MCP) is **transport-agnostic**, meaning it can operate over any channel capable of carrying JSON text. This flexibility allows MCP to support multiple transport layers. It supports Standard Input/Output (STDIO), HTTP with Server-Sent Events (SSE), and WebSockets. Let's now look at these transport mechanisms, their connection flows, message framing, and their strengths and limitations.

### Transport Layers

MCP supports three primary transport layers, each designed to balance latency, infrastructure compatibility, and interactivity:

- **Standard Input/Output (STDIO):**\
    STDIO leverages a process's stdin and stdout streams for communication, typically when the MCP server runs as a local subprocess of the host application.

    - **Pros:** Extremely low latency (microseconds) due to no network overhead, simple setup for local plugins, and inherits OS-level security (only the user's process can access it).
    - **Cons:** Limited to local connections (cannot easily connect to remote servers), and requires the host to manage the server process lifecycle.
    - **Use Cases:** Local integrations, such as an AI assistant spawning a tool-access server on the same machine to securely access the local filesystem or databases.

- **HTTP + Server-Sent Events (SSE):**\
    This transport uses standard HTTP requests for client-to-server communication and a long-lived SSE connection for server-to-client streaming. It's ideal for remote servers and one-way data streaming.

    - **Pros:** Compatible with existing web infrastructure (e.g., proxies), supports real-time incremental results via server push, and works with web clients that cannot initiate arbitrary sockets.
    - **Cons:** SSE is unidirectional (server-to-client only), requiring separate HTTP POST requests for client-to-server communication. Managing dual channels (HTTP + SSE) adds complexity, and long-lived SSE connections may require special handling with load balancers or proxies.
    - **Use Cases:** Cloud-based or remote MCP servers, such as an AI assistant connecting to a cloud data source that streams results as they become available (e.g., in a browser environment).
    - **Note:** MCP is exploring *Streamable HTTP* to unify HTTP+SSE into a single connection with streaming capabilities. As of the 2025 spec, SSE remains the primary HTTP streaming method, but future iterations may enhance this.

-   **WebSockets:**\
    WebSockets provide a persistent, full-duplex connection for bidirectional communication with low latency (milliseconds).

    - **Pros:** True real-time two-way communication, single connection management, and efficient for interactive or high-frequency message exchanges.
    - **Cons:** Requires WebSocket support, which may be restricted in some corporate networks, and involves slight overhead during connection handshaking.
    - **Use Cases:** Interactive scenarios or long-running connections, such as an AI-powered IDE continuously interacting with a tool server for spontaneous notifications and commands.

MCP's JSON message format remains consistent across all transports, tunneled through the chosen mechanism. The choice of transport depends on deployment needs: STDIO for local plugins, HTTP+SSE for web-friendly streaming, and WebSockets for full-duplex interactivity.

### Connection Flows and Message Framing

Each transport defines how MCP messages are exchanged and framed (delimited) on the wire, ensuring reliable, ordered delivery of JSON-RPC messages. Below is an overview of the connection flows and framing for each transport:

- **STDIO Transport:**

    - **Connection Flow:** Used when the MCP client (within the host application) and server run on the same machine. The host application launches the server as a subprocess and wires its stdin/stdout streams to the MCP client. Communication occurs entirely over these pipes, effectively forming the connection.
    - **Message Framing:** JSON-RPC messages are exchanged over stdin/stdout. Simple implementations may separate messages with newlines, but robust systems may use explicit framing, prefixing each JSON message with headers like Content-Length: NNN\r\n\r\n, followed by the JSON payload. This ensures accurate message delimitation, especially for large messages.
    - **Use Case Example:** A local tool server handling file system operations or Git commands, where the host manages the server's lifecycle.

- **HTTP + SSE Transport:**

    - **Connection Flow:** Supports communication between clients and servers on the same or different machines. The MCP server runs independently, exposing an HTTP endpoint (e.g., http://localhost:3000/mcp). The client initiates a standard HTTP connection, and the server uses SSE to push JSON-RPC messages asynchronously over a persistent connection.
    - **Message Framing:** SSE uses a text-based framing protocol. Messages are sent as "events" with fields like event: message_type (optional), data: json_payload, id: (optional), and retry: (optional). Each field is a line, and events are terminated by a double newline (\n\n). MCP JSON-RPC messages are encoded as JSON strings within the data: field of an SSE event. Clients send commands via separate HTTP POST requests to the server's endpoint (e.g., /mcp).
    - **Use Case Example:** A web-based client accessing a remote MCP server for shared services or APIs, with the server streaming results back.

-   **WebSockets Transport:**

    - **Connection Flow:** A single WebSocket connection is established, enabling full-duplex communication. The client connects to the server's WebSocket endpoint, and both parties can send messages at any time after the handshake.
    - **Message Framing:** WebSockets naturally carry JSON text frames bidirectionally. Each MCP JSON-RPC message is sent as a single WebSocket frame, with no additional framing required beyond the WebSocket protocol's built-in message boundaries.
    - **Use Case Example:** An interactive AI IDE sending commands and receiving spontaneous server notifications over a single, low-latency connection.

### Transport Abstraction

MCP's design ensures the higher-level protocol (JSON-RPC + capabilities) remains consistent across transports. Developers can switch transports as an example, from STDIO during development to WebSockets in production without altering the core logic of their MCP client or server. SDKs or transport handlers abstract away the details of framing and connection management, allowing seamless transitions between transports based on deployment requirements.

## Capabilities in MCP: Tools, Resources, and Prompts

Now that we understand the communication foundation and how messages are transmitted, let's walk through an MCP session from start to finish. The lifecycle follows a logical order:

1. **Handshake:** The client and server connect and agree on capabilities.  
2. **Discovery:** The client asks the server *what* it can do.  
3. **Invocation:** The client asks the server to *do* something.

We will look at these in logical order of steps below. 

### Step 1: The Handshake (Connection Establishment)

Establishing a connection in MCP involves both setting up the transport (STDIO, HTTP+SSE, or WebSocket) and performing a protocol handshake. Once the low-level connection is open, the **MCP handshake** occurs at the JSON-RPC level:

1. **Client initialize Request:** The client (host application) sends an initialize JSON-RPC **request** to the server. This message includes the MCP protocol version, client identification, the client's supported capability categories, and optionally a set of allowed resource roots.  

```json
{  
  "jsonrpc": "2.0",  
  "id": "1",  
  "method": "initialize",  
  "params": {  
    "protocolVersion": "1.0",  
    "clientInfo": {  
      "name": "ExampleHostApp",  
      "version": "1.2.0"  
    },  
    "capabilities": {  
      "tools": {},  
      "resources": {},  
      "prompts": {}  
    },  
    "roots": [  
      { "uri": "file:///workspace", "name": "workspace" }  
    ]  
  }  
}
```
2. **Server initialize Response:** The server responds with a JSON-RPC **response** containing its details, such as the capability types it supports (e.g., resources, tools) and server identification. This capability negotiation allows the client to adjust its behavior and is designed for backwards-compatibility.
```json
 {  
   "jsonrpc": "2.0",  
   "id": "1",  
   "result": {  
     "protocolVersion": "1.0",  
     "capabilities": {  
       "tools": {},  
       "resources": {},  
       "prompts": {}  
     },  
     "serverInfo": {  
       "name": "SampleMCPServer",  
       "version": "0.1.0"  
     }  
   }  
 }
```
3. **Client initialized Notification:** After receiving a successful initialize result, the client sends an `initialized` notification (no id) to signal that the connection is fully established and ready for use.


{{< mermaid >}}
sequenceDiagram
    title MCP Session Initialization
    participant Client
    participant Server

    Note over Client,Server: MCP = Model Context Protocol

    Client->Server: initialize Request<br>{"id": 1, "method": "initialize", "params": {...}}
    activate Server
    alt Success
        Server-->Client: initialize Response<br>{"id": 1, "result": {"capabilities": {...}, "serverInfo": {...}}}
    else Failure
        Server-->Client: Error Response<br>{"id": 1, "error": {"code": -32000, "message": "Server not ready"}}
    end
    deactivate Server

    Client->Server: initialized Notification<br>{"method": "initialized", "params": {}}

    Note right of Server: MCP Session is now established
{{< /mermaid >}}

### Step 2: Capability Discovery

At this point, the MCP session is live. The next step is usually **capability discovery**: the client will call the listing methods to get available resources, tools, or prompts. This allows an AI agent to become aware of what's available in its context.

MCP defines standard JSON-RPC methods for this:

* **resources/list:** Discovers what resources the server offers.  
* **tools/list:** Retrieves the list of available tools (actions) the server can perform.  
* **prompts/list:** Lists available prompt templates.

**Example: Listing Resources**

The client sends a `resources/list` request to get the server's resource inventory.  

```json
// Client --> Server: discover available resources  
{  
  "jsonrpc": "2.0",  
  "id": 1,  
  "method": "resources/list",  
  "params": {}  
}
```

The server replies with a response containing a list of resource descriptors, including their uri, name, and mimeType.

```json
// Server --> Client: list of resources (result of resources/list)  
{  
  "jsonrpc": "2.0",  
  "id": 1,  
  "result": {  
    "resources": [  
      {  
        "uri": "demo://greeting.txt",  
        "name": "Greeting File",  
        "description": "A friendly greeting text file",  
        "mimeType": "text/plain"  
      }  
     ]  
  }  
}
```

A similar flow would be used with tools/list, where the server would return an array of tools, each with a name, description, and an inputSchema describing its required parameters.

### Step 3: Capability Invocation

Once the client has discovered capabilities, it can **invoke** them as needed. This is done using methods like `resources/read` or `tools/call`.

**Example 1: Reading a Resource**

Now that the client knows the resource `demo://greeting.txt` exists, it can send a resources/read request to retrieve its content.  

```json
// Client --> Server: request to read a specific resource  
{  
  "jsonrpc": "2.0",  
  "id": 2,  
  "method": "resources/read",  
  "params": { "uri": "demo://greeting.txt" }  
}
```

If successful, the server returns a result containing the resource's content.

```json
// Server --> Client: content of the resource (result of resources/read)  
{  
  "jsonrpc": "2.0",  
  "id": 2,  
  "result": {  
    "contents": [  
      {  
        "uri": "demo://greeting.txt",  
        "text": "Hello from MCP\!",  
        "mimeType": "text/plain"  
      }  
    ]  
  }  
}
```
If the resource cannot be found, the server returns an error object instead of a result.

```json
// Server --> Client: error response (resource not found)  
{  
 "jsonrpc": "2.0",  
  "id": 2,  
  "error": {  
    "code": 404,  
    "message": "Resource not found"  
  }  
}
```

The diagram below illustrates this full discover-and-read sequence for resources.

{{< mermaid >}}
sequenceDiagram
    title MCP Resource Access Sequence
    participant MCP-Client
    participant MCP-Server

    Note over MCP-Client,MCP-Server: MCP Session already established

    MCP-Client->MCP-Server: resources/list Request<br>{"id": 1, "method": "resources/list", "params": {}}
    activate MCP-Server
    alt Success
        MCP-Server-->MCP-Client: resources/list Response<br>{"id": 1, "result": {"resources": ["demo://greeting.txt", "demo://info.txt"]}}
    else Failure
        MCP-Server-->MCP-Client: resources/list Error Response<br>{"id": 1, "error": {"code": -32600, "message": "Invalid request"}}
    end
    deactivate MCP-Server

    Note left of MCP-Client: Client processes resource list<br>and identifies needed URI

    MCP-Client->MCP-Server: resources/read Request<br>{"id": 2, "method": "resources/read", "params": {"uri":"demo://greeting.txt"}}
    activate MCP-Server
    alt Success
        MCP-Server-->MCP-Client: resources/read Response<br>{"id": 2, "result": {"contents": "Hello, World!"}}
    else Failure
        MCP-Server-->MCP-Client: resources/read Error Response<br>{"id": 2, "error": {"code": -32602, "message": "Resource not found"}}
    end
    deactivate MCP-Server

    Note left of MCP-Client: Client processes resource content
{{< /mermaid >}}


**Example 2: Calling a Tool**

The invocation flow for tools is very similar. After discovering a tool (e.g., "echo") via tools/list, the client can invoke it using tools/call.  

```json
// Client --> Server: invoke a tool (echo) via tools/call  
{  
  "jsonrpc": "2.0",  
  "id": 3,  
  "method": "tools/call",  
  "params": {  
    "name": "echo",  
    "arguments": { "message": "Testing 123" }  
  }  
}
```

The server executes the tool and returns its output in the result field. The structure of the result is defined by the tool itself.

```json
// Server --> Client: result of the echo tool  
{  
  "jsonrpc": "2.0",  
  "id": 3,  
  "result": {  
    "content": [  
      { "type": "text", "text": "Echo: Testing 123" }  
    ]  
  }  
}
```

And just like resources, if the tool fails or is not found, the server returns an error response.

```json
{  
  "jsonrpc": "2.0",  
  "id": 3,  
  "error": {  
    "code": 404,  
    "message": "Tool not found"  
  }  
}
```

This sequence for tool invocation is visualized below.

{{< mermaid >}}
sequenceDiagram
    title Tool Invocation Sequence (MCP Protocol)
    participant Client
    participant Server

    Note over Client,Server: MCP Session already established

    Client->Server: tools/call Request<br>{"id": 3, "method": "tools/call", "params": {"name":"tool_name", "arguments":{...}}}
    activate Server
    alt Successful Invocation
        Server-->Client: tools/call Success Response<br>{"id": 3, "result": {...}}
        Note left of Client: Client processes tool result
    else Invocation Failed
        Server-->Client: tools/call Error Response<br>{"id": 3, "error": {"code": -32602, "message": "Tool not found"}}
        Note left of Client: Client handles error
    end
    deactivate Server
{{< /mermaid >}}

This discover-and-invoke pattern applies similarly to prompts, where the client lists available prompt templates and invokes them with specific parameters. 

## Core Security Principles

The MCP specification outlines key security principles that implementers **SHOULD** adhere to :

- **User Consent and Control:** Users must be informed about and explicitly consent to data access and tool operations. Clear user interfaces for reviewing and authorizing actions are critical. Users should retain control over what is shared and executed. As an example, A support agent asks, “Issue a refund for order 45677”. The host shows a confirmation UI with tool name, inputs, and side‑effects. Only on approval does the host send:
  ```json
  {
    "jsonrpc": "2.0",
    "id": 101,
    "method": "tools/call",
    "params": {
      "name": "issue_refund",
      "arguments": { "orderId": "45677", "amount": 129.90 }
    }
  }
  ```
  If the user cancels, no request is sent to the server.

- **Data Privacy:** Host applications must obtain explicit user consent before exposing user data (e.g., through Resources) to servers. Sensitive data should be protected with appropriate access controls, both in transit and at rest.

- **Tool Safety:** Tools represent potential arbitrary code execution paths and must be treated with caution. Tool descriptions provided by servers should not be implicitly trusted unless the server itself is trusted. Hosts **MUST** obtain explicit user consent before invoking any tool, and users should understand the tool's function beforehand.

- **LLM Sampling Controls:** If the server utilizes the Sampling capability (requesting the client to perform LLM interactions), the user must explicitly approve such requests, controlling the prompt content and the visibility of results to the server.


## Security Mechanisms

MCP does not mandate specific authentication or authorization mechanisms at the protocol level, allowing flexibility for different contexts. However, common patterns are expected:

- **Transport-Level Security:** For `HTTP/SSE` transport, using TLS (HTTPS) is essential to protect data in transit. For `stdio`, security primarily relies on the operating system's user permissions and process isolation model.

- **User Consent and Prompts:** The host (client side) also plays a role in authorization. A well-designed MCP integration will ask the user for permission before, say, executing a destructive tool or accessing a sensitive resource. This isn't enforced by MCP itself, but is a recommended practice (as noted in the MCP spec's security principles) to keep the human in control of what the AI is allowed to do. Essentially, even if the server is willing to perform an action, the client UI might gate that behind a confirmation dialog to the end-user.

It is crucial to understand that MCP standardizes the communication channel but deliberately leaves the implementation of robust consent flows, specific authentication methods, and fine-grained authorization logic to the applications using the protocol. This provides necessary flexibility but places a significant responsibility on developers to implement security measures appropriate for their specific use case and the sensitivity of the data and tools involved. 

## Implementation Guidance (Best Practices)

- Design for idempotency: make tool calls repeatable without harmful side effects.
- Declare precise input schemas: prefer required fields and validation over free-form inputs.
- Set timeouts and budgets: bound tool latency and cancel appropriately using `$/cancelRequest`.
- Minimize data exposure: scope resource roots narrowly and redact sensitive fields.
- Log with intent: log tool invocations and outcomes for auditability, not raw user data.
- Version deliberately: advertise `protocolVersion` and evolve capabilities compatibly.


## Looking Ahead to Part 3: Implementing an MCP Server

We now have a solid understanding of MCP's technical architecture. Right from message formats and transports to capability discovery and invocation. We are now ready to get our hands dirty in Part 3. In the next blog post, we will **build a simple MCP server** step-by-step. This implementation will illustrate how to put the concepts into practice. Here's a quick preview of what we'll cover:

1.  **Setting Up the Server Skeleton:** Initializing an MCP server (using an SDK or from scratch) and advertising a name and version.

2.  **Registering Capabilities:** Defining a couple of example resources and tools, and hooking them into the server (so that `resources/list` and `tools/list` return them, and `resources/read`/`tools/call` execute the corresponding logic).

3.  **Choosing a Transport:** Running the server over STDIO for local testing, and discussing how we could switch to HTTP+SSE or WebSocket if needed. We'll show how the server reads/writes JSON messages over the chosen transport.

4.  **Handling the Handshake and Loop:** Implementing the `initialize` handler to perform capability negotiation, and writing the main loop that processes incoming requests and sends responses. We'll pay attention to message framing details and concurrency (if the server can handle multiple requests at once).

5.  **Error Handling and Cleanup:** Ensuring our server properly returns errors for invalid requests and how it shuts down gracefully on exit (honoring any MCP shutdown sequence if applicable).

6.  **Security Considerations:** Simple measures to restrict access (for example, only allowing the server to run for the current user), and how one might plug in an auth check for remote transports.

By the end of Part 3, you'll have a working MCP server and a deep appreciation of how all the pieces come together in code. Armed with the architectural knowledge from this post and the hands-on experience from the next, you'll be well-equipped to integrate AI assistants with external data and tools in a standardized, robust way. Stay tuned -- in Part 3 we'll bring MCP from theory to reality!
