---
title: "Mastering Kubernetes Health Probes: Ensuring Robust and Reliable Services"
author: "Pradeep Loganathan"
date: 2023-10-25T14:33:30+10:00

draft: false
comments: true
toc: true
showToc: true
TOCOpen: true

mermaid: true

description: "Health checks in Kubernetes enable applications to be more resilient by allowing for self-healing, efficient traffic management, and handling of diverse operational scenarios."

cover:
    image: "images/Kubernetes-health-checks.png"
    relative: true

images:
  - images/Kubernetes-health-checks.png

tags:
  - "health check"
  - "kubernetes"
  - "resilience"
---

# Introduction

One of the key factors in Kubernetes' success is its ability to facilitate the development and deployment of resilient and highly available applications. This is achieved through a combination of features, including its containerization approach, flexible scaling mechanisms, and robust health check mechanisms.

As a container orchestration system it is essential for Kubernetes to keep track of the health of the various nodes, pods and containers in the cluster. Kubernetes uses health checks to monitor the health of applications, containers & pods running in a cluster. Health checks are a critical part of the platform and are used by the Kubernetes control plane to ensure that your services are not just up and running, but also ready and capable of performing their intended functions effectively. Health checks allows kubernetes to take appropriate corrective action by replacing unhealthy components and route traffic to healthy ones. This functionality is critical and provides the high availability and resiliency features of kubernetes.  

By leveraging the power of health checks, Kubernetes empowers developers and operations teams to build robust and reliable applications that can withstand unexpected failures and maintain consistent service delivery. This, in turn, contributes to the overall success and adoption of Kubernetes as a platform for modern cloud-native applications.

# Health check types

In Kubernetes, health checks are primarily categorized into three types: Liveness Probes, Readiness Probes, and Startup Probes. Each serves a unique purpose in the lifecycle management of containers. The configuration and management of these health probes can be the difference between a smoothly running system and one plagued with interruptions and downtime. 

## Startup probe

A startup probe is used to identify if a container has started. If the startup probe fails the container is killed and the restartPolicy for the container is implemented. Startup probes run before any other probes. When a startup probe is configured the readiness and liveness probes are disabled until it is successful.  It is important to implement the startup probe in conjunction with the liveness and the readiness probes to prevent the possibility of these probes running before the container indicates that it has started up. The startup probe is configured using the ```spec.containers.startupprobe``` attribute of the pod configuration

## Liveness probe

A liveness probe determines if an application running within a container is healthy and functioning properly. Failure of a liveness health check may indicate that an application is unresponsive or deadlocked. If a liveness health check fails the kubernetes control plane will kill the container and restart it according to the configured ```restartPolicy```.  This is especially useful in cases where the pod may be running but the application itself may not be functioning properly. This automatic recovery mechanism is vital for self-healing in a Kubernetes environment ensuring application uptime and availability. It also improves application resilience by preventing cascading failures. The liveness probe is configured using the ```spec.containers.livenessprobe``` attribute of the pod configuration

## Readiness probe

A readiness probe is used to identify if a container is ready to recieve traffic. This probe is used to ensure that a container is fully up and running and can serve incoming connection requests. The readiness probe is executed periodically. This may seem redundant given that we have a startup probe. However, a lot of applications may need to perform additional initialization tasks post startup before they are ready to handle any incoming traffic. Some applications may need to initialize data, connect to external services or perform some other functions before they are ready to handle incoming traffic. For example, an API may need to connect to an external database system before it can handle incoming requests. If it is unable to connect to the external database it makes no sense to restart the container as that would not fix the issue. It would also not be ideal to direct any traffic to this container until it is able to establish connection with the external database. The best course of action would be to let the container run and give it some time to establish connections with its external dependencie. The readiness probe is used to provide this functionality of letting the container run and perform successfull initialization before handling any requests.

# Configuring Health Probes

Proper configuration of health probes is key to their effectiveness.Kubernetes offers several ways to define probes, with parameters that can be tuned to match the specific needs of your application. Each of the above probe types supports different methods of checking the container's state, like HTTP requests (httpGet), TCP socket (tcpSocket), gRPC endpoint, or executing a command inside the container (exec). Additionally, we can configure parameters like initialDelaySeconds, periodSeconds, timeoutSeconds, successThreshold, and failureThreshold based on the application's characteristics and requirements. 

The choice of probe and its configuration can significantly impact the stability and performance of the application. For instance, overly aggressive liveness probes can lead to frequent restarts, while lenient readiness probes might allow traffic to pods that aren't ready, resulting in poor user experience.

Let us take a look at configuring health probes in detail.

## Health Probe Mechanisms

Health probes can be implemented in a container using different mechanisms to check the containers state. Some of them are 

- Container Execution checks : This can be used to run a command or a script to check the health of the container.  This can be done by executing a command inside the container and checking the return code of the command. The container is restarted when the command returns a failure status code. 

- TCP Socket checks : This can be used to determine if a socket connection can be successfully established. This is done by establishing a TCP socket connection to a container on the port specified in the configuration. 

- HTTP checks : This can be used to verify if HTTP get requests succeed. If the container exposes an HTTP endpoint this probe can be used to perform a HTTP get request against this endpoint. If the get request fails appropriate actions can be taken.

- gRPC checks : This can be used to verify if gRPC requests succeed. This health check is natively available starting from Kubernetes version 1.25.


## Health probe parameters

Health probe mechanisms provide parameters which allows us to define the probes success criteria and the frequency at which the probes are run. These parameters allow us to fine-tune and optimise health probe execution. These parameters are

