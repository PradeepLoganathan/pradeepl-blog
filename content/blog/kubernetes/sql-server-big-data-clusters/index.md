---
title: "Sql Server Big Data Clusters"
author: "Pradeep Loganathan"
date: 2022-02-11T11:38:18+10:00

draft: true
comments: true
toc: true
showToc: true

description: ""

cover:
    image: "/images/hohyeong-lee-e0uCDHd19U4-unsplash.jpg"
    relative: true

images:


tags:
  - "sqlserver"
  - "bigdata"
  - "sqlserver2019"
  - "hdinsight"
---

SQl Server Big Data Clusters were introduced in SQL Server 2019 (Version 15.x). They are a great way to scale your data processing workloads by deploying them to a kubernetes cluster. In the previous post we have seen how to deploy SQL Server 2019 on a kubernetes cluster and create an Always on Availability group. SQl Server Big Data Clusters take that concept a lot further by providing a complete SKU that can only be deployed on a Kubernetes cluster. Big Data Clusters provide a feature set consisting of Data virtualization, Managed SQL Server, Spark, Data Lake and an AI/ML platform running in a Kubernetes environment. SQL Server Big Data Cluster components are deployed in containers to create a consistent, scalable, elastic environment. Kubernetes is used to manage and orchestrate these containers. Big data Clusters use Kubernetes native functionality to provide scalability, fault tolerance and performance. This also allows Big data clusters to be deployed on any Kubernetes platform such as [VMware Tanzu](https://tanzu.vmware.com/tanzu), AWS, Azure or GCP.

 In this post we will deploy SQL Server Big Data Clusters on a kubernetes cluster.

## Logical Architecture

A Big data cluster is composed of four logical layers. The control plane provides the management and security components for the cluster. The compute pool provides computational resources for the cluster. The storage pool provides storage resources for the cluster. The data pool provides data persistence for the cluster.

### Control Plane

### Compute Pool

### Data Pool

### Storage Pool


