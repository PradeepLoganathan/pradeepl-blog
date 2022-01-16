---
title: "JWT - Creating a token server"
date: "2018-04-21"
categories: 
  - "security"
---

### Three part series on JWT tokens

[Part 1: What is a JWT Token.](http://pradeeploganathan.com/security/jwt/) Part 2: Creating a JWT token server in ASP.net core 2.0 (This post) [Part 3: Accessing and Consuming a JWT token protected service in Angular 5+.](http://pradeeploganathan.com/security/jwt-angular-interceptor/)

In the previous [post](http://pradeeploganathan.com/security/jwt/), we understood the structure of a JWT and the process of issuing and validating JWT's. Now let's take a look at implementing a JWT token server which will serve tokens to users with the appropriate credentials. The primary namespaces involved are System.Security.Claims, System.IdentityModel.Tokens.Jwt and Microsoft.IdentityModel.Tokens.

### Token Server

In order to create a token server, I created a new ASP.Net core Web API and added a controller which allows anonymous access. The controller code to generate the JWT is below.All the action happens in the IssueToken method. This method takes a UserModel which represents a users credentials (User ID and password). If the credentials are valid, it generates a set of claims. It then creates a symmetric key using a secret string. and a signing credential using the HMAC SHA256 algorithm. A JWTSecurityToken is then created by passing the issuer, audience, claims, expiration time and the signing credentials generated previously into the constructor. The JwtSecurityTokenHandler is then used to serialize the token and send it back to the client in the response.

<script src="https://gist.github.com/PradeepLoganathan/ab8e48681e25e9dc36e62411cbccb581.js"></script>

The appsettings for the token server are below and are an example of how the JWT parameters can be configured in the appsettings.

<script src="https://gist.github.com/PradeepLoganathan/46385921cc433982e4c8600750505fce.js"></script>

### Resource Server

Now let's create an API which serves resources protected by an endpoint which requires a JWT token issued by the above token server. I created a regular .Net core Web API with the values controller. Let's assume that we need to protect the values controller. In the resource server, we need to add authentication services to the middleware pipeline.  To do so we need to change the ConfigureServices and the Configure method of the startup class as shown below. I am initially adding authentication to the middleware using the services.AddAuthentication in the Configure method. Additionally, I am passing in options to set the authentication scheme and the challenge scheme to JWTBearerDefaults.

<script src="https://gist.github.com/PradeepLoganathan/a69717dfee55c18febd25327aeb08038.js"></script>

Additionally, I have also added the \[Authorize\] attribute to the values controller to protect its route. After setting up the above configuration, calling the protected API in postman results in failure with a 401 Unauthorized. To be able to call this API we now need to provide a JWT token in the header.

![](images/Token-un-authenticated-request.png)

To get the token we need to call the token server and pass valid user credentials. Using postman we can call the token server and get the JWT token. The token is in the body of the response.

![](images/Token-server-postman.png)

Now we can call the protected API again but this time lets add the token using the header Authorization with a value of bearer and the token as shown below. This time the resource API returns successfully with a 201 OK and the results of the API call.

![](images/Token-authenticated-request.png)

That's it. We have implemented a simple JWT token server and have successfully built a protected API which will validate for a valid token when called. Please note that the authentication method proposed above is for understanding purposes only and is Not Safe For Work(NSFW).

In the [next post](http://pradeeploganathan.com/security/jwt-angular-interceptor/) let us look at calling the Token server from an Angular client and using an Angular 5 HTTP interceptor to add JWT tokens to the authorization header.

Photo by [Kevin Jarrett](https://unsplash.com/photos/ricbHp3PD9s?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/ticket-booth?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
