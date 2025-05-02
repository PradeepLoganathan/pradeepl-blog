---
title: "MCP - Protocol Mechanics and Architecture"
lastmod: 2025-05-01T19:03:33+10:00
date: 2025-05-01T19:03:33+10:00
draft: true
Author: Pradeep Loganathan
tags: 
  - 
  - 
  - 
categories:
  - 
#slug: kubernetes/introduction-to-open-policy-agent-opa/
description: "meta description"
summary: "summary used in summary pages"
ShowToc: true
TocOpen: true
images:
  - 
cover:
    image: "images/cover.jpg"
    alt: ""
    caption: ""
    relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---

Welcome back to our series on the Model Context Protocol (MCP)! In Part 1, we explored the fundamental challenge MCP addresses: the complex web of custom integrations needed to connect diverse AI applications with the ever-growing universe of external tools and data sources -- the "M x N" problem. We introduced MCP as a promising solution, an open standard designed to simplify this landscape into a more manageable "M + N" scenario by providing a universal communication layer. Often described as a "USB-C port for AI," MCP aims to standardize how AI models plug into the context they need, fostering a more interoperable ecosystem.

This post, Part 2, shifts gears from the 'why' to the 'how'. We'll dive deep into the technical architecture that powers MCP, dissecting the protocol's mechanics piece by piece. Understanding these underlying components is crucial for developers aiming to build robust MCP servers or integrate MCP clients into their AI applications. We will examine how MCP structures its messages, the data formats and transports it uses, and how it represents capabilities like tools and resources. By the end, you'll have a detailed understanding of MCP's architecture, preparing you for the step-by-step server implementation in Part 3. 

## Communication Foundation: JSON-RPC 2.0

The communication between MCP Clients and Servers is built upon the JSON-RPC 2.0 specification. This choice provides several advantages:

- **Standardization:** It leverages a well-defined, widely implemented, and understood remote procedure call protocol.
- **Simplicity:** JSON-RPC 2.0 defines a relatively straightforward structure for requests, responses, and notifications.
- **Data Format:** It utilizes JSON (JavaScript Object Notation) for message serialization, which is human-readable, easily parsed across numerous programming languages, and inherently compatible with web technologies.
- **Proven Foundation:** The protocol explicitly draws inspiration from the Language Server Protocol (LSP), which also successfully employs JSON-RPC to standardize communication between development tools and language servers.

By adopting JSON-RPC, MCP avoids reinventing fundamental RPC mechanisms. This strategic decision likely accelerated the development of MCP SDKs across various languages and lowers the adoption barrier, allowing the protocol's focus to remain on the specific semantics of AI context exchange.

## Structured JSON Messages in MCP

As discussed above, all MCP communications are built on **structured messages** following the JSON-RPC 2.0 standard. Every message is a JSON object containing specific fields that convey its intent and allow the recipient to understand how to process it. Key fields include:

-   **`jsonrpc` (version):** Specifies the protocol version (always `"2.0"` for JSON-RPC 2.0). This field ensures both sides interpret the message format the same way.
-   **`id` (identifier):** A unique ID for pairing requests with responses. The sender assigns an `id` to each request, and the receiver uses the same `id` in the corresponding response. This can be a number or string; it's used only for matching responses and is not needed for one-way messages (notifications).
-   **`method`:** A String indicating the name of the method to be invoked or the notification type. Examples include `initialize`, `tools/list`, `tools/call`, `$/progress`, or `$/cancelRequest`. This field is **REQUIRED** for both Requests and Notifications.
-   **`params` (or `payload`/`data`):** An object (or array) containing data needed to perform the method. This could be inputs to a tool, a resource identifier, or other context. It may be omitted if a method doesn't require additional data.
-   **`result`:** Included in Response messages upon successful method execution. This field contains the value returned by the invoked method. It is **REQUIRED** on success and **MUST NOT** exist if the `error` field is present.
-   **`error`:** Included in Response messages when a method invocation fails. This field **MUST** be an Object containing:
    -   **`code`:** An Integer indicating the error type that occurred (using standard JSON-RPC error codes or potentially custom codes).
    -   **`message`:** A String providing a short description of the error.
    -   **`data` (optional):** A primitive or structured value containing additional information about the error. The `error` field is **REQUIRED** on failure and **MUST NOT** exist if the `result` field is present.

