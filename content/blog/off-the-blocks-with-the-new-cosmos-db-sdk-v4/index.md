---
title: "Off the blocks with the new Cosmos Db SDK V4"
date: "2020-11-02"
categories: 
  - "azure"
  - "cloud"
  - "cosmosdb"
tags: 
  - "comosdb"
---

### Creating Cosmos Db Infrastructure

The azure Cosmos DB team provides SQL API SDK's for various languages. At the time of writing this post the NuGet package for .NET core is at version 4 preview 3. The GitHub repo for this NuGet package is [here](https://github.com/Azure/azure-cosmos-dotnet-v3/blob/v4/changelog.md). To get started we can use the Cosmo Db emulator locally or create a Cosmos Account on Azure. We can log onto Azure portal to create a Cosmos Account or use Azure CLI. I am using the below Azure CLI command to create a Cosmos DB account. This command creates a Cosmos DB Account named eCommerceDb-AC in the eCommerce-RG resource group.

<script src="https://gist.github.com/PradeepLoganathan/ca2ec12683ac79e584591d21bed94200.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/ca2ec12683ac79e584591d21bed94200">View this gist on GitHub</a>

Create Cosmos Db Account

Creating a Cosmos Db account also provisions an endpoint URI with both read only and read-write keys needed to connect to the account. We can get the keys for the account create above using the below cli command

![](images/Cosmos-Keys-1024x201.png)

Retrieve Cosmos Db Keys

Now that we have provisioned the Cosmos Db account and have the necessary keys to connect we have all the prerequisites needed to get started with the code solution.

### CosmosClient

We start off by creating a console application. We can now install the NuGet package using the below command.

```
dotnet add package Azure.Cosmos --version 4.0.0-preview3
```

This NuGet package provides the CosmosClient object which is used to connect to Cosmos DB. The CosmosClient object manages connections to Cosmos Db in an efficient way and is thread safe. It is ideal to create an instance of the CosmosClient object as a singleton. The CosmosClient object allows further configuration of the connection through the CosmosClientOptions parameter. In the below code sample, I am configuring a CosmosClient object to connect to a Cosmos DB by specifying the endpoint, the primary key, and a host of other options.

<script src="https://gist.github.com/PradeepLoganathan/b65bd38eeb9bd1dc622d8fa075f9437e.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/b65bd38eeb9bd1dc622d8fa075f9437e">View this gist on GitHub</a>

The CosmosClient class can also be created using a fluent api provided by the CosmosClientBuilder class.

<script src="https://gist.github.com/PradeepLoganathan/c3ec4ca0a1f739cd9438d131fc57de7c.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/c3ec4ca0a1f739cd9438d131fc57de7c">View this gist on GitHub</a>

### Creating a Cosmos Db Database

Now that we can establish a connection using the CosmosClient instance, we can check and create the database using the CreateDatabaseIfNotExistAsync method as below.

<script src="https://gist.github.com/PradeepLoganathan/b2b4a17a6c4c7edcb2fa7abf970f9590.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/b2b4a17a6c4c7edcb2fa7abf970f9590">View this gist on GitHub</a>

### Creating a Container

A Cosmos DB container is a collection of items. The primary decision that needs to be made when creating a container is selecting a partition key. The partition key plays a crucial role in defining the performance characteristics as well as determining the RU usage. We can use the CreateContainerIfNotExistAsync method to check and create the container.

<script src="https://gist.github.com/PradeepLoganathan/3ce63e71aa9e148f08e02994a62bdfb6.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/3ce63e71aa9e148f08e02994a62bdfb6">View this gist on GitHub</a>

The container can also be created using the Fluent API surface as below

<script src="https://gist.github.com/PradeepLoganathan/34ac10abe6d2be9ee463cafb131b483e.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/34ac10abe6d2be9ee463cafb131b483e">View this gist on GitHub</a>

### Inserting Documents

Now that we have created a Cosmos DB account, a database, and a container we can insert documents into the container. To insert a document, we use the CreateItemAsync method, passing it the json object and the partition key. In the below gist I am adding a Customer object and a collection of Order objects to the same container. The objects are deserialized and inserted as json documents into the Cosmos DB container.

<script src="https://gist.github.com/PradeepLoganathan/3817b6b59d6b299c3e3d1bf36d333db2.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/3817b6b59d6b299c3e3d1bf36d333db2">View this gist on GitHub</a>

Inserting two different types into a container

### Querying Documents

There are two primary ways to query documents in Cosmos Db using the SQL API namely Point reads and SQL Queries.

- Point Reads -Point reads are used to do a key value lookup of a single item using its Identifier and partition key. Point reads do not use the query engine. They are faster and cheaper to perform.
- SQL Query - To query documents with complex search criteria we can use SQL Queries. SQL queries use the query engine. They are more expensive and have higher & variable latency depending on the SQL query.

The below query uses point read to read an item using an Id and partition key.

<script src="https://gist.github.com/PradeepLoganathan/1ad89b44de7adc7e92f98bb401e33085.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/1ad89b44de7adc7e92f98bb401e33085">View this gist on GitHub</a>

Querying for an Item using an ID and Partition Key

The below code uses a SQL query. It creates a query definition to construct a query with specific parameters to filter and sort the result as below.

<script src="https://gist.github.com/PradeepLoganathan/22cee392729ad67a9245f72d5a25bc3e.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/22cee392729ad67a9245f72d5a25bc3e">View this gist on GitHub</a>

We can also use a combination of point reads and custom SQL queries to construct rich and powerful query functionality.

### Deleting Documents

The SDK provides the DeleteItemAsync method to enable deleting documents from a container. This method takes the document identifier and the partition to locate and delete the document.

<script src="https://gist.github.com/PradeepLoganathan/6551ed7037db8b9dba87accff7834dc4.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/6551ed7037db8b9dba87accff7834dc4">View this gist on GitHub</a>

### Updating Documents

There are two strategies to update documents in Cosmos Db. The first one is to replace the document using the ReplaceItemAsync method. This method replaces the document with the item identifier if it exists and fails if it does not. The second option is to use UpsertitemAsync which updates the document if it exists or creates a new document if it does not exist.

### Bulk Operations

Bulk operations refers to operations which require a high degree of throughput, for e.g., inserting a large batch of documents. Bulk operations have been simplified extensively in V4 of the SDK. To perform bulk operations, we need to create a list of tasks representing actions in the batch and execute them concurrently against the container.

<script src="https://gist.github.com/PradeepLoganathan/3c7f9452eb3b8aa9c38c324b9650db3f.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/3c7f9452eb3b8aa9c38c324b9650db3f">View this gist on GitHub</a>

Cosmos Db - Bulk Operations

The above code executes a bulk operation to insert orders into the Orders container. The code makes it look like we are executing a list of threads running the CreateItemStreamAsync concurrently, However the Cosmos SDK does a lot more work in the background to enable and optimize bulk operations. The SDK creates batches in the background and allocates concurrent operations to these batches grouped by the partition key. Multiple batches are created and dispatched concurrently. A batch is dispatched based on a timer or if the batch is full. The timer ensures that even if batch is not full it can be dispatched. The maximum size for a batch is 100 operations per batch or 2 MB and the timer ensures that a batch is dispatched at 1 second.

We now have a fully functioning console application connecting to a Cosmos DB instance to perform CRUD operations on documents. This is a quick sample to demonstrate using the SQL API on Cosmos DB and does not have any production optimizations or best practices. Use at your own discretion.

> Photo by [Benjamin Voros](https://unsplash.com/@vorosbenisop?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/s/photos/cosmos?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
