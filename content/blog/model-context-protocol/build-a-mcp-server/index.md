---
title: "Building a simple MCP Server"
lastmod: 2025-05-09T14:29:22+10:00
date: 2025-05-09T14:29:22+10:00
draft: true
Author: Pradeep Loganathan
tags: 
  - 
  - 
  - 
categories:
  - 
#slug: kubernetes/introduction-to-open-policy-agent-opa/
description:  "Learn how to set up a Model Context Protocol (MCP) server using NuGet packages in Visual Studio Code, with GitHub Copilot integration for development and testing." 
summary:  "This guide covers building an MCP server in C# (.NET) with NuGet package management, running it in VS Code, and integrating with GitHub Copilot for AI-assisted development." 
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


## Introduction


In parts [one](https://pradeepl.com/blog/model-context-protocol/introduction-to-model-context-protocol/) and [two](https://pradeepl.com/blog/model-context-protocol/mcp-protocol-mechanics-and-architecture/) of this series, we explored what Model Context Protocol (MCP) is, why it matters, and how it works under the hood. Now it's time to get practical: in this post, we'll walk through building a simple MCP server step-by-step, from scratch.

We'll use a straightforward example that provides text manipulation tools, such as reversing strings, counting words, checking palindromes, and more.

## What You'll Build

We'll create an MCP server in C# (.NET) that provides the following string manipulation tools. The MCP server will use STDIO server transport for communication. We will integrate this MCP server into Github Copilot within Visual Studio Code.

## Prerequisites

Before we start, ensure you have:

-   [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) installed.
-   [Visual Studio Code](https://code.visualstudio.com/) or your preferred IDE.
-   The [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) extension installed and enabled in Visual Studio Code to seamlessly integrate and test your MCP tools.


## Step 1: Setting up your MCP Project

To get started lets Create a new directory for your MCP server and initialize it as a .NET consoleproject:

```bash
dotnet new console -o simple-mcp-server
cd simple-mcp-server
```

Then add the necessary MCP NuGet package:

```bash
dotnet add package ModelContextProtocol --prerelease
dotnet add package Microsoft.Extensions.Hosting
```

The package `ModelContextProtocol` provides the core MCP libraries, types, and classes needed to build an MCP server in .NET. It includes the attributes and server infrastructure (`McpServerToolType`, `McpServerTool`, etc.) that help your C# methods become discoverable tools for MCP clients, such as LLMs or developer tools. We use the `Microsoft.Extensions.Hosting` nuget package to provide a lightweight hosting framework for your MCP server. It simplifies running background services, configuring dependency injection, and managing the server lifecycle.

## Step 2: Implementing Your Tools


Create a new file `MyTools.cs` in your project directory and paste the provided tools implementation. I am creating a bunch os string manipulation tools that can be used by the LLM.

```csharp
using System.ComponentModel;
using System.Linq;
using ModelContextProtocol.Server;

namespace SimpleTools;

[McpServerToolType]
public class MyTools
{
    [McpServerTool, Description("Reverse a string")]
    public string ReverseString(string input)
    {
        if (input is null) return string.Empty;

        var chars = input.ToCharArray();
        System.Array.Reverse(chars);
        return new string(chars);
    }

    [McpServerTool, Description("Convert a string to upper-case")]
    public string ToUpperCase(string input) => input?.ToUpperInvariant() ?? string.Empty;

    [McpServerTool, Description("Convert a string to lower-case")]
    public string ToLowerCase(string input) => input?.ToLowerInvariant() ?? string.Empty;

    [McpServerTool, Description("Check if a string is a palindrome (ignoring case and non-letters)")]
    public bool IsPalindrome(string input)
    {
        if (string.IsNullOrWhiteSpace(input)) return true;

        var filtered = new string(input
            .ToLowerInvariant()
            .Where(char.IsLetterOrDigit)
            .ToArray());

        return filtered.SequenceEqual(filtered.Reverse());
    }

    [McpServerTool, Description("Count the number of words in a string (whitespace-separated)")]
    public int CountWords(string input)
    {
        if (string.IsNullOrWhiteSpace(input)) return 0;

        return input.Split((char[])null, StringSplitOptions.RemoveEmptyEntries).Length;
    }

    [McpServerTool, Description("Repeat a string N times")]
    public string RepeatString(string input, int count)
    {
        if (input is null || count <= 0) return string.Empty;

        return string.Concat(Enumerable.Repeat(input, count));
    }

    [McpServerTool, Description("Return a substring given start index and length")]
    public string Substring(string input, int startIndex, int length)
    {
        if (string.IsNullOrEmpty(input)) return string.Empty;
        if (startIndex < 0 || startIndex >= input.Length) return string.Empty;

        return input.Substring(startIndex, Math.Min(length, input.Length - startIndex));
    }

    [McpServerTool, Description("Replace all occurrences of a substring with another substring")]
    public string Replace(string input, string oldValue, string newValue)
    {
        if (input is null) return string.Empty;

        return input.Replace(oldValue ?? string.Empty, newValue ?? string.Empty);
    }
}

```
The above code provides a bunch of stinr manuipulation tools.

## Step 3: Integrating Tools into MCP Server Host


Modify your `Program.cs` file to host your MCP tools:

```csharp
using Microsoft.Extensions.Hosting;
using ModelContextProtocol.Server;

var builder = Host.CreateApplicationBuilder(args);

builder.Services
    .AddMcpServer()
    .WithStdioServerTransport()
    .WithToolsFromAssembly(typeof(SimpleTools.MyTools).Assembly);

await builder.Build().RunAsync();`
```

## Step 4: Running the MCP Server


Run the MCP server locally using the following command:

```bash
dotnet run
```
Your MCP server is now up and running, ready to accept requests!

## Step 5: Testing Your MCP Server


You can test your MCP server locally with [mcp-dev](https://www.npmjs.com/package/@model-context-protocol/dev):

bash

CopyEdit

`npm install -g @model-context-protocol/dev
mcp-dev stdio`

This tool lets you interact with your MCP tools directly from the terminal.

Example interaction:

graphql

CopyEdit

`> ReverseString input="hello MCP"
Output: "PCM olleh"`

## Step 6: Integrating with Github Copilot in VS Code 

For developers using Visual Studio Code, there's an even tighter integration path for MCP servers, particularly for enhancing AI-assisted coding workflows with tools like GitHub Copilot Chat.

### A. The `mcp.json` Configuration File

VS Code allows users to define and configure MCP servers directly within the IDE using a special configuration file named `mcp.json`. This file can be placed in the `.vscode` directory of a workspace (for project-specific servers) or in user settings (for globally available servers).

Here's a minimal example of what a `.vscode/mcp.json` file might look like to configure the `MyFirstMcpServer` built in this tutorial:

```json
//.vscode/mcp.json
{
    "servers": {
        "simple-mcp-server": {
            "type": "stdio",
            "command": "dotnet",
            "args": [
                "run",
                "--project",
                "/home/pradeepl/source/repos/simple-mcp-server/simple-mcp-server.csproj"
            ]
        }
    }
}
```

Key fields in this configuration include :

-   **`"type": "stdio"`**: Specifies the transport protocol.
-   **`"command": "dotnet"`**: The executable to run the server.
-   **`"args": [...]`**: Arguments to pass to the command. Here, it tells `dotnet` to run the project. 

This `mcp.json` configuration standardizes how different MCP servers, regardless of their implementation language (C#, Python, Node.js, etc.), are declared and launched by client applications like VS Code. The IDE doesn't need to know the specifics of how each server is built; it just needs this configuration to manage and communicate with them.

### B. Benefits of VS Code Integration

Configuring an MCP server this way allows VS Code features, notably Copilot Chat when in "agent mode," to discover and utilize the tools provided by the custom server directly within the editor. This can significantly streamline development workflows by augmenting the AI assistant with domain-specific or project-specific tools. This direct support within VS Code signals a strategic effort to make MCP a fundamental part of the local developer environment, potentially fostering the creation of many small, specialized MCP servers.

### C. How to Use (Briefly)

After creating the `.vscode/mcp.json` file and restarting or reloading VS Code if necessary, you will see an option to start the server as in the screen shot below.
![alt text](images/mcp.json.png)

Once the server has started and discovered the tools available in this MCP server.. you can follow the steps below.
1.  Open the Chat view (e.g., with GitHub Copilot).
2.  Switch to "Agent mode" (if available and supported by the Chat extension).
![alt text](images/copilot-agent-mode.png)
3.  There should be an option to select or view available tools, where "my-echo-server" and its tools (`Echo`, `ReverseEchoAsync`) would appear.
![alt text](images/mcp-server-tools.png)
4.  One could then interact with Copilot Chat, and it might choose to use these custom tools if relevant to the prompt.

This section serves as a brief introduction, as a full tutorial on VS Code's MCP integration is beyond the current scope.

## What's Next?

You now have a working MCP server ready for integration. Here are some ideas for further exploration:

-   Expand your server with additional tools for database access, API interaction, or AI inference.
-   Deploy your MCP server to cloud services like Azure App Service or AWS Lambda.
-   Write more advanced tools to handle streaming or large-scale data manipulation.

## Conclusion


In this three-part series, we've explored the power and flexibility of the Model Context Protocol. You've learned what MCP is, its underlying architecture, and now how to build your own MCP server. With these foundational skills, you're ready to unlock endless possibilities by connecting powerful AI models to the rich contexts they need.