These fields make MCP messages self-descriptive and machine-readable. Notably, there is no explicit field for "message type" -- instead, the presence or absence of certain fields defines the type. For example, a message with a `method` and no `result` or `error` is a **Request**; a message with `result` or `error` (but no `method`) is a **Response** to a prior request; and a message with a `method` but **no** `id` is treated as a one-way **Notification** (no response expected). 

## MCP Transport Layers and Connection Flows

The Model Context Protocol (MCP) is **transport-agnostic**, meaning it can operate over any channel capable of carrying JSON text. This flexibility allows MCP to support multiple transport layers---Standard Input/Output (STDIO), HTTP with Server-Sent Events (SSE), and WebSockets---each suited to specific use cases. Below, we explore these transport mechanisms, their connection flows, message framing, and their respective strengths and limitations.

### Transport Layers

MCP supports three primary transport layers, each designed to balance latency, infrastructure compatibility, and interactivity:

- **Standard Input/Output (STDIO):**\
    STDIO leverages a process's stdin and stdout streams for communication, typically when the MCP server runs as a local subprocess of the host application (similar to Language Server Protocol implementations).

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

    - **Connection Flow:** Used when the MCP client (within the host application) and server run on the same machine. The host application launches the server as a subprocess (e.g., npx -y @modelcontextprotocol/server-filesystem /path/to/root). Communication occurs over the server's stdin and stdout pipes, effectively forming the "connection."
    - **Message Framing:** JSON-RPC messages are exchanged over stdin/stdout. Simple implementations may separate messages with newlines, but robust systems (similar to LSP) use explicit framing, prefixing each JSON message with headers like Content-Length: NNN\r\n\r\n, followed by the JSON payload. This ensures accurate message delimitation, especially for large messages.
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

MCP's design ensures the higher-level protocol (JSON-RPC + capabilities) remains consistent across transports. Developers can switch transports---e.g., from STDIO during development to WebSockets in production---without altering the core logic of their MCP client or server. SDKs or transport handlers abstract away the details of framing and connection management, allowing seamless transitions between transports based on deployment requirements.

## Capabilities in MCP: Tools, Resources, and Prompts

Now that we understand the communication foundation and how messages are transmitted we can focus on how communication actually occurs. First..How does an AI client know what capabilities a server provides? MCP includes a discovery mechanism. When a connection is first established, the client and server perform a **handshake** (initialization sequence) where they exchange supported features. The client sends an `initialize` request identifying the MCP protocol version it speaks and perhaps its own capabilities or preferences. The server responds with an acknowledgment that includes its available capability types (whether it has resources, tools, and/or prompts, and possibly other info like server name/version). This exchange ensures both sides know what the other supports (for example, a server might declare it supports the "resources" and "tools" features, but not "prompts"). After this, the client sends an `initialized` notification to finalize the handshake.

Once initialized, the client can query the server for specific capability details. MCP defines the below **standard JSON-RPC methods** for discovering and using capabilities:

-   **`resources/list`:** Discovers what resources the server offers. The server returns a list of resource descriptors (each typically includes a `uri`, a human-friendly `name` or description, and maybe a MIME type or other metadata).

-   **`resources/read`:** Requests the content of a specific resource identified by URI. The server returns the resource data (text content, or binary data encoded in base64, along with metadata like MIME type).

-   **`tools/list`:** Retrieves the list of available tools (actions) the server can perform. The response is an array of tools, each with a `name`, a description of what it does, and an `inputSchema` (often a JSON Schema or similar) describing the expected parameters for that tool. The schema helps the client (and ultimately the AI) understand how to call the tool correctly (what inputs are required).

