---
title: "Understanding the Model Context Protocol (MCP) for AI Integration"
lastmod: 2025-04-29T13:10:07+10:00
date: 2025-04-29T13:10:07+10:00
draft: false
author: "Pradeep Loganathan"
tags: 
  - ai
  - llm
  - integration
  - model-context-protocol
  - developer-tools
categories:
  - AI Architecture
  - Agent Systems
  - DevTools
  - featured
description: "Learn why the Model Context Protocol (MCP) is essential for connecting LLMs to real-world tools, APIs, and context in a standardized and secure way."
summary: "LLMs are powerful—but without access to live tools, data, and systems, they're limited. Discover how MCP bridges that gap and why it's becoming the standard for AI integration."
ShowToc: true
TocOpen: true
images:
  - images/mcp-cover.png
cover:
  image: "images/mcp-cover.png"
  alt: "Model Context Protocol Overview Diagram"
  caption: "Diagram showing how MCP connects AI with tools and data"
  relative: true
mermaid: true
series: ["Model Context Protocol"]
weight: 1
---

{{< series-toc >}}

Let's be honest: you can't build an AI system that does *real work* without solving a major engineering challenge first. LLMs like Claude and ChatGPT are frozen in time, with no access to your systems, no memory of recent events, and no ability to learn. Ask an LLM to explain an API, and it will do a great job. But ask it to *call* that API? It can't, not without custom wiring.

This creates a significant engineering bottleneck: to give an LLM any real-world capability, you have to build custom integration code for every single tool, API, or data source. This one-to-one approach is not scalable and leads to a fragile, unmanageable mess. 

Want your AI system to:
* Look up live data (APIs, databases, file systems)?
* Trigger real actions (send emails, update records, execute commands)?
* Access context about what the user is actually working on?
* Use specialized tools (code analyzers, orchestration platforms, CLIs)?

**Each of these requires custom plumbing.** And this is where everything falls apart.

### The Problem with Custom Integrations

Imagine building a customer support chatbot for an e-commerce business. A customer asks, "Where's my order #45677?" An LLM can guess what to do, but it can't retrieve live order data without a connection to your system. So, you build an integration with your order management API.

But then, you need to add tracking information from a shipping provider, payment details from Stripe, and the ability to send email notifications. Each new capability requires more custom code, and soon your clean integration becomes a web of brittle connectors. Each system has a different API, authentication method, and error handling.

This isn't just a problem for chatbots. A corporate knowledge assistant that's supposed to help employees answer questions might need to access internal documentation in Confluence, query a database for sales figures, and check a user's permissions in Active Directory. Without a standardized way to interact with these systems, you're back to building custom integrations for each one. Later in this series, we'll look at concrete coding examples, such as a log analysis tool that can query Datadog or Splunk.

This is where the **Model Context Protocol (MCP)** comes in.

## Why MCP? 

After the previous experience of building brittle, custom integrations between AI models and external systems, developers needed something better. Each new use case, whether checking order status, scanning code for vulnerabilities, or fetching live metrics, meant repeating the same boilerplate: define a custom API contract, build tooling to adapt the model's output, and carefully manage authentication, serialization, and errors.

This fragmentation slowed innovation and made AI assistants hard to scale, test, or secure. This fragmentation and custom-plumbing problem isn't new. We've solved it before. In the 2000s,  [REST]({{< ref "/series/rest" >}}) emerged as a standard way for web services to communicate over HTTP, saving us from a mess of proprietary XML-RPC and SOAP integrations. More recently, [GraphQL]({{< ref "/blog/api/getting-started-with-graphql" >}}), and [gRPC]({{< ref "/blog/api/grpc" >}})  provided a high-performance, schema-driven standard for internal microservice communication, replacing ad-hoc RPC calls. Each standard provided a common language that reduced complexity and accelerated innovation.The AI ecosystem lacked its own standard for this new type of interaction—a universal way for models to talk to tools.That's where the **Model Context Protocol (MCP)** comes in.

MCP, introduced by Anthropic, is an **open protocol** designed to standardize these interactions. It defines how language models and agent-like systems can:

