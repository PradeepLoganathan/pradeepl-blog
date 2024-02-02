---
title: "Cross origin resource sharing CORS"
author: "Pradeep Loganathan"
date: 2017-07-10T12:25:09+10:00
draft: false
comments: true
toc: true
showToc: true
TocOpen: false
ShowPostNavLinks: true
ShowRssButtonInSectionTermList: true
summary: "Cross-Origin Resource Sharing or CORS is a mechanism that enables a web browser to perform cross-domain requests. Cross-domain requests are HTTP requests for resources hosted on a different domain than the domain of the resource making the request."
tags: 
  - "architecture"
  - "cloud"
  - "cloud native"
  - "REST"
  - "API"
categories: 
  - "REST"
series: ["REST"]
cover:
  image: CORS-cover.png"
  alt: "CORS"
  caption: "CORS"
  relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---

Cross-Origin Resource Sharing or CORS is a mechanism that enables a web browser to perform "cross-domain" requests. Cross-domain requests are HTTP requests for resources hosted on a different domain than the domain of the resource making the request. CORS is a [W3 Spec](http://www.w3.org/TR/cors/) supported in HTML5 that manages XMLHttpRequest access to a different domain. It provides a set of request and response headers for defining which domains can access data and which HTTP methods they can utilize. But first, let us understand what same origin policy and its associated challenges are.

## Same Origin Policy

Browsers implement a "same origin" policy for scripts to ensure security and prevent malicious attacks. A web application using XMLHttpRequest can only make HTTP requests to its own domain. The origin of a  resource such as a JavaScript file is defined by the domain of the HTML page which includes it.For e.g, I have a google analytics script embedded on my blog which is provided by Google. Since I copied it over into my scripts section, it has the same origin as my blog domain and can perform actions on my website. Imagine a scenario where you are logged into your online mail in your browser and click on a link which takes you to a malicious site in another tab. Without the same origin policy JavaScript on this malicious website can do anything with your mail account that you can do. It can send emails, downloading contacts etc. In an API enabled world, this gets even worse since the JavaScript on the browser can now call API's on your behalf without your explicit knowledge and permission.

However, with the prevalence and rapid rise of JavaScript frameworks such as Angular, REACT, Ionic, Vue and others, JavaScript code now needs to be able to access API's across domains natively. CORS enables this functionality transparently and securely. The server providing the resource is in charge and can decide to support CORS by using the necessary response headers and indicating the Domains allowed, the Headers supported, Methods allowed and the response headers that the client can read.

## CORS HTTP headers

If a server wants its resources to be available securely to other domains, it should use the below headers to control access to it resources. The headers are

- Access-Control-Allow-Origin: This header is used to control access to the resource and make it available for specific domains If you want to restrict it to specific domains( e.g. siteb.com ), the response header can be modified to allow the same by marking the header as Access-Control-Allow-Origin: https://siteb.com. If another site such as sitec.com tries to get access to this resource now, it will trigger an XMLHttpRequest error and deny access to the requesting JavaScript code. To allow access to the resource across all domains this header should be marked as Access-Control-Allow-Origin: \*.

- Access-Control-Allow-Methods: This header indicates the methods that can be used on the resource from other domains. The acceptable values are the HTTP verbs POST, PUT, GET, etc.

- Access-Control-Allow-Headers: This indicates a comma-separated list of headers accepted by the server providing the resource.

- Access-Control-Allow-Credentials: This is an optional header and if set to true indicates that the server allows cookies (or other user credentials) to be included on cross-origin requests. By default, CORS does not include cookies on cross-origin requests. To reduce the chance of Cross site request forgery (CSRF) vulnerabilities in CORS, CORS requires both the server and the client to acknowledge that it is ok to include cookies on requests. Doing this makes cookies an active decision, rather than something that happens passively without any control. The client code must set the withCredentials property on the XMLHttpRequest to true to give permission. The server must respond also with the Access-Control-Allow-Credentials header. Responding with this header to true means that the server allows cookies (or other user credentials) to be included on cross-origin requests.

- Access-Control-Expose-Headers: This is an optional header and provides explicit permission to the client to read response headers. This is primarily for compatibility with pre-CORS clients. This header is used in CORS preflight requests. It indicates how long the results of a preflight request can be cached. The results of this preflight request are the headers defined above primarily the Access-Control-Allow-Methods and Access-Control-Allow-Headers.

A client uses the below request headers to initiate a CORS request

- Origin: This defines where the actual request originates from.
- Access-Control-Request-Method: This defines the method used in the request.
- Access-Control-Request-Header: This defines the headers used in the request.

CORS also differs between a simple and a "non-simple" request. If a client makes a non-simple request, then it results in two HTTP calls to access the resource. The first call is an OPTIONS pre-flight request which determines if the second call should be issued.  The first preflight response indicates if the server allows the necessary headers and methods in the Access-Control-Allow-Headers and Access-Control-Allow-Methods response headers. The second call is the actual request and is dependent on the success of the preflight response.

An HTTP request is classified as a "non- Simple" request if

- It uses an HTTP verb other than a GET or POST (PUT, DELETE, PATCH )
- It uses any request headers other than Accept, Accept-Language, Content-Language, and a Content-Type of application/x-www-form-urlencoded, multipart/form-data, or text/plain.

A general preflight request header is as shown below.

```shell
OPTIONS /resource/foo  
Origin: http://myorigindomain.com  
Access-Control-Request-Method: POST  
Access-Control-Request-Headers: X-Custom-Header  
content-length: 7995
```

A valid CORS request always contains an Origin header. This Origin header is added by the browser, and cannot be controlled by the user. The value of this header is the scheme (e.g. HTTP), domain (e.g. mydomain.com) and port (included only if it is not a default port, e.g. 8080) from which the request originates. In response, the server sends back an Access-Control-Allow-Origin header as shown below

```shell
HTTP/1.1 200  
status: 200  
transfer-encoding:"chunked"  
content-type:"application/json; charset=utf-8"  
content-encoding:"gzip"  
vary:"Accept-Encoding"  
server:"Kestrel"  
Access-Control-Allow-Origin:http://myorigindomaincom  
Access-Control-Allow-Methods:GET, POST  
Access-Control-Allow-Headers:X-Custom-Header  
x-powered-by:"ASP.NET"  
date:"Sat, 17 Feb 2018 14:07:48 GMT"
```

In this case, the server responds with a Access-Control-Allow-Origin: \* which means that the resource can be accessed by any domain in a cross-site manner. If the resource owners at /api/testapi wished to restrict access to the resource to requests only from http://alloweddomain.org, they would send back:  
Access-Control-Allow-Origin: http://alloweddomain.org  
Note that now, no domain other than http://alloweddomain.org (identified by the ORIGIN: header in the request) can get access to the resource in a cross-site manner. The Access-Control-Allow-Origin header should contain the value that was sent in the request's Origin header.

## CORS in ASP.NET Core

In ASP.Net Core 3.1 CORS functionality for the pipeline is defined in the package Microsoft.AspNetCore.MVC.Cors. It can be included in the pipeline by adding cors to the middleware in the startup class as below.

```csharp
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddCors(options =>
            {
                options.AddPolicy("AllowAll",
                builder => builder.AllowAnyOrigin()
                                  .AllowAnyHeader()
                                  .AllowAnyMethod());
            });
            services.AddMvc();            
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseCors("AllowAll");
            app.UseMvc();
        }
    }
```
In the above startup class, I am adding CORS into the pipeline by calling Service.AddCors and defining a policy. The policy specified is a very liberal policy allowing all headers, origins, and methods. I am then configuring the service by calling app.UseCors() and specifying the policy defined above.

We can define custom CORS policies in ASP.Net core and apply them into the pipeline as needed. In the below example, I am defining two different CORS policies. The CORSPolicies.PublicAPI policy is used for production scenarios and the CORSPolicies.DevAPI policy is used for development purposes. The PublicAPI policy restricts the domains and the methods whereas the DevAPI policy used in the development environment places no such restrictions.

```csharp

readonly string CORSPolicies.PublicAPI = "corspolicy.public";
readonly string CORSPolicies.DevAPI = "corspolicy.dev";
    
services.AddCors(options =>
{
    options.AddPolicy(CORSPolicies.PublicAPI,
        builder => builder
            .AllowAnyHeader()
            .WithMethods("POST", "GET")
            .WithOrigins("https://domain1.com", "https://domain2.com"));

    options.AddPolicy(CORSPolicies.DevAPI,
        builder => builder
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowAnyOrigin());
});
```

We can specify the policy to be used based on the environment as below

```csharp
if (env.IsDevelopment())
{
    app.UseCors(CORSPolicies.DevAPI);
}
else
{
    app.UseCors(CORSPolicies.PublicAPI);
}
```

We can also use specific policies for specific endpoints by specifying the EnableCORS attribute at the controller level as below. This provides a fine-grained level of control over which CORS policy is applied at the controller and at the method level. We can also disable CORS policy for a specific method using the DisableCors attribute.

```csharp

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[AllowAnonymous]
[EnableCors(CORSPolicies.PublicApi)]
public class PublicApiControllerBase : ControllerBase
{
  [DisableCors]
  [HttpGet]
  public ActionResult<IEnumerable<string>> Get()
  {
    return new string[] { "hello", ".net Core 3.1" };
  }
}
```