-   **`tools/call`:** Invokes a named tool with provided parameters. The server executes the action and returns the result. The result format depends on the tool (could be any JSON data structure defined by that tool's contract) or returns an error if something went wrong during execution.

-   **`prompts/list` and `prompts/get`:** Similarly, list available prompt templates and retrieve the content of a selected prompt.

Using these standardized methods, an MCP client can systematically explore what a server can do. For instance, right after initialization, a client might call `tools/list` and `resources/list` to get a full inventory of capabilities. The **capabilities object** exchanged in the handshake is high-level (just indicates categories supported), while these list methods provide the detailed inventory of each category. This two-step discovery (handshake negotiation, then detailed listing) allows MCP to remain **extensible** -- new categories of capabilities or new features can be introduced in future versions, and clients/servers will negotiate if they support them.

## Connection Establishment and Capability Discovery

Establishing a connection in MCP involves both setting up the transport and performing a protocol handshake. At the transport level, this means connecting via STDIO, HTTP+SSE, or WebSocket as discussed earlier (e.g. launching a subprocess for STDIO, or opening an HTTP connection for SSE events). Once the low-level connection is open, the **MCP handshake** occurs at the JSON-RPC level:

1.  **Client Initialization:** The client (host application) sends an `initialize` JSON-RPC **request** to the server. This message typically includes parameters such as the MCP protocol version and the client's own supported features or preferences. For example, the client might send the version and indicate it's ready to handle certain server capabilities. It may also specify a list of "roots" or a scope for resources (to limit what the server should have access to, e.g., only a certain directory). The `initialize` request carries an `id` since the client expects the server to reply. A sample initialization request is below

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "processId": null,
    "clientInfo": {
      "name": "ExampleHostApp",
      "version": "1.2.0"
    },
    "capabilities": {
     },
    "trace": "off",
    "rootUri": null,
    "workspaceFolders": null
  }
}
```

2.  **Server Response (Capabilities Ack):** The server responds to `initialize` with a JSON-RPC **response** containing its details. In the response's `result`, the server includes information such as:

    -   **`capabilities`:** The capability types it supports (e.g. `{ "resources": {}, "tools": {} }` to advertise that it provides resources and tools).
    -   **`serverName` and `serverVersion`:** Identification of the server (helpful for logging or UI).
    -   Optionally, any other info or negotiated settings (for example, some servers might send a `sessionId` or accepted protocol version if negotiation was needed).

    The server's response confirms the protocol version (usually it will mirror what the client requested if compatible) and lists what features it can offer. This capability negotiation allows the client to adjust its behavior if needed and is designed for backwards-compatibility as MCP evolves. A sample initialization response is below.

    ```json
    {
      "jsonrpc": "2.0",
      "id": 1,
      "result": {
        "capabilities": {
          "tools": {
            "supported": true
          },
          "resources": {
            "supported": true
          },
          "prompts": {
            "supported": false
          }
        },
        "serverInfo": {
          "name": "SampleMCPServer",
          "version": "0.1.0"
        }
      }
    }
    ```

3.  **Client Acknowledgment:** After receiving a successful initialize result, the client sends an `initialized` **notification** (a JSON-RPC message with a `method` but no `id`) to signal that it received the server's capabilities and that the connection is fully established. This tells the server that the client is ready and any startup procedures can be considered done. There is no response to a notification.

At this point, the MCP session is live and ready for use. The next step is usually **capability discovery**: the client will call the listing methods to get available resources, tools, or prompts. This can be done immediately after initialization, or later on demand when the AI needs something. It's common for a client to do it upfront so that an AI agent can be aware of what's available in its context.

Let's walk through an example of discovering a resource and then using it, to illustrate the message flow and structures:

**Example -- Listing and Reading a Resource:** Suppose the MCP server provides access to a simple resource (say, a text file). After the handshake, the client can ask for a list of resources:

```json
// Client -> Server: discover available resources
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "resources/list",
  "params": {}
}
```
This is a request for the server's resource inventory. The `params` are empty here because no additional data is needed to list everything. The server would reply with a JSON-RPC response containing a list of resources:

```json
// Server -> Client: list of resources (result of resources/list)
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

In this fictional example, the server has one resource (`greeting.txt`) identified by the URI `demo://greeting.txt`. It provides a name and description for the resource, and indicates the MIME type is plain text. (In a real scenario, there could be many resources listed. The URI scheme `demo://` here is arbitrary; some servers might use file paths or other URI schemes like `file://` or custom scheme names.)