- **Discover** what tools and data are available,
- **Invoke** those tools with structured arguments,
- **Receive** results in a consistent, LLM-friendly format,
- And **maintain context** across interactions.

Because MCP is open and composable, it allows developers and tool vendors to build **plug-and-play connectors** that work across models and platforms. You can expose a payment API, a document store, or a CLI tool once and use it with any assistant that speaks the MCP protocol. Rather than building a new integration every time an AI model changes, you build once, plug in anywhere. By standardizing this interface, MCP shifts the developer's focus to designing smart, secure, and useful AI workflows without reinventing the wiring for every tool or data source.

## The Growing MCP Ecosystem

Since its introduction by Anthropic in late 2024 , MCP has rapidly gained traction, fostering a growing ecosystem around the standard.

### Specification and Standards

MCP is positioned as an open standard, stewarded by Anthropic but open to community contribution. The core assets are publicly available:

- **Specification Repository:** The repo at `https://github.com/modelcontextprotocol/modelcontextprotocol` hosts the specification details and the schema definitions. 
- **Schema:** The protocol contract is defined using TypeScript types first, which are then compiled to JSON Schema for cross-language compatibility.
- **Documentation:** The official documentation site, `modelcontextprotocol.io`, provides guides, tutorials, and API references.

### SDK Support

A key factor in MCP's adoption is the availability of official Software Development Kits (SDKs) for major programming languages, facilitating the development of both clients and servers. Official or officially supported SDKs exist for almost all major languages. This broad language support significantly lowers the barrier for developers to integrate MCP into their existing technology stacks.

### Industry Adoption

MCP has seen remarkably rapid adoption by major players in the AI landscape:

-   **Anthropic:** Integrated MCP into its Claude models and Claude Desktop application.
-   **OpenAI:** Announced support for MCP in its Agents SDK and ChatGPT desktop applications in early 2025.
-   **Google:** Integrated MCP support into Vertex AI, the Agent Development Kit (ADK), and upcoming Gemini models, referring to it as a "rapidly emerging open standard".
-   **Tool and Platform Vendors:** Numerous companies, including development tool providers (Akka, Sourcegraph, Zed, Codeium, Replit), enterprise platforms (Akka, Block, Apollo), and integration platforms (Zapier, Pipedream), have adopted or built integrations for MCP.

This swift and broad uptake by leading AI companies and the wider developer community signals strong momentum. It suggests a collective recognition of the need for standardization in how AI models interact with external context and tools.

### Complementary Protocols

It's also worth noting that MCP exists within a broader landscape of emerging AI communication standards. Google, for instance, introduced the Agent-to-Agent (A2A) protocol, explicitly positioning it as *complementary* to MCP. While MCP focuses on standardizing how a single agent interacts with tools and data sources, A2A aims to standardize how different autonomous AI agents communicate and collaborate with *each other*. Understanding this distinction helps place MCP within the larger context of building complex, multi-agent AI systems.

## The MCP Architecture
At its core, MCP is built around a client-server architecture that clearly separates the roles of the AI application (the Host), the intermediary that speaks the MCP protocol (the Client), and the service exposing external capabilities (the Server). This separation of concerns is fundamental to MCP's design, promoting security, modularity, and composability. 

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

As the diagram above illustrates, the MCP architecture is built on a clear separation of concerns. It shows how an AI-Enabled Application (the Host) interacts with External Systems by communicating through a standardized MCP Server Layer. This client-server model is fundamental to MCP's design. Now, let's get into the specific details of each component in that flow.

### MCP Hosts, Clients, and Servers

MCP follows a client-server architecture designed to facilitate communication between AI applications and the external capabilities they need to leverage. The architecture revolves around a clear separation of roles within a client-server model. The primary components involved are:


1. **MCP Host:** The Host is the application or runtime that embeds the AI model and needs contextual capabilities. Examples include chatbots, AI-enhanced Integrated Development Environments (IDEs) like Cursor or Claude Desktop, or other custom applications integrating AI features. The host application operates or embeds the MCP Client to interact with the MCP ecosystem. The host is responsible for managing one or more MCP Clients, initiating connections, enforcing security policies, handling user interaction (including critical consent flows for tool use and data access), and potentially aggregating context from multiple servers.

