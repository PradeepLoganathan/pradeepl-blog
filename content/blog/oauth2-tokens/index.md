---
title: "OAuth 2.0 - Tokens, Client types, Endpoints and Scope"
date: "2017-07-13"
categories: 
  - "security"
---

There are two types of tokens in OAuth 2.0, the access token, and the refresh token.

## Access token

The access token represents the authorization of a specific application to access specific parts of a user’s data. Access tokens must be kept confidential in transit and in storage. The only parties that should ever see the access token are the application itself, the authorization server, and resource server.

The access token can only be used over an https connection, since passing it over a non-encrypted channel would make it trivial for third parties to intercept.

The access token response contains the following fields/parameters:

- access token: This is a mandatory parameter, defined by a string of characters, representing an authorization on behalf of the user who authorized the request, issued to the client application.
- expires in: This is a mandatory parameter that tells the client application for how much time the issued token is valid. This numeric value is in seconds, so in our example this token is valid for one hour.
- scope: This is an optional parameter defining which parts (or types) of protected resources can be accessed on behalf of the user. More information on access scope is provided later in this chapter.
- state: This is an optional parameter, used by the client for its own purposes, most commonly for security checks. The state value that the client application sends during the request will be the same as the one it will receive as part of the access token response, so this parameter can be used for defending against man in the middle attacks.
- refresh token: This parameter contains a string of characters that are to be used as a parameter when requesting a new token before its expiry. It is an optional parameter and some service providers don't use it.

A sample Access token is below

{  
"access\_token":"1/fFAGRNJru1FTz70BzhT3Zg",  
"expires\_in":3920,  
"token\_type":"Bearer"  
}

## Refresh token

Access tokens should always expire; it's a rare case to have an access token that has an infinite lifetime, which is also considered a bad security practice.  
The client uses the refresh token to get a new access token, by contacting the authorization server and supplying the data from the refresh token field. If this data is valid, the authorization server returns a new access token response to the client.

Refresh tokens mitigate the risk of long-lived access tokens leaking into the wild. The refresh token also limits the client credentials being sent over the wire to the auth service frequently.

## Client types

When registering the client, the authorization server must know which type of client is being registered. There are two types:

- Confidential client: This type of client application is capable of keeping the confidentiality of the credentials secure, for example, applications running on servers in secure/restricted environments
- Public client: These type of client applications are not capable of keeping the credentials secure, for example, pure JavaScript applications that run directly in the browser or mobile applications where the application logic is in a WebView

Additionally, clients are separated in three general profiles:

- Web application: This is considered to be a confidential client application, and it's meant to be a web application where data is stored securely on the server side of the application and cannot be accessed on the public/client side.
- User-agent-based application: This is an application that is first downloaded and then executed in a user-agent environment (for example, in a web browser). Since all data is downloaded, including credentials, this is a public application.
- Native application: This is also a public client. Applications that are installed on a device, which is used by the resource owner belong to this profile.

## Endpoints

An endpoint is an HTTP URL string that defines the address which should be used in a certain request by an entity capable of making requests.

In OAuth 2.0 there are three important endpoints.

Two of them are server endpoints:

- Authorization endpoint: The client uses this endpoint to be authorized from the resource owner. If successful, the client obtains an authorization grant. There are exceptions to this behavior, like in the implicit grant flow, where the client obtains an access token from this endpoint.
- Token endpoint: The client uses this endpoint to supply the authorization grant and get an access token in return.

And one is a client endpoint:

- Redirection (callback) endpoint: The authorization server uses this endpoint to return data with authorization credentials to the client

## Scopes

An OAuth scope represents a set of rights at a protected resource.  It is an identifier for one or more endpoints that you want to protect. When a microservice wants to call any of those endpoints, it first needs permission to do so. That permission is given in the form of a token containing the scope.Scopes are represented by strings in the OAuth protocol. They can be combined into a set by using a space-separated list.

Scopes are an important mechanism for limiting the access granted to a client. Scopes are defined by the protected resource, based on the API that it’s offering. Clients can request certain scopes, and the authorization server can allow the resource owner to grant or deny scopes to a given client during its request. Scopes are additive in nature. In some cases, a collection of scopes can be used to represent a role.

Photo Credit : [Josh](https://unsplash.com/@joshlikesdesign)
