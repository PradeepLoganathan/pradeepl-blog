---
title: "Adding security to OAS 3 / Swagger in .net core 3.1 using swashbuckle"
date: "2020-06-25"
categories: 
  - "api"
  - "aspnetcore"
  - "rest"
tags: 
  - "api"
  - "oas"
  - "oas-3-0"
  - "oas3"
  - "security"
  - "securityrequirement"
  - "securityscheme"
  - "swagger"
---

## OpenAPI Security Schemes

As part of documenting API's, OpenAPI 3.0 lets you describe how your APIs are protected using various security schemes and their security requirements. Defining the security requirements for an API is key to enable developers to use the API. The OAS 3 definitions for security is described in a [previous blog post here](https://pradeeploganathan.com/api/openapi-specification-swagger/#Security). It can be used to specify the below security schemes for an API

1. HTTP authentication schemes that use the Authorization header
    1. Basic
    2. Bearer
2. API keys in headers, query string or cookies
    1. Cookie authentication
3. OAuth 2
4. OpenID Connect Discovery

Swashbuckle and NSwag are examples of nuget packages that provide functionality to generate swagger documents for API's.

Let us look at using swashbuckle to generate the swagger definition and to also define the bearer, API key and oAuth2 Security schemes below. We can install swashbuckle using

Dotnet install Swashbuckle.AspNetCore -Version 5.3.3

Installing swashbuckle gives you access to below 3 namespaces which are key to generate the OAS document and the corresponding Swagger UI.

- Swashbuckle.AspNetCore.SwaggerUI
- Swashbuckle.AspNetCore.Swagger
- Swashbuckle.AspNetCore.SwaggerGen

Swashbuckle uses the OpenAPISecurityScheme object to specify the security schemes and the OpenApiSecurityRequirement object to specify the Security requirements needed by the API. The Security scheme and the security requirements can be added to the generated OAS json using the AddSecurityDefinition & the AddSecurityRequirement methods, respectively. The sections below detail adding a bearer, api key and oAuth2 security requirements to the OAS json by calling the AddSwaggerGen method in ConfigureServices metod of the startup class.

### Bearer Security Scheme

The code below specifies a bearer security scheme and the associated parameters for this security scheme. We are specifying the name of the http authorization scheme as defined in RFC7235 to be bearer, we are specifying that the bearer token is in the header with the scheme type of http.

<script src="https://gist.github.com/PradeepLoganathan/5d5572eff6d67af1051b4e0e4face10d.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/5d5572eff6d67af1051b4e0e4face10d">View this gist on GitHub</a>

The above code results in the swagger UI requiring a [JWT bearer token](https://pradeeploganathan.com/security/jwt/) to authorize requests to the API as below

![](images/JWT-token-Swagger-1024x471.png)

Bearer token - Swagger UI

### API Key Security Scheme

The code below specifies an API key security scheme. This code can be used when we use an API key to authenticate requests to the API.

<script src="https://gist.github.com/PradeepLoganathan/a802c9b469c1eccef5a3457f585f587b.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/a802c9b469c1eccef5a3457f585f587b">View this gist on GitHub</a>

### OAuth2 Security Scheme

We can also add an implicit flow grant as a security scheme using the code below.

<script src="https://gist.github.com/PradeepLoganathan/aeedbdfc22fcf936ea78c5fee2ba4203.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/aeedbdfc22fcf936ea78c5fee2ba4203">View this gist on GitHub</a>

The above gists can be used to add different security specifications to the OAS document. This will result in the swagger UI using the defined security requirements as part of not only documenting the API but also in the Swagger UI.