2. **MCP Client:** Residing within the Host environment, the MCP Client acts as an intermediary. The Client acts as a bridge between the AI model and the external tools exposed by MCP Servers. Each Client maintains a persistent, stateful 1:1 connection with a single MCP Server and handling the specifics of the MCP protocol. It handles the specifics of the MCP protocol over the chosen transport (e.g., WebSocket), translates requests from the Host into MCP messages, manages the connection lifecycle (including initialization and capability negotiation), handles authentication with the server, and routes messages bidirectionally. Think of the MCP Client as a **runtime agent or library** inside the Host that speaks the MCP protocol and coordinates tool usage. The host may launch multiple clients to connect to different servers (for example, one client for a Google Drive connector, another for a database connector).

3. **MCP Server:** An MCP Server exposes one or more tools, prompts, or data resources through the standardized MCP interface. Servers operate independently and each server provides a specific set of functions or context. An MCP Server acts as a gateway, exposing external capabilities to the AI model via the standardized MCP interface. A server might provide access to specific databases, integrate with external APIs (like Stripe or GitHub), manage local file systems, or execute specific functions. They form the core of the ecosystem, acting as the bridge between the AI model's requests (via the client) and the real-world tools or data sources.
MCP Servers can be implemented as local processes communicating via standard I/O (stdio) or as remote services accessible over protocols like HTTP with Server-Sent Events (SSE). This architectural separation is fundamental to MCP's design, promoting security and composability. The Host retains control over the user interaction and the overall context, deciding which servers to connect to and managing trust boundaries. Each server focuses on providing its specific set of capabilities, isolated from the full conversation context and other connected servers, which is crucial for managing security risks. This isolation model is critical. It ensures that a tool server can only do what it's explicitly asked to and nothing more. The Host is always in control of **which tools are available**, **who can use them**, and **when they're called**.

Now that we have a clear picture of the primary components namely the **Host, Client, and Server** and their roles, the next logical question is: **how does a server actually expose its capabilities?** What is the "language" they use to share functions, data, and instructions? This is defined by MCP's three core primitives. Let's dive into what they are and how they work.

## Core Primitives of MCP

MCP servers expose their capabilities using three core primitives: **Tools**, **Resources**, and **Prompts**. These primitives define how AI models interact with the external world by performing actions, accessing data, or shaping behavior---with structured metadata and human-in-the-loop safeguards.

### Tools 

Tools represent executable capabilities that the MCP server exposes to the AI model or agent allowing it to perform actions or invoke external services and APIs. Examples range from executing Kubernetes command-line interface (CLI) commands (kubectl, helm, istioctl) , calling a payment processing API, interacting with a version control system like GitHub , or any other defined action. A critical aspect of MCP Tools is how they are described. Unlike traditional APIs defined for machine consumption, **MCP tool definitions are designed to be interpretable by language models**. 

A tool definition typically includes:
- A natural language description explaining what the tool does.
- A structured definition of inputs and outputs (e.g., using schemas).
- Any preconditions required for successful execution (e.g., a specific user must exist).
- Examples illustrating how the tool might be used in different contexts. 
 
This metadata helps the LLM **understand when and how to use a tool correctly**, making the tool not just machine-callable, but **AI-readable**. We will be looking at tool definitions in detail in subsequent blog posts in the series.

Tools can be unsafe (they might execute code, send emails, make purchases, etc.), so MCP enforces that the user must explicitly allow a tool invocation​. Typically the host will prompt the user “Allow AI to run tool X with these inputs?” and only call the server if confirmed. Tool results can be text or data; if a result is binary (e.g. an image or file generated), the server might return a reference (like a URI or an encoded blob) and the host can decide how to handle it (display to user, etc.). MCP also allows tool annotations – hints about tool behavior (like cost, side effects) – but these are considered untrusted unless from a trusted source​.

### Resources

Resources allow an MCP server to expose structured or unstructured data to the model. This could involve querying databases, accessing specific files or directories on a local filesystem, retrieving information from cloud storage platforms, or accessing specific data streams like customer logs. The server acts as a content provider, and can support a range of capabilities, including:

