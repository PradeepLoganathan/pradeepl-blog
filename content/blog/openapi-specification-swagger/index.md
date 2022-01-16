---
title: "Open api specification (OAS) 3.0 - swagger"
date: "2020-06-20"
categories: 
  - "api"
  - "rest"
tags: 
  - "api"
  - "oas"
  - "rest"
  - "swagger"
---

### OpenAPI Specification

The OpenAPI specification, generally known by it’s former name Swagger, is a schema that can be used to construct a JSON or YAML definition of a restful API. The OpenAPI specification acts as a documentation tool allowing developers to easily describe their public APIs in a format that is widely known, understood, and supported. The OpenAPI spec is language agnostic. The APIs defined by the spec can be constructed in any language with any tool or framework. This specification is detailed here [https://www.openapis.org/](https://www.openapis.org/).

### Swagger vs Open API Specification

The terms Swagger and OpenAPI are used interchangeably. Swagger began in 2011 as a set of tools that allowed developers to represent API as code, to automatically generate documentation and client SDKs. The rights to Swagger were bought by SmartBear Software, who donated the rights of the specification format to the Linux Foundation, under the OpenAPI Initiative. The need for standardization when expressing API functionality in a platform, transport, and programming language agnostic way emerged as the OpenAPI Specification. On 1 January 2016, the Swagger specification was renamed to the OpenAPI Specification (OAS). Since then, a newer version, 3.0.0 of OAS, has been released. The Swagger website (https://swagger.io/) now focuses on tooling around the OpenAPI Specification, including ways to author an API specification and generate client- and server-side stubs (Swagger Editor, Codegen, and UI) to help developers consume the resulting API more easily. Thus, OpenAPI is the specification language itself, while Swagger is a set of tools that work with and around an OpenAPI specification.

The Open-API specification is defined [here](http://spec.openapis.org/oas/v3.0.3). Some of the tooling supporting version 3 of OAS is listed [here](https://github.com/OAI/OpenAPI-Specification/blob/master/IMPLEMENTATIONS.md)

### Open API Specification file structure

An Open API file allows you to describe your entire API, including the following:

- Available endpoints
- Endpoint operations (GET, PUT, DELETE, and so on)
- Parameter input and output for each operation
- Authentication methods
- Contact information, license, terms of use, and other information.

The structure of an Open API file version 3.0 and a corresponding sample is below

![](images/OAS3.png)

OAS 3.0 File structure

An overview of some of the commonly used OAS 3.0 schema objects are below

#### Info

- openapi (string): This specifies the OpenAPI specification version in use.
- info (object): Metadata about the API.
    - version (string): The version of the API identified by the specification. This is the version of the API itself, not the OpenAPI Specification.
    - title (string): The name of your API.
    - description (string): A brief description of your API.
    - contact (object): Support contact for the API.
        - name (string): The name of the contact.
        - url (string): A URL pointing to a page with contact information.
        - email (string): The contact email address.
    - termsOfService (string): A valid URL pointing to the Terms of Service for the API.
    - license (object): License information of the API.

<script src="https://gist.github.com/PradeepLoganathan/de5de6f50e9472c4410a4ac66d835f40.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/de5de6f50e9472c4410a4ac66d835f40">View this gist on GitHub</a>

#### Servers

The servers array is used to specify the list of servers hosting the API and has the below structure

- servers (array of objects): A list of servers hosting the API.
    - url (string): A valid URL to the target host. This may be a relative URL, relative from the location at which the OpenAPI specification is being served.
    - description (string): A short description of the host. This is useful for distinguishing between different hosts if multiple are specified.

<script src="https://gist.github.com/PradeepLoganathan/cd16e4998042689c25dc04e20dd39c82.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/cd16e4998042689c25dc04e20dd39c82">View this gist on GitHub</a>

#### Paths

The paths object represents all paths and operations exposed by the API. The paths object is a dictionary of paths and path item Objects. A path item object is a dictionary of HTTP verbs and Operation Objects. The Operation Object defines the behavior of the endpoint, such as what parameters it accepts and the type of responses it emits.

<script src="https://gist.github.com/PradeepLoganathan/bb954d1116cbb443693edf5cbb5c385d.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/bb954d1116cbb443693edf5cbb5c385d">View this gist on GitHub</a>

#### Components

Components holds a set of reusable objects. Components are used to minimize duplication within the specification. For example, if multiple endpoints may return a 401 Unauthorized error with the message "The Authorization header must be set", we can define a component called AuthHeaderNotSet, and reuse this object in place of the response definition. Components must be explicitly referenced from other parts of the specification using JSON references ($ref). Data types/schema, parameters, responses, request bodies, headers, security schemes, links, and callbacks can be defined as components.

#### Security

A list of Security Requirement Objects used by the API. The Security Requirement Object is a dictionary of security schemes that are common across different operations. For example, we require that the client provides a valid token on many endpoints; therefore, we can define that requirement here, and apply it in a DRY manner within each definition. For endpoints that do not require a token, we can override this requirement on an individual basis. The Security Requirement Object is a dictionary of security schemes that must be satisfied for a request to be authorized. If multiple schemes are specified, then each scheme must be satisfied

A complete overview of the OAS 3.0.3 specification is provided [here](https://swagger.io/specification/). An understanding of this spec is key to helping developers use an API effectively.

> Photo by [Denise Johnson](https://unsplash.com/@auntneecey?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](/s/photos/shape-definition?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
