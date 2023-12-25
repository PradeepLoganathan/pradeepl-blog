---
title: "Azure Event Grid - Creating a Topic"
author: "Pradeep Loganathan"
date: 2022-06-23T12:25:09+10:00
draft: false
comments: true
toc: true
showToc: true
TocOpen: false
categories: 
  - "azure"
tags: 
  - Azure
  - Eventdriven
categories: 
  - "azure"
summary: "Azure Event Grid is an eventing back plane that enables event-driven and reactive programming. In this blog post series we will understand Azure Event Grid and look at developing an event driven application using Azure Event Grid as the backplane"
cover:
    image: "images/azure-event-grid-createtopic.png"
    alt: "Azure Event Grid - Introduction"
    caption: "Azure Event Grid - Introduction"
    relative: false # To use relative path for cover image, used in hugo Page-bundles
---

This post is part of a three post series on Azure Event Grid

[Part 1 - Azure Event Grid - Introduction]({{< ref "/blog/azure/azureeventgrid-introduction" >}})

[Part 2 - Azure Event Grid - Create Topics]({{< ref "/blog/azure/azureeventgrid-createtopic" >}})

[Part 3 - Azure Event Grid - Creating Custom events]({{< ref "/blog/azure/azureeventgrid-createcustomevents" >}})

To get started with Azure Event grid we need to create three primary elements as described previously. We need to create a Topic, a subscription and an Event handler .

**_Creating the Topic -_** On Azure portal use the create resource option to create an Event Grid topic as shown below. I have created a topic and named it as CandidateTopic. I have specified the resource group , the location and the event schema.

![Event Grid - Creating a topic](images/Topic-creating.png)

**_Creating the Subscription -_** The topic is now created but as you can see below the topic needs a subscription in order for it to deliver events.

![Azure Event Grid - Topic Created - No Endpoint](images/Topic-Created-No-Endpoint.png)

**_Creating the Handler -_** I have created a subscription and have used a Web hook as the handler for the subscription as seen below. The web hook is a custom API that i created to be called by the subscription.

![](images/Create-Subscription-1-1024x475.png)

![Azure Event Grid - Topic Created](images/TopicCreated.png)

Azure Event Grid - Topic Created