- **Listing:** Discovering what resources are available.
- **Reading:** Fetching the content of a specific resource.
- **Searching:** Finding resources that match certain keywords.
- **Subscriptions:** Receiving notifications when a resource changes.

Crucially, resources are selected by the application or user, not by the model directly. This ensures human oversight and data privacy. Large resources are handled intelligently, with options for chunking, summarizing, or streaming to avoid overwhelming the model's context window.

### Prompts

These are reusable, server-managed templates designed to guide or enhance the AI model's behavior and responses in specific situations. They can be used to maintain consistency in responses, simplify complex or repeated actions, or inject specific instructions or context into the model's processing flow for certain tasks.  For example, a troubleshoot-bug prompt might return a series of messages that first instruct the assistant to ask clarifying questions, then analyze logs, etc. Prompts are user-controlled: the idea is the user chooses to insert that prompt flow (like selecting a pre-made recipe)​. In UIs, these could surface as buttons or slash-commands for the user. They help standardize complex instructions and can be shared across apps. Importantly, because prompts come from an external source, there is a risk of prompt injection if a prompt template is malicious. Implementations should only include prompt templates from trusted servers or after user review, and even then the user should know what the prompt will do. The MCP spec advises treating tool descriptions and prompt templates as untrusted by default, unless the server is fully trusted​

So far, we've identified all the key pieces of the puzzle:
- The architectural components (Host, Client, and Server).
- The core primitives they use to communicate (Tools, Resources, and Prompts).

Now, let's put it all in motion. How do these components use these primitives to get a job done? This is where we look at the actual data flow and interaction patterns.

## Interaction Patterns and Data Flow

### Tool Access Flow

The typical tool invocation follows a request–response pattern mediated by the MCP client and server. Here's a simplified walkthrough aligned to the diagram below:

1. The Host identifies a need for an external action (e.g., user asks to check order status).
2. The Host consults its registered capabilities and finds the `check_order_status` tool via a connected MCP Client.
3. The Host instructs that MCP Client to execute `check_order_status` with parameters (e.g., order ID), often after user consent.
4. The MCP Client translates the call into an MCP `tools/call` request and sends it to its one connected Server.
5. The MCP Server validates inputs and executes the tool logic (e.g., calls an external API or queries a database).
6. The Server returns a normalized MCP response (result or error) to the Client.
7. The MCP Client delivers the result to the Host.
8. The Host composes the final answer for the user (and may persist context/memory).

{{< mermaid >}}
sequenceDiagram
    autonumber
    participant U as User
    participant H as Host App
    participant C as MCP Client
    participant S as MCP Server
    participant API as Order API

    U->>H: Where is my order 45677?
    H->>H: Select tool check_order_status
    H->>U: Optional consent to run tool
    H->>C: tools call check_order_status id 45677
    C->>S: MCP request tools call
    S->>API: GET orders 45677
    API->>S: Status and tracking info
    S->>C: MCP response result
    C->>H: Deliver result
    H->>U: Compose and return answer
{{< /mermaid >}}

### Resource Access Flow

While the core request–response path is the same for tools and resources, resource access has a few notable nuances:

- **Discovery:** Use `resources/list` to retrieve descriptors; the user/host selects which URIs to expose.
- **Data shape:** Reads return `contents[]` (e.g., `{ text, uri, mimeType }`), not tool-defined payloads.
- **Consent model:** Models cannot arbitrarily read files or databases; the host preselects allowed roots/URIs.
- **Size and streaming:** Large items are summarized, chunked, or streamed; subscriptions deliver updates.
- **Prompt safety:** Treat content as untrusted; summarize/redact to reduce prompt‑injection risk.

{{< mermaid >}}
sequenceDiagram
    autonumber
    participant H as Host App
    participant C as MCP Client
    participant S as MCP Server

    H->>C: resources list
    C->>S: resources list
    S->>C: resources listed uri name mimeType
    C->>H: Show descriptors in host UI

    H->>C: resources read uri
    C->>S: resources read
    S->>C: contents returned text or binary ref
    C->>H: Provide content
    Note over H: Summarize or inject content into prompt

    H->>C: resources subscribe uri
    C->>S: resources subscribe
    S->>C: resource updated diff or new chunk
    C->>H: Notify host and refresh context window
{{< /mermaid >}}

