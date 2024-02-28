---
title: "gRPC and .NET: Crafting Cutting-Edge APIs"
lastmod: 2024-01-31T09:39:01+10:00
date: 2024-01-31T09:39:01+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - api
  - grpc
  - architecture
categories:
  - api
#slug: kubernetes/introduction-to-open-policy-agent-opa/
summary: "Dive into gRPC with this tutorial – understand Protocol Buffers, define services, and implement a gRPC server in .NET for fast, efficient communication."
ShowToc: true
TocOpen: false
images:
  - images/getting-started-with-grpc.png
cover:
    image: "images/getting-started-with-grpc.png"
    alt: "Getting started with gRPC "
    caption: "Getting started with gRPC"
    relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---
> The code for this blog post is [available here.](https://github.com/PradeepLoganathan/CustomerAPI)

# Introduction

In the evolving landscape of web services and API design, the choice of architectural style plays a pivotal role in shaping the efficiency, scalability, and robustness of API interactions. Architectural styles such as SOAP and [REST]({{< ref "/blog/rest/rest-api-what-is-rest" >}}) have long dominated API design. The technical landscape is evolving rapidly and technologies such as gRPC and [GraphQL]({{< ref "/blog/api/getting-started-with-graphql" >}}) now provide strong alternatives to these established architectural frameworks. A good understanding of the various API architectural styles is key to building high performance API's. [This blog post]({{< ref "/blog/rest-vs-graphql-vs-grpc" >}}) compares the various API architectures such as REST, GraphQL and gRPC. In this blog post we will look at how gRPC helps build a fast and efficient API and also implement an "HelloWorld" gRPC api with dotnet.

gRPC is a modern, open-source, light-weight, high-performance Remote Procedure Call (RPC) framework. It enables services to communicate efficiently with built-in support for load balancing, tracing, health checking, and authentication. Developed by Google, gRPC is a CNCF incubating project with the most GitHub stars. gRPC is a high-performance, language-agnostic RPC framework, leveraging HTTP/2 for transport, Protocol Buffers as the interface description language, and providing features like authentication, load balancing, and many others. The primary strength of gRPC lies in its ability to facilitate efficient, low-latency communication between services, making it an ideal choice for microservices architectures and systems where performance is paramount. Since its introduction, gRPC has seen widespread adoption across various industries and applications, particularly benefiting microservices architectures due to its efficiency and cross-platform capabilities.

# The Compelling Case for gRPC: Performance and Flexibility

Choosing an architectural style to build API's is a matter of trade offs and prioritization of features. The primary advantages of using gRPC are:

- High Performance: Utilizes HTTP/2 protocol, enabling multiplexed requests and server push capabilities, significantly reducing latency and bandwidth usage. [See this blog post]({{< ref "/blog/http2" >}}) to understand more about these HTTP2 features.
- Contract-First API Development: Uses Protocol Buffers to define service contracts, ensuring a clear, platform-independent, and language-neutral definition of service interfaces and data structures.
- Streaming Support: Offers four types of service methods, including server streaming, client streaming, and bidirectional streaming, facilitating real-time communication and efficient data transfer.
- Language Agnostic: Supports code generation in multiple languages, allowing seamless interoperability between services written in different programming languages.

# Decoding Protocol Buffers: The Foundation for Efficient Data Exchange

Before diving into building a gRPC service using dotnet, it is essential to understand protocol buffers. Protocol Buffers (Protobuf) might appear as an Interface Definition Language (IDL) at first glance, but it's much more. It's a powerful tool for defining and exchanging structured data efficiently across diverse systems and languages. They are a language-agnostic, platform-neutral, extensible mechanism for serializing data. In Protobuf, we do not write any logic as we do in a programming language, but instead, we write data schemas. These schemas are contracts to be used for serialization and are to be fulfilled by deserialization. They are a method of serializing structured data, similar to XML or JSON, but smaller, faster, and simpler. You define how you want your data to be structured once, and then you can use special generated source code to easily write and read your structured data to and from a variety of data streams and using a variety of languages.

Protocol Buffers provide several advantages:

- ___Language-agnostic and Platform-neutral___: Define data structures once in a human-readable .proto file and generate code for various languages (C++, Java, Python, Go, etc.) and platforms, ensuring seamless communication.
- ___Strongly-Typed Interfaces___: Ensures type safety in communication between client and server, preventing data corruption and unexpected behavior.
- ___Code Generation___: Protobuf compilers automate the creation of boilerplate code for data serialization and deserialization, saving you time and effort.
- ___Binary Efficiency___: Binary serialization results  in a compact binary format compared to human-readable formats like JSON or XML, resulting in smaller data sizes and faster processing, especially for large datasets.
- ___Schema Evolution___: Add new fields to your message formats without breaking existing implementations. Older clients will simply ignore new fields, preserving backward compatibility.

# Building Blocks: Defining Data Structures with Protocol Buffers

The heart of Protobuf lies in defining messages, which are blueprints for structured data. These messages are composed of named fields, each with a specific type. Understanding these types is crucial for crafting efficient and accurate data definitions.

## Scalar Types

These are the fundamental building blocks, representing basic data values such as

- Integers: int32, int64 for whole numbers (e.g., age, product ID).
- Strings: string for text data (e.g., name, address).
- Floating-point numbers: float, double for decimal values (e.g., price, scientific measurements).
- Booleans: bool for true/false values (e.g., active status, flag).

## Composite Types

Complex data structures can be created by combine these basic types such as

### Nested messages

Create nested message hierarchies to represent intricate data relationships (e.g., Address message containing nested Street, City, and Country messages). In the example below, the Person message has a nested Address message, effectively grouping address-related data under a single structure.

```protobuf
message Person {
  string name = 1;
  int32 age = 2;
  
  message Address {
    string street = 1;
    string city = 2;
    string state = 3;
  }
  
  Address address = 3;
}
```

### Enums

Define named constants for a set of related values. In the example below, the Color enum defines constants for different colors with assigned integer values.

```protobuf
enum Color {
  RED = 0;
  GREEN = 1;
  BLUE = 2;
}
```

### Maps

Represent key-value pairs where keys can be strings or integers (e.g., user_preferences map with string keys and string values).

```protobuf
message User {
  Person person = 1;
  Color color = 2;
  map<string, string> user_preferences = 3;
}
```

## Well-Known Types

Google provides pre-defined types for common data structures, simplifying usage:

- Timestamp: Represents a point in time with nanosecond precision.
- Duration: Represents a span of time between two timestamps.
- StringValue, Int32Value, etc.: Wrapper types for basic types.

## Custom Types

Extend the capabilities beyond built-in options for specific needs:

- Extend existing message types with additional fields for specialized data.
- Define custom options for data validation or behavior control.

By understanding these different types and their uses within message structures, you can effectively design data exchange mechanisms that are efficient, flexible, and interoperable across diverse systems.

# Building Blocks: Designing RPC Services with Protobuf

Protocol Buffers not only allow us to structure data but also define the actions that can be performed on that data through Remote Procedure Calls (RPCs). In the context of gRPC, these actions are encapsulated within services. In Protobuf, a service is akin to an interface in many programming languages—it defines a contract for what operations can be performed but not their implementation. This contract specifies the methods that can be called remotely, their request parameters, and their expected response types.

## Key Components of a Service

A service definition in a .proto file consists of the following:

- The service keyword: This keyword indicates the beginning of a service definition.
- Service Name: A descriptive name for the set of related actions (e.g., CustomerService).
- RPC Methods: Individual methods that can be called remotely by a client. Each method includes:
- Method Name: A descriptive name for the action (e.g., GetCustomerById).
- Input Parameter Type: The type of message the method expects as input.
- Output Parameter Type: The type of message the method will return as a response.

An example of a simple service is below

```proto
service CustomerService {
  // Retrieves a customer by their ID.
  rpc GetCustomerById(GetCustomerByIdRequest) returns (GetCustomerResponse);

  // Creates a new customer.
  rpc CreateCustomer(CreateCustomerRequest) returns (CreateCustomerResponse);
}
```

## Types of RPC Methods

gRPC supports four primary types of service methods to accommodate different communication patterns:

- Unary RPCs: The most basic form of RPC – a client sends a single request and receives a single response.
- Server Streaming RPCs: The server streams a sequence of messages as a response to a single client request.
- Client Streaming RPCs: The client streams a sequence of messages to the server, which then processes and sends a single response.
- Bidirectional Streaming RPCs: Both the client and server can independently send streams of messages, enabling full-duplex communication.

The services and message types defined using Protocol Buffers form the fundamental contract for your gRPC API.Protobuf services are directly leveraged by gRPC to generate the scaffolding for our server and client code. This automation significantly reduces the manual coding effort required to set up network communication, allowing developers to concentrate on implementing the business logic behind these service methods. gRPC takes care of the heavy lifting involved in data serialization, network transmission, and error handling, guided by the service definitions in our .proto files.

# Protobuf in Action: Defining Messages and Services

Let us build a simple .proto file defining a Customer message along with a CustomerService service. The Customer message includes some basic fields, and the CustomerService service includes RPC methods for retrieving a customer by ID and creating a new customer. The code for the proto file is below

```protobuf
syntax = "proto3";

package customer;

// The customer message definition.
message Customer {
  int32 id = 1;                  // Unique identifier for the customer
  string first_name = 2;         // First name of the customer
  string last_name = 3;          // Last name of the customer
  string email = 4;              // Email address of the customer
}

// The customer service definition.
service CustomerService {
  // Retrieves a customer by their ID.
  rpc GetCustomerById(GetCustomerByIdRequest) returns (GetCustomerResponse);

  // Creates a new customer.
  rpc CreateCustomer(CreateCustomerRequest) returns (CreateCustomerResponse);
}

// Request message for GetCustomerById.
message GetCustomerByIdRequest {
  int32 customer_id = 1;         // ID of the customer to retrieve
}

// Response message for GetCustomerById.
message GetCustomerByIdResponse {
  Customer customer = 1;         // The customer details
}

// Request message for CreateCustomer.
message CreateCustomerRequest {
  Customer customer = 1;         // The customer details to create
}

// Response message for CreateCustomer.
message CreateCustomerResponse {
  Customer customer = 1;         // The newly created customer details
  bool success = 2;              // Whether the creation was successful
  string message = 3;            // Additional message, e.g., error message
}
```

# Building Your First gRPC Service in .NET

Creating a gRPC service involves defining your service and message types in a .proto file, generating the server and client-side code, and then implementing the service logic. Here's how you can build your first gRPC service in .NET:

## Creating the gRPC project

we can create the gRPC project using the dotnet cli. This command ```dotnet new grpc -o CustomerAPI```  creates a new gRPC project in a directory named CustomerAPI.

## Define the Service and Messages

We now need to create the protobuf definition.

- Navigate to the Protos directory in your project.
- Create a new file named Customer.proto.
- Define your service and the request and response message types. For example:

```proto

syntax = "proto3";

option csharp_namespace = "CustomerAPI";

package customer;

// The customer message definition.
message Customer {
  int32 id = 1;                  // Unique identifier for the customer
  string first_name = 2;         // First name of the customer
  string last_name = 3;          // Last name of the customer
  string email = 4;              // Email address of the customer
}

// The customer service definition.
service CustomerService {
  // Retrieves a customer by their ID.
  rpc GetCustomerById(GetCustomerByIdRequest) returns (GetCustomerByIdResponse);

  // Creates a new customer.
  rpc CreateCustomer(CreateCustomerRequest) returns (CreateCustomerResponse);
}

// Request message for GetCustomerById.
message GetCustomerByIdRequest {
  int32 customer_id = 1;         // ID of the customer to retrieve
}

// Response message for GetCustomerById.
message GetCustomerByIdResponse {
  Customer customer = 1;         // The customer details
}

// Request message for CreateCustomer.
message CreateCustomerRequest {
  Customer customer = 1;         // The customer details to create
}

// Response message for CreateCustomer.
message CreateCustomerResponse {
  Customer customer = 1;         // The newly created customer details
  bool success = 2;              // Whether the creation was successful
  string message = 3;            // Additional message, e.g., error message
}
```

## Configure the Protobuf Tooling

Edit the .csproj file in your project and ensure it contains a reference to the Grpc.AspNetCore package and a <Protobuf> item group like this:

```xml
<ItemGroup>
  <Protobuf Include="Protos\Customer.proto" GrpcServices="Server" />
</ItemGroup>
```

This configuration tells the .NET build system to generate the C# classes for your service and messages.

## Build the Project

Run dotnet build. The build process automatically generates the C# classes for the service and messages defined in your .proto files.

## Implementing the Server Side

- Navigate to the Services directory.
- Create a new C# class file named CustomerService.cs.
- Implement the service class by inheriting from the generated base class and overriding the method(s).

The code for this is in the github repository linked above.

You've now successfully defined your service and message types, generated the necessary code, implemented the server side of your gRPC service. We can test this using a tool such as grpcurl.

## Testing the server

`grpcurl` is a command-line tool designed to interact with gRPC servers. It's akin to curl but is specifically tailored for gRPC, allowing developers to make gRPC calls from the terminal. grpcurl is immensely useful for testing, inspecting, and interacting with gRPC services without the need for compiled client code or a graphical user interface. `grpcurl` can be installed on macOS via Homebrew with brew install grpcurl, on Windows via Chocolatey with choco install grpcurl, or you can download precompiled binaries from its [GitHub releases page](https://github.com/fullstorydev/grpcurl/releases) for various operating systems. To test the service run the server with `dotnet run` and the use `grpcurl` on the command line.

### Discovering services and methods

> Note : In the service implemented above we are supporting reflection. If the server does not support reflection, you'll need to provide the proto files using the -proto option or have them precompiled into a descriptor set file with the -protoset option.

#### List Services

We can list all the services implemented by the Customer API with

`grpcurl -plaintext localhost:5024 list`

This outputs the services

`customer.CustomerService
grpc.reflection.v1alpha.ServerReflection`

#### Describe Service

We can now inspect the service's methods with

`grpcurl -plaintext localhost:5024 describe customer.CustomerService`

This outputs the service details as below

`customer.CustomerService is a service:
service CustomerService {
  rpc CreateCustomer ( .customer.CreateCustomerRequest ) returns ( .customer.CreateCustomerResponse );
  rpc GetCustomerById ( .customer.GetCustomerByIdRequest ) returns ( .customer.GetCustomerByIdResponse );
}`

#### Call Methods

We can now call the methods implemented by the service. Let us call the CreateCustomer method on the CustomerService with 

```shell
grpcurl -plaintext \
        -d '{
              "customer": {
                "id": 998, 
                "first_name": "John",
                "last_name": "Doe",
                "email": "john.doe@example.com"
              }
            }' \
        localhost:5024 customer.CustomerService/CreateCustomer
```

Calling this method prints the belopw output indicating succesful creation of the customer.

```json
{
  "customer": {
    "id": 998,
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com"
  },
  "success": true,
  "message": "Customer created successfully"
}
```

We can also retrieve the customer we now created by calling the GetCustomerById method

```shell
grpcurl -plaintext \
    -d '{
            "customer_id": "998"
        }' \
    localhost:5024 customer.CustomerService/GetCustomerById
```

Calling this method produces this output

```json
{
  "customer": {
    "id": 998,
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com"
  }
}
```

We have now successfully created a gRPC service in dotnet. We have authored the proto file to define messages and services. We have also implemented the service. We then were able to successfully call the service using `grpcurl` command line tool.

In the next section, we'll discuss best practices in gRPC development to ensure your services are efficient, maintainable, and secure. 
