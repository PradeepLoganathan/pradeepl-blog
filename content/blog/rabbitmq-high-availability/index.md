---
title: "High Availability with RabbitMQ "
author: "Pradeep Loganathan"
date: 2022-03-04T08:41:50+10:00

draft: true
comments: true
toc: true
showToc: true

description: ""

cover:
    image: "cover.png"
    relative: true

images:


tags:
  - "post"
---

RabbitMQ is an open-source messaging middleware system. It is used for message routing, message queuing, and message persistence. It is a highly available system that is designed to be highly scalable and fault-tolerant.

## Clustering

Clustering allows multiple RabbitMQ instances to be configured to work as a single logical unit in the form of a clustered message broker. RabbitMQ clusters are a set of nodes that are configured to run in a highly available manner. Each node is a member of the cluster. The nodes in the cluster communicate with each other to exchange state information. In a RabbitMQ cluster, run time state information about exchanges, queues, users, bindings, etc is available cluster-wide to all nodes. The cluster is highly configurable. It can be configured to run a single-node configuration or a cluster of nodes. The cluster is highly scalable and can scale to hundreds of nodes. It allows to linearly scale throughput by adding more nodes. The cluster is also highly fault-tolerant. RabbitMQ clusters are designed to allow consumers and producers to continue functioning even if one or multiple nodes fail. If a node fails, the cluster will automatically elect a new leader and the cluster will continue to function. Queues in a cluster can span multiple nodes and synchronize state across nodes. If a node fails, the queue instance on the other nodes will continue to function and contain messages and queue state. When the failed node is healed and rejoins the cluster it will be fully synchronized with the other nodes to update it to the latest state of the cluster.

While clusters are great for achieving high availability and fault tolerance they are designed for low latency networks. State synchronization is a costly operation and is not recommended to use clusters in high-latency networks or over a WAN/internet. In cloud environments such as AWS, Azure and GCP, RabbitMQ Clusters can be deployed to an availability zone but ideally not across availability zones. However, solutions such as Shovel and Federation can be used to synchronize queues in high-latency environments. Another important consideration is the size of the cluster. Each node in the cluster must know about every other node in the cluster. Synchronizing state across nodes can be expensive. If the cluster is too large, it can lead to a significant increase in the amount of data that needs to be synchronized.

There are some prerequisites for creating RabbitMQ clusters.

* All nodes in the cluster must be running the same version of RabbitMQ and Erlang.

* All the nodes in the cluster must have the same Erlang cookie.

* Peer discovery must be enabled on all nodes in the cluster.

## HA Queue Setup

When a RabbitMQ cluster is setup it [replicates all information necessary to run the cluster](https://www.rabbitmq.com/clustering.html#overview-what-is-replicated). This includes the cluster configuration, cluster membership, and all the queues, exchanges, and bindings. However, it does not replicate the messages in the queues. This is because the messages are stored in the message broker and not in the cluster. This means that the messages are not replicated across the cluster. This is a trade-off between the cost of replication and the cost of storing messages. In the event of a node failure the cluster continues to operate. Clients can connect to a different node, declare queues and continue to send and receive messages from that point in time. However, the messages in the original node will be lost. Additional protection is provided using quorum queues and mirrored queues.

## Quorum Queues