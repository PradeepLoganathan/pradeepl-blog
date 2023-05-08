---
title: "Data Engineering With Lambda Architecture"
author: "Pradeep Loganathan"
date: 2023-05-08T12:12:40+10:00

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




Lambda architecture is a data processing architecture designed to handle large amounts of data by combining batch processing with real-time stream processing. It was introduced by Nathan Marz in 2015, and it has since become a popular approach in big data processing. Lambda architecture provides a way to handle both real-time and batch processing in a single architecture. It allows for efficient processing of large amounts of data, as well as the ability to handle real-time data streams. However, it also adds complexity to the data processing pipeline and requires additional tools and technologies to manage. The key idea behind Lambda architecture is to split the data processing into two different paths: a batch layer and a speed layer. It also includes a serving layer which makes the processed data available to end users. 

The batch layer is responsible for processing large volumes of data in batches and computing pre-aggregated batch views. This layer is designed to handle the entire data set, including historical and incremental data, and to provide a complete and accurate view of the data. The batch layer is slow but accurate, and it provides a reliable and consistent view of the data that can be used as a baseline for comparison with real-time data. The batch layer stores all the data in a distributed file system, such as Hadoop HDFS, and processes it using batch processing technologies such as Apache Spark or Apache Flink. The batch layer is responsible for precomputing batch views, which are essentially summaries of the data that can be queried efficiently.

The speed layer processes incoming data in real-time using stream processing technologies such as Apache Kafka or Apache Storm. The speed layer is responsible for computing real-time views, which are essentially incremental updates to the batch views. The speed layer is responsible for processing real-time data and computing real-time views. This layer is designed to handle data as it arrives, providing low-latency responses to queries and allowing for real-time decision-making. The speed layer is fast but may not be as accurate as the batch layer, as it only considers a portion of the data.

The serving layer combines the results from both the batch and speed layers and makes them available to end-users through query APIs. The serving layer is responsible for querying and serving the batch views and the real-time views to the end-users. The serving layer is responsible for serving pre-computed batch views and real-time views to end-users. This layer is designed to provide a unified view of the data, combining the accuracy of the batch layer with the low latency of the speed layer. The serving layer is where end-users can query the data, visualize it, and make informed decisions based on it.

By separating the processing of data into these three layers, Lambda architecture provides a way to handle both real-time and batch data processing, while providing accurate and low-latency views of the data. The batch layer provides accuracy and completeness, while the speed layer provides low-latency processing of real-time data. The serving layer provides a unified view of the data that combines the accuracy of the batch layer with the low latency of the speed layer.

## Batch Layer

The batch layer is one of the three main layers of the Lambda architecture. It is responsible for processing and analyzing large volumes of historical data in batches. The batch layer is typically used to provide pre-computed views and insights over a large dataset, and it is particularly useful for generating reports and performing complex analytics tasks.

Here are some key characteristics of the batch layer:

1. Data storage: The batch layer typically uses distributed file systems, such as Apache Hadoop HDFS or Amazon S3, to store large volumes of data. These systems provide fault tolerance and scalability, allowing the batch layer to handle massive amounts of data.

2. Batch processing: The batch layer processes data in batch mode, which means that data is collected over a period of time and then processed all at once. Batch processing is usually slower than real-time processing, but it allows for more complex computations and analysis over a larger dataset.

3. Computation: The batch layer uses distributed computing frameworks, such as Apache Spark, Apache Flink, or Apache Hadoop MapReduce, to process large volumes of data. These frameworks can be used to perform a wide range of operations, such as filtering, aggregating, and joining data.

4. Pre-computed views: The batch layer is typically used to generate pre-computed views over the data, such as daily, weekly, or monthly aggregations. These views are stored in a separate data store, such as Apache HBase or Apache Cassandra, and are used to support ad-hoc queries or real-time analytics.

5. Latency: The batch layer is not designed for real-time processing and may have higher latency compared to the speed layer. However, it provides a more comprehensive view of historical data and supports more complex analysis.

Overall, the batch layer is an essential component of the Lambda architecture, as it provides valuable insights into historical data and supports complex analytics tasks. It is particularly useful for generating pre-computed views that can be used to support real-time queries and analytics.

## Streaming Layer

The streaming layer is responsible for processing and analyzing real-time data streams in a continuous manner. The streaming layer is particularly useful for handling high-throughput, time-sensitive data streams, such as those generated by IoT devices, social media feeds, or financial transactions.

The key characteristics of the streaming layer are:

1. Data ingestion: The streaming layer ingests and processes real-time data streams in near real-time. This requires a messaging system, such as Apache Kafka, RabbitMQ, or Amazon Kinesis, to buffer and distribute incoming data streams.

2. Real-time processing: The streaming layer processes data in real-time, which means that it provides low latency and supports continuous analysis over a data stream. Streaming frameworks, such as Apache Flink, Apache Spark Streaming, or Apache Storm, can be used to process incoming data streams and provide real-time analytics.

3. Event-driven architecture: The streaming layer is based on an event-driven architecture, which means that it processes events as they occur. This allows for timely and context-aware processing of data streams.

4. Stateful processing: The streaming layer can maintain state over time, allowing for more complex processing and analysis of data streams. This requires the use of a stateful streaming framework, such as Apache Flink or Apache Samza, which can handle stateful computations over a data stream.

5. Fault tolerance: The streaming layer is designed to handle failures and ensure fault tolerance. Streaming frameworks typically provide mechanisms for fault tolerance, such as checkpointing and state replication, to ensure that data is not lost in case of failures.

Overall, the streaming layer provides real-time insights into data streams and supports timely and context-aware processing of data. It is particularly useful for handling high-throughput data streams and providing real-time analytics for applications that require low latency and continuous processing of data.

## Serving Layer

The serving layer is responsible for serving pre-computed views and insights over a large dataset, generated by the batch layer, as well as real-time views and insights generated by the speed layer. The serving layer is typically used to support ad-hoc queries, data exploration, and real-time analytics for end-users.

Here are some key characteristics of the serving layer:

1. Data storage: The serving layer typically uses a distributed database or key-value store, such as Apache Cassandra, Apache HBase, or Apache Accumulo, to store pre-computed views and insights generated by the batch layer, as well as real-time views and insights generated by the speed layer. These databases provide low-latency access to data, high availability, and scalability.

2. Query processing: The serving layer supports ad-hoc queries and data exploration over the pre-computed views and insights generated by the batch layer, as well as real-time views and insights generated by the speed layer. Query processing can be performed using SQL or NoSQL query languages, depending on the database used.

3. API layer: The serving layer typically includes an API layer that exposes the pre-computed views and insights to end-users, as well as real-time views and insights generated by the speed layer. This allows end-users to interact with the data and perform ad-hoc queries and analytics.

4. Caching: The serving layer may include a caching layer, such as Apache Ignite, Apache Geode, or Redis, to improve query performance and reduce latency. Caching can be used to store frequently accessed data in memory, reducing the number of queries that need to be performed against the database.

5. Load balancing: The serving layer may include a load balancing layer, such as Apache ZooKeeper or Consul, to distribute incoming queries and traffic across multiple nodes in the database cluster. This improves scalability and availability of the serving layer.

Overall, the serving layer provides low-latency access to pre-computed views and insights over a large dataset, as well as real-time views and insights generated by the speed layer. It supports ad-hoc queries, data exploration, and real-time analytics for end-users, and provides a scalable and fault-tolerant architecture for serving data to applications and users.