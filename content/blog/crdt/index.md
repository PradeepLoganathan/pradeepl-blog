---
title: "CRDT"
date: "2019-09-02"
categories: 
  - "architecture"
  - "patterns"
---

CRDT stands for conflict-free replicated datatype. CRDT describes data types that can be replicated across multiple computation units, updated concurrently without any coordination, and then merged to get a consistent state. It doesn’t matter in which order you execute operations on the data type or if you repeat operations: the result is eventually correct. CRDTs always have a merge function that can take many data entries living on different nodes and merge these automatically into one consistent view of the data, without any coordination between the nodes. The most important properties of the merge function are that it is symmetric and monotonic.

![](images/CRDT-walk-path.png)

CRDT Walk path

Lets go through a simple example of how CRDT's work by walking through all possibilities of a simple Order processing workflow. Initially, define all possible status values and their merge order, as shown in figure. A graphical representation is the easiest way to get started when designing a CRDT with a small number of values. The states are represented by the rounded rectangles and their merge order indicated by the state progression arrows. So an order can progress from New to cancelled, or from scheduled to cancelled or from Packing to Aborted.

Lets assume two nodes report differnt status. Now we need to merge the two status . When merging two statuses, there are three cases.

- If both statuses are the same, then obviously you just pick that status.
- If one of them is reachable from the other by walking in the direction of the arrows, then you pick the one toward which the arrows are pointing; as an example, merging “New” and “Packing” will result in “Packing.”
- If that is not the case, then you need to find a new status that is reachable from both by walking in the direction of the arrows, but you want to find the closest such status (otherwise, “Shipped” would always be a solution, but not a useful one). There is only one example in this graph, which is merging “Packing” and “Cancelled,” in which case you choose “Aborted”—choosing “Shipped” would technically be possible and consistent, but that choice would lose information (you want to retain both pieces of knowledge that are represented by “Packing” and “cancelled”).

> Photo by [NeONBRAND](https://unsplash.com/@neonbrand?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/conflict-free?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