- ```initialDelaySeconds``` : Defines the delay in seconds from the time the container starts to the first time the probe is executed. The default value is zero seconds.

- ```periodSeconds``` : Defines the frequency in seconds at which the probe will be executed after the initial delay. The default value is 10 seconds.

- ```timeoutSeconds``` : Defines the wait time in seconds before a probe is marked as failed. The default value is one second.

- ```failureThreshold``` : Defines the number of times a probe should be retried after a failure. The container will be restarted after this threshold is reached. The default value is three.

# Defining health probes

Let us now look at defining health probes using liveness probes as an example.

## httpGet handler

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/liveness:0.1
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20
      timeoutSeconds: 5
      successThreshold: 1
      failureThreshold: 3
```

This configuration defines a probe that sends an HTTP GET request to the /health endpoint on port 8080 within the container every 20 seconds, with a 5-second timeout. This endpoint should be configured to perform checks that confirm the application is functioning properly, and return an HTTP status code based on the outcome (typically, HTTP 200 for healthy). The ```initialDelaySeconds: 15``` sets a delay of 15 seconds from when the container starts to the first execution of the probe. This delay allows your application sufficient time to start up before the health checks begin. The probe considers the container healthy if it receives a successful response at least once in a three-attempt window as set by the ```successThreshold: 1``` parameter. If the probe fails the specified threshold, Kubernetes restarts the container. This means that the container will be restarted by Kubernetes if the probe fails 3 times in a row as set by the ```failureThreshold: 3``` parameter.

## execAction handler

This handler executes a user defined command to check the health of a container.

```apiVersion: v1
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/liveness:0.1
    ports:
    - containerPort: 8080
    livenessProbe:
      exec:
        command:
        - cat
        - /usr/share/liveness/html/index.html
      initialDelaySeconds: 5
      periodSeconds: 5
```

This liveness probe checks if the file /usr/share/liveness/html/index.html exists and is readable. If the file exists and is readable, the container is considered healthy. If the cat command is unable to read the file successfully, it will also be considered an error, leading to the container restart. 

##  TCPSocketAction handler

We can use a TCP connection check to setup the liveness health probe as below.

```
apiVersion: v1
kind: Pod
metadata:
  name: liveness
  labels:
    app: liveness-tcp
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/liveness:0.1
    ports:
    - containerPort: 8080
    livenessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

This liveness probe uses a TCP socket to check the container's health. It attempts to establish a TCP connection at port 8080 to verify the container's health. If the probe cannot establish a connection, Kubernetes interprets this as the container being unhealthy and will take appropriate actions, like restarting the container.

## gRPC handler

Starting with kubernetes 1.24, gRPC probes became available as a built-in feature. gRPC probes can be defined as below.

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-gRPC
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/liveness:0.1
    ports:
    - containerPort: 2379
    livenessProbe:
      grpc:
        port: 2379
      initialDelaySeconds: 5
      periodSeconds: 5
```
The probe will connect to the service using the gRPC protocol on port 2379 and consider the container unhealthy if the connection fails.

# Health Probe Optimizations


- Probe Effectiveness: The choice of probe and its configuration can significantly impact the stability and performance of the application. For instance, overly aggressive liveness probes can lead to frequent restarts, while lenient readiness probes might allow traffic to pods that aren't ready, resulting in poor user experience.

- Thresholds and Delays: Setting appropriate thresholds and delays is crucial. High failureThreshold values can prevent unnecessary pod restarts, while reasonable initialDelaySeconds can give applications enough time to start up before the probes begin.

- Monitoring and Logging: Keeping an eye on the probe activity can aid in troubleshooting and performance tuning. Kubernetes provides logs and metrics that can be used to monitor the health probe activity and tweak them for optimal performance.

# Sequence of health probes

This diagram effectively illustrates the workflow of Kubernetes health probes and their impact on a container's lifecycle.

{{< mermaid >}}

flowchart LR
    A[0 - Start] -->|Deployment| B{Startup Probe}
    B -->|Success| C{Readiness Probe}
    B -->|Fail| D[Restart Container]
    C -->|Success| E{Liveness Probe}
    C -->|Fail| F[Stop Traffic]
    F -->|Failures Below Threshold| C
    F -->|Failures Exceed Threshold| D
    E -->|Success| E
    E -->|Fail| D
    D -->|Retry Startup Probe| B
{{< /mermaid >}}


The process begins with the deployment of the container in Kubernetes. After the container starts, the startup probe checks if the application within the container is ready to run. If the startup probe succeeds, it proceeds to the readiness probe. If the startup probe fails, Kubernetes restarts the container.

When the startup probe is successful, the readiness probe is executed. This probe determines if the container is ready to serve traffic. If the readiness probe is successful, Kubernetes initiates the liveness probe to continually monitor the container's health. If the readiness probe fails, traffic to the container is stopped. Kubernetes will retry the readiness probe until it succeeds or the failure threshold is exceeded. If the failure threshold is exceeded, Kubernetes restarts the container.

Once the startup probe and the readiness probes are successful, Kubernetes continuously checks the health of the container during its runtime. If the liveness probe is successful, it will continue to monitor at defined intervals. If the liveness probe fails, Kubernetes will restart the container. After restarting the container, the process begins again with the startup probe.

# Conclusion

In summary, health checks in Kubernetes enable applications to be more resilient by allowing for self-healing, efficient traffic management, and handling of diverse operational scenarios. They form a critical part of the automated orchestration that Kubernetes provides, ensuring that applications are not just deployed but are consistently available and reliable.