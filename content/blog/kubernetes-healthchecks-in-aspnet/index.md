---
title: "Building Resilient ASP.NET Applications with Kubernetes Health Checks"
lastmod: 2023-12-08T14:37:12+05:30
date: 2023-12-08T14:37:12+05:30
draft: true
Author: Pradeep Loganathan
tags: 
  - 
  - 
  - 
categories:
  - 
#slug: kubernetes/introduction-to-open-policy-agent-opa/
summary: ""
ShowToc: true
TocOpen: false
images:
  - "cover.jpg"
cover:
    image: "cover.jpg"
    alt: ""
    caption: ""
    relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---


## Add Health Checks Services

Add health checks to your service collection.

```
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddHealthChecks()
    .AddCheck<LivenessProbe>("Liveness")
    .AddCheck<ReadinessProbe>("Readiness");

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

endpoints.MapHealthChecks("/healthz", new HealthCheckOptions
{
    Predicate = healthCheck => healthCheck.Name == "Liveness"
});
app.MapHealthChecks("/health/liveness", new HealthCheckOptions 
{
    Predicate = healthCheck => healthCheck.Name == "Liveness"
});

app.MapHealthChecks("/health/readiness", new HealthCheckOptions 
{
    Predicate = healthCheck => healthCheck.Name == "Readiness"
});

app.MapRazorPages();

app.Run();
```

## Create Health Check Classes

Create classes that implement the IHealthCheck interface. These classes represent different health checks (like liveness and readiness).

```dotnet
public class LivenessProbe : IHealthCheck
{
    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = new CancellationToken())
    {
        // Liveness probe logic here
        return Task.FromResult(HealthCheckResult.Healthy("Application is running"));
    }
}

public class ReadinessProbe : IHealthCheck
{
    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = new CancellationToken())
    {
        // Readiness probe logic here
        bool isReady = true; // Replace with actual readiness logic
        if (isReady)
        {
            return Task.FromResult(HealthCheckResult.Healthy("Application is ready"));
        }

        return Task.FromResult(HealthCheckResult.Unhealthy("Application is not ready"));
    }
}
```