Now that the client knows a resource exists, the AI (or user) can decide to retrieve it. To get the content of `demo://greeting.txt`, the client sends a `resources/read` request:

```json
// Client -> Server: request to read a specific resource
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "resources/read",
  "params": { "uri": "demo://greeting.txt" }
}
```

This request includes the `uri` of the desired resource as a parameter. The server will attempt to read that resource and respond. If successful, it returns a `result` containing the content:

```json
// Server -> Client: content of the resource (result of resources/read)
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "contents": [
      {
        "uri": "demo://greeting.txt",
        "text": "Hello from MCP!",
        "mimeType": "text/plain"
      }
    ]
  }
}
```

Here, the server returned the content of the file: the text `"Hello from MCP!"` as plain text. We see that the result wraps the data in a `contents` array -- this is an MCP convention since a resource could be multi-part or might return multiple chunks (but in this simple case it's just one text blob). The `uri` is echoed back to clarify what this content corresponds to (useful if batched) and the MIME type is included as metadata.

If the resource cannot be found or accessed, the server would instead return an error. For example, if the client requested a URI that doesn't exist:

```json
// Server -> Client: error response (resource not found)
{
  "jsonrpc": "2.0",
  "id": 2,
  "error": {
    "code": 404,
    "message": "Resource not found"
  }
}
```

This indicates the request failed. The error object contains a numeric `code` and a `message` explaining the failure. In this case we used an HTTP-style `404` code for clarity, but MCP doesn't mandate specific codes beyond the JSON-RPC standard ones. Some implementations use JSON-RPC's predefined error codes or domain-specific codes. The key is that an error response always has the `error` field instead of `result`, and the original request `id` so the client knows which call failed.

Through this discovery sequence, the client learned what resources are available and then successfully retrieved one. The same pattern applies for tools and prompts: use `tools/list` or `prompts/list` to discover what's offered, then invoke `tools/call` or `prompts/get` (or other actions) to utilize them.

## Invoking Capabilities: Requests, Results, and Errors

Now that we know and understand how to use resources..lets focus on tools. Once capabilities are discovered, the host can **invoke** them as needed. Invocations in MCP are simply JSON-RPC requests to the appropriate method (like `tools/call` or a specific resource action). The server will execute the request and send back a response. Let's consider how a tool invocation works to illustrate the general pattern (tools often have more interesting inputs/outputs than a static resource):

Suppose the server in our example also provides a simple tool named `"echo"` that just repeats back a message. The client would first have obtained this tool's info via `tools/list` (similar to resources, we won't repeat the listing here). Now, to use the tool, the client sends a request:

```json
// Client -> Server: invoke a tool (echo) via tools/call
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "echo",
    "params": { "message": "Testing 123" }
  }
}
```

Here, the `params` for `tools/call` include the tool's name (`"echo"`) and a nested object of arguments (`"message": "Testing 123"`). The server will look up the `"echo"` tool and execute it. In this case, the tool simply returns the string it was given. The server's response might look like:

