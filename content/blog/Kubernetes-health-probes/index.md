---
title: "Kubernetes Health Probes"
author: "Pradeep Loganathan"
date: 2023-10-25T14:33:30+10:00

draft: true
comments: true
toc: true
showToc: true
TOCOpen: true

description: ""

cover:
    image: "cover.png"
    relative: true

images:


tags:
  - "post"
---

As a container orchestration system it is critical for Kubernetes to know and keep track of the health of its various components. This allows kuberenetes to replace unhealthy pods/containers and know which ones to route traffic to. This is critical to implement high availability and resiliency. Kubernetes probes are used to monitor the health of kubernetes applications, containers or pods running in a cluster. These diagnostic tests are performed periodically by the kubelet. These probes are a critical part of the platform and are used by the Kubernetes control plane to detect changes in the application and take the appropriate corrective action. 

## Probe Types

Kubernetes has three types of container health checks or probes

### Startup probe

A startup probe is used to identify if a container has started. If the startup probe fails the container is killed and the restartPolicy for the container is implemented. Startup probes run before any other probes. When a startup probe is configured the readiness and liveness probes are disabled until it is successful.  It is important to implement the startup probe in conjunction with the liveness and the readiness probes to prevent the possibility of these probes running before the container indicates that it has started up. The startup probe is configured using the ```spec.containers.startupprobe``` attribute of the pod configuration

### Liveness probe

A liveness probe is used to identify if a container is in an healthy state. If a liveness health check fails the kubernetes control plane will kill the container and restart it according to the configured ```restartPolicy```.  This is especially useful in cases where the pod may be running but the application itself may not be functioning properly. The startup probe is configured using the ```spec.containers.livenessprobe``` attribute of the pod configuration

### Readiness probe

A readiness probe is used to identify if a container is ready to recieve traffic. This probe is used to ensure that a container is fully up and running and can serve incoming connection requests. The readiness probe is executed periodically. This may seem redundant given that we have a startup probe. However, a lot of applications may need to perform additional initialization tasks post startup before they are ready to handle any incoming traffic. Some applications may need to initialize data, connect to external services or perform some other functions before they are ready to handle incoming traffic. For example, an API may need to connect to an external database system before it can handle incoming requests. If it is unable to connect to the external database it makes no sense to restart the container as that would not fix the issue. It would also not be ideal to direct any traffic to this container until it is able to establish connection with the external database. The best course of action would be to let the container run and give it some time to establish connections with its external dependencie. The readiness probe is used to provide this functionality of letting the container run and perform successfull initialization before handling any requests.

## Health probe mechanisms

Health probes can be implemented in a container using the below mechanisms 

- Container Execution checks : This can be used to run a command or a script to check the container.  A probe can execute a command inside the container and check the returned status. The container is restarted when a the command returns a failed status code. 

- TCP Socket checks : This can be used to determine if a socket connection can be succesfully established. This is done by establishing a TCP socket connection to a container on the port specified in the configuration. 

- HTTP checks : This can be used to verify if HTTP get requests succeed. If the container exposes an HTTP endpoint this probe can be used to perform a HTTP get request against this endpoint. If the get request fails appropriate actions can be taken.

- gRPC checks : This can be used to verify if gRPC requests succeed. This health check is natively available starting from Kubernetes version 1.25.


## Health probe parameters

The above health probe mechanisms provide parameters which allows us to define the probes success criteria and the frequency at which the probes are run. These parameters are

- ```initialDelaySeconds``` : Defines the delay in seconds from the time the container starts to the first time the probe is executed. The default value is zero seconds.

- ```periodSeconds``` : Defines the frequency in seconds at which the probe will be executed after the initial delay. The default value is 10 seconds.

- ```timeoutSeconds``` : Defines the wait time in seconds before a probe is marked as failed. The default value is one second.

- ```failureThreshold``` : Defines the number of times a probe should be retried after a failure. The container will be restarted after this threshold is reached. The default value us three.

# Defining a liveness probe

## execAction handler

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

##  TCPSocketAction handler

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

## HTTPGetAction handler

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
        httpHeaders:
        - name: Custom-Header
          value: ItsAlive
      initialDelaySeconds: 5
      periodSeconds: 5
```

## gRPC handler

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

# Defining a startup probe

#