In addition to this synchronous flow, MCP supports asynchronous Notifications. Servers can proactively send these messages to clients without a preceding request, typically to inform them about relevant state changes, such as the availability of a new tool or updates to a resource the client might be interested in. This allows for more dynamic interactions and keeps clients informed about the capabilities available through the server. Overall, MCP provides a structured protocol enabling AI agents to effectively plan sequences of actions, execute those steps by interacting with real systems via tools and resources, and adapt based on the information received. This completes our high-level overview of the Model Context Protocol. We've established why it's needed, what it does, and how its core primitives (tools, resources, and prompts) provide a powerful and extensible framework for AI agent interactions.

## Why Now? The Convergence

MCP didn't appear randomly. Three things converged in late 2024:

1. **LLMs finally escaped the lab** — Claude, ChatGPT, Gemini became AI agents, not just chatbots. They needed to *do* things, not just talk about them.

2. **Everyone built custom integrations** — Companies like Anthropic, OpenAI, and Google all independently hit the same problem: their AI systems needed standard ways to talk to tools. They were all solving the same problem separately.

3. **Standardization became urgent** — The fragmentation got so bad that Anthropic said: "Let's just open-source a standard and invite everyone." And everyone said yes. That's rare.

The timing matters. A year earlier, the AI landscape wasn't mature enough. A year later, we'd have even more vendor-specific solutions. But in late 2024, the moment was right.

## What MCP Doesn't Do (And Why That Matters)

MCP solves a real problem: standardizing how AI systems talk to tools. But it's not a magic solution, and it's worth being clear about its limits:

- **MCP Doesn't Handle Access Control** : MCP says "here are the tools available." It doesn't say "this user can call this tool." That's still your job. Example: You expose a "delete_order" tool via MCP. MCP makes it discoverable and callable. But your backend still needs to check: "Is this user allowed to delete this order? Does it belong to their account?". If you get this wrong, you've got a security hole.

- **MCP Doesn't Fix Hallucination** : An LLM might have access to the right tool but use it *wrong*. Example: You expose a `send_email` tool with parameters (recipient, subject, body). The AI might:
  - Call it with the wrong recipient (hallucinated email address)
  - Send the right message to the wrong person
  - Construct a malicious prompt in the body
 MCP gives access. It doesn't guarantee correct usage. That's still an LLM problem.

- **You're Trading One Lock-in for Another** : MCP frees you from custom integration code. But you're betting on Claude, ChatGPT, or Gemini being around and not changing their APIs dramatically.Is that a good bet? Probably...these are major platforms. But it's worth acknowledging you're shifting risk, not eliminating it.

- **Building Reliable Servers is Still Hard** : MCP defines the protocol. It doesn't define:
  - How to retry failed API calls
  - How to handle timeouts
  - How to log errors
  - How to monitor performance
  - How to scale if the AI system calls your server 1000x per second

 Your MCP server is still software. It needs to be robust, tested, and monitored.

- **Performance Has a Cost** : Each tool invocation is another round-trip: AI system → your server → external API → your server → AI system. That's extra latency. For most use cases, fine. For real-time systems? You might notice.

- **MCP Isn't Always Worth It** : If you're building a simple assistant that needs to call one API, MCP might be overkill. You could just write custom integration code in an afternoon.
MCP shines when you have *many* tools, *many* AI consumers, and you want to avoid repeating integration work. It's an investment that pays off at scale.


## What's Next?

Now that you have a high-level understanding of the "what" and "why" of MCP, you're ready to dive deeper. In the [**next post in this series**]({{< relref "/blog/model-context-protocol/mcp-protocol-mechanics-and-architecture/">}}), we'll explore the "how" by examining the protocol mechanics, including:

- How messages are structured using JSON-RPC 2.0.
- How stateful sessions are managed.
- How transports like `stdio` and `HTTP + SSE` are used.

Subsequent posts will then get into hands-on coding, where we'll build our own MCP Servers and Clients. Stay tuned!
