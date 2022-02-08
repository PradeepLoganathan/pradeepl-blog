---
title: "Deploying Sql Server Always On Availability Group on Kubernetes"
lastmod: 2022-01-31T11:00:08+10:00
date: 2022-01-31T11:00:08+10:00
draft: true
Author: Pradeep Loganathan
tags: 
  - sqlserver
  - Kubernetes
  - "high availability"
  - "disaster recovery"
categories:
  - Kubernetes
#slug: kubernetes/introduction-to-kubernetes-admission-controllers/
summary: In this post we will deploy MS Sql Server in a kubernetes cluster. We will then configure it as an always on availability group.
ShowToc: true
TocOpen: false
images:
  - Shaniwar-wada.png
cover:
    image: "Shaniwar-wada.png"
    alt: "Deploying Sql Server on Kubernetes for High Availability and Disaster Recovery"
    caption: "Deploying Sql Server on Kubernetes for High Availability and Disaster Recovery"
    relative: false # To use relative path for cover image, used in hugo Page-bundles
editPost:
  URL: "https://github.com/PradeepLoganathan/pradeepl-blog/tree/master/content"
  Text: "Edit this post on github" # edit text
  appendFilePath: true # to append file path to Edit link
---
## Always On Availability Group

SQL Server Always On Availability Groups provide a flexible option for achieving high availability and fault tolerance at the database level. It provides options to recover from disasters and allows for greater access to data. Before SQL Server 2017, an Always On Availability Group required Windows Server Failover Clustering (WSFC) when running on Windows and Pacemaker/Corosync when running on Linux. WSFC and Pacemaker are cluster managers which provide HA capabilities to the cluster where SQL server is deployed. On Windows clusters, WSFC monitors applications and resources. It automatically identifies and recovers from failure conditions. This capability provides great flexibility in managing the workload within a cluster and improves the overall availability of the system. WSFC has specific hardware and software compatibility requirements. Pacemaker and corosync are the most widely used clustering solution on Linux clusters. Corosync is responsible for messaging between nodes and ensuring a consistent cluster state. Pacemaker is responsible for managing the resources on top of this cluster state. This is a highly scalable solution for high availability and disaster recovery.

However, all of this complexity is unnecessary when the architecture demands read scale workloads. In read scale workloads, the availability of the database is not a primary concern. This enables us to not worry about the cluster failover and other requirements for HA and DR. Read-Scale-Out utilizes the additional capacity of read-only replicas instead of sharing the read-write or primary replica. This ensures that read-only workloads like reports, long-running queries, API queries etc, are isolated from the main read-write workload.

SQL Server 2017 introduced Read Scale Availability groups which can be deployed without the need for a cluster manager. This architecture provides read-scale only. It doesn’t provide high availability. However, read-only Availability Groups can even be configured for containerized SQL, with Kubernetes using SQL Server 2019. A Read Scale AG consists of one or more databases that are replicated to one or more SQL Servers and are a unit of failover. The SQL Server where transactions originate is called a primary replica. A SQL Server receiving changes is called a secondary replica. The primary replica is the one that is used to store read/write data. The secondary replica is used to provide read-only access to the data. The primary replica is also used to store logs and other system data. Failover from a primary server to a secondary server can be performed manually when required.A Read-Only AG can be used to load-balance read workloads, for maintenance jobs such as backups, and consistency checks on the secondary databases.
SQL Server will capture transaction log changes on a Primary and transmit them over a separate communication channel (called a database mirroring endpoint) to the Secondary replica. On the Secondary replica, the changes are first hardened to the local transaction log and then separately any necessary redo recovery operations are applied.
## Synchronization Options

Availability Groups offer two synchronization options to synchronize the secondary replicas with the primary replica.

1. Synchronous Commit mode : In Synchronous commit mode, a transaction on the primary replica will wait for the transaction to commit on the primary and for log records associated with the transaction to be hardened on the secondary replica.

2. Asynchronous Commit mode : In Asyncronous commit mode, a transaction on the primary replica will only wait for the transaction to be commited on the primary. It does not wait for transactions to be hardened on the secondary replica.
