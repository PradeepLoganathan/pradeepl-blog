---
title: "Creating a Tekton Build Pipeline"
author: "Pradeep Loganathan"
date: 2022-04-11T23:40:28+10:00

draft: true
comments: true
toc: true
showToc: true

description: ""

cover:
    image: "cover.png"
    relative: true

images:

mermaid: true

tags:
  - "post"
---

## Install Tekton Components

Tekton can be installed on any kubernetes cluster version 1.15 or higher. For this blog post, I am deploying tekton on an Azure Kubernetes cluster with version 1.21.9. We can deploy the pipeline, trigger and the interceptor components as below. I strongly advise to run a ``` kubectl get pods --namespace tekton-pipelines --watch``` command to see the status of the pods after installing each component. Ensure that the pods are running before installing the next set of components.

```shell
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
```

## Install Tekton Dashboard

The Tekton dashboard is a web application that can be used to monitor the status of the pipeline. The dashboard is installed as a service.  To access the dashboard we need to perform port forward the container port 9097 of the service.

```shell
kubectl apply --filename https://github.com/tektoncd/dashboard/releases/latest/download/tekton-dashboard-release.yaml

kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
```

## Install Tekton CLI

The Tekton CLI makes it easier to interact with Tekton pipelines. It is available as a binary package on the Tekton releases page. On linux it can be installed as below

```shell
curl -LO https://github.com/tektoncd/cli/releases/download/v0.23.1/tkn_0.23.1_Linux_x86_64.tar.gz
sudo tar xvzf tkn_0.23.1_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn
```

Once installed, the Tekton CLI can be used to check the version of installed components using the ```tkn version``` command. I get the below versions after installing the components.

```shell
Client version: 0.23.1
Pipeline version: v0.34.1
Triggers version: v0.19.1
Dashboard version: v0.25.0
```

## Pipeline

dfgdfgfdgdfg

{{< mermaid >}}

flowchart  LR
A(Checkout) ---> B(Build)
B ---> C{Test}
C --Tests pass--> D(Containerize)
C --Tests Fail--> E(Report Failure)
D ---> F(Deploy)
{{< /mermaid >}}

dfgdfgdfgfd

## Checkout Task
