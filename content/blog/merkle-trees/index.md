---
title: "Merkle Trees"
date: "2017-07-12"
categories: 
  - "architecture"
  - "blockchain"
---

A Merkle tree, named for its inventor, Ralph Merkle, is also known as a “hash tree". It’s a data structure represented as a binary tree, and it’s useful because it summarizes in short form the data in a larger data set. In a hash tree, the leaves are the data blocks (typically files on a filesystem) to be summarized. Every parent node in the tree is a hash of its direct child node, which tightly compacts the summary.

The data structure used to detect if two trees are the same is called a hash tree or Merkle tree. Hash trees work by calculating the hash values of each leaf of a tree, and then using these hash values to create a node object. Node objects can then be hashed and result in a new hash value for the entire directory.

For more information on Merkle trees, check Ralph Merkle’s website at [_www.merkle.com_](http://www.merkle.com/).

Merkle Trees are used as an anti-entropy mechanism in several distributed, replicated key/value stores such as [DynamoDB](https://pradeeploganathan.com/cloud/aws/dynamodb-running-locally-using-docker/), Riak and Cassandra. Merkle trees are used in Cassandra to ensure that the peer-to-peer network of nodes receives data blocks unaltered and unharmed. The anti-entropy mechanism of Cassandra the data in a column-family is converted to a hash using the Merkle tree. The Merkle tree representations compare data between neighboring nodes. If there is a discrepancy, the nodes are reconciled and repaired. The Merkle tree is created as a snapshot during a major compaction operation.

A Merkle tree represents an interesting application of hash functions, as it represents a series of parallel-computed hashes that feed into a cryptographically strong resultant hash of the entire tree.

Corruption or integrity loss of any one of the hashes (or data elements that were hashed) provides an indication that integrity was lost at a given point in the Merkle tree.  A Merkle tree is a complete binary tree constructed from a set of secret leaf tokens where each internal node of the tree is a concatenation, then a hash of its left and right child. The leaves consist of a set of m randomly generated secret tokens. Since it is a complete binary tree, m = 2h where h is the height of the tree and m is the number of leaves. The root is public and is the result of recursive applications of the one-way hash function on the tree, starting at the leaves (Santhanam et al., 2008). Merkle trees offer low cost authentication for mesh clients.  Compared to public key, they are lightweight, quick to generate and are resistant to quantum attacks.  The strength of the Merkle tree authentication scheme rests on having a secure hash function and practical cryptographic hash functions do exist.  The purpose of a hash function is to produce a “fingerprint” of a message, that is, a hash function s() is applied to a file M and produces s(M), which identifies M, but is much smaller (Stamp, 2011).

<span class="mceItemHidden" data-mce-bogus="1"><span></span>&amp;amp;amp;amp;amp;amp;amp;amp;amp;lt;meta http-equiv="refresh" content="0; <span class="mceItemHidden" data-mce-bogus="1"><span class="hiddenSpellError" pre="" data-mce-bogus="1">url</span></span>=/library/no-js/"&amp;amp;amp;amp;amp;amp;amp;amp;lt;/p&amp;amp;amp;amp;amp;amp;amp;amp;gt;<br> &amp;amp;amp;amp;amp;amp;amp;amp;lt;p&amp;amp;amp;amp;amp;amp;amp;amp;gt;/&amp;amp;amp;amp;amp;amp;amp;amp;amp;gt;</span>

<table class="Figure_Table"><tbody><tr><td></td></tr></tbody></table>

![Figure978-1-5225-1829-7.ch007.f01](images/ch007.f01.png)

Merkle Tree as a Binary Tree