```json
// Server -> Client: result of the echo tool
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

The structure of the result is defined by the tool. We've formatted it as a `content` array with a text snippet, to simulate how a real tool might return a textual result (some tools return structured data, some might return multiple pieces of content). The key is that it appears under the `result` field with the same request `id` of 3, indicating success. The client (and ultimately the AI model) can now use this result in its workflow.

If something went wrong during the invocation -- for example, the client provided an invalid tool name or bad parameters -- the server would send an error response instead of a result. Error responses in MCP follow the JSON-RPC error structure: they include an `error.code` (integer) and `error.message` describing the issue. For instance, if the client tried to call a non-existent tool `"foobarbaz"`, the server might respond with:

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

Just like the resource example, the meaning is clear: the requested tool doesn't exist (hence no result). The client should handle this gracefully -- perhaps by informing the AI that the tool is unavailable or by attempting an alternative approach. MCP does not fix a strict list of error codes beyond recommending reusing JSON-RPC's conventions. Servers often use codes analogous to HTTP (400 for bad request, 404 for not found, etc.) or the standard JSON-RPC codes (like -32601 for "Method not found"). The **error handling** strategy is up to the implementation, but the structure is always the same. This consistency makes it easier for client libraries to handle errors uniformly, regardless of the specific cause.

In addition to direct invocation results, MCP also supports **notifications and streaming** for longer-running operations. Notifications can be used for things like "resource changed" events if the protocol is extended to support subscriptions. These advanced patterns are optional, but they illustrate the flexibility of MCP's message model to handle not just simple request/response but also asynchronous event flows when needed.

## Core Security Principles

The MCP specification outlines key security principles that implementers **SHOULD** adhere to :

- **User Consent and Control:** Users must be informed about and explicitly consent to data access and tool operations. Clear user interfaces for reviewing and authorizing actions are critical. Users should retain control over what is shared and executed.
- **Data Privacy:** Host applications must obtain explicit user consent before exposing user data (e.g., through Resources) to servers. Sensitive data should be protected with appropriate access controls, both in transit and at rest.
- **Tool Safety:** Tools represent potential arbitrary code execution paths and must be treated with caution. Tool descriptions provided by servers should not be implicitly trusted unless the server itself is trusted. Hosts **MUST** obtain explicit user consent before invoking any tool, and users should understand the tool's function beforehand.
- **LLM Sampling Controls:** If the server utilizes the Sampling capability (requesting the client to perform LLM interactions), the user must explicitly approve such requests, controlling the prompt content and the visibility of results to the server.

## Security Mechanisms

MCP does not mandate specific authentication or authorization mechanisms at the protocol level, allowing flexibility for different contexts. However, common patterns are expected:

- **Transport-Level Security:** For `HTTP/SSE` transport, using TLS (HTTPS) is essential to protect data in transit. For `stdio`, security primarily relies on the operating system's user permissions and process isolation model.

- **User Consent and Prompts:** The host (client side) also plays a role in authorization. A well-designed MCP integration will ask the user for permission before, say, executing a destructive tool or accessing a sensitive resource. This isn't enforced by MCP itself, but is a recommended practice (as noted in the MCP spec's security principles) to keep the human in control of what the AI is allowed to do. Essentially, even if the server is willing to perform an action, the client UI might gate that behind a confirmation dialog to the end-user.

It is crucial to understand that MCP standardizes the communication channel but deliberately leaves the implementation of robust consent flows, specific authentication methods, and fine-grained authorization logic to the applications using the protocol. This provides necessary flexibility but places a significant responsibility on developers to implement security measures appropriate for their specific use case and the sensitivity of the data and tools involved. 


## Looking Ahead to Part 3: Implementing an MCP Server

With a solid understanding of MCP's technical architecture -- from message formats and transports to capability discovery and invocation -- we are ready to get our hands dirty in Part 3. In the next installment, we will **build a simple MCP server** step-by-step. This implementation will illustrate how to put the concepts into practice. Here's a quick preview of what we'll cover:

1.  **Setting Up the Server Skeleton:** Initializing an MCP server (using an SDK or from scratch) and advertising a name and version.

2.  **Registering Capabilities:** Defining a couple of example resources and tools, and hooking them into the server (so that `resources/list` and `tools/list` return them, and `resources/read`/`tools/call` execute the corresponding logic).

3.  **Choosing a Transport:** Running the server over STDIO for local testing, and discussing how we could switch to HTTP+SSE or WebSocket if needed. We'll show how the server reads/writes JSON messages over the chosen transport.

4.  **Handling the Handshake and Loop:** Implementing the `initialize` handler to perform capability negotiation, and writing the main loop that processes incoming requests and sends responses. We'll pay attention to message framing details and concurrency (if the server can handle multiple requests at once).

5.  **Error Handling and Cleanup:** Ensuring our server properly returns errors for invalid requests and how it shuts down gracefully on exit (honoring any MCP shutdown sequence if applicable).

6.  **Security Considerations:** Simple measures to restrict access (for example, only allowing the server to run for the current user), and how one might plug in an auth check for remote transports.

By the end of Part 3, you'll have a working MCP server and a deep appreciation of how all the pieces come together in code. Armed with the architectural knowledge from this post and the hands-on experience from the next, you'll be well-equipped to integrate AI assistants with external data and tools in a standardized, robust way. Stay tuned -- in Part 3 we'll bring MCP from theory to reality!