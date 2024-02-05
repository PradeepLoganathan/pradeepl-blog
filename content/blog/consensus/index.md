---
title: "Consensus algorithms"
author: "Pradeep Loganathan"
date: "2017-07-12T14:06:19+10:00"
draft: false
Author: Pradeep Loganathan
categories: 
  - "architecture"
  - "blockchain"
  - "algorithms"
  - "consensus"
tags: 
  - "architecture"
  - "consensus algorithms"
  - "Raft"
  - "Paxos"
summary: Consensus is one of the most important and fundamental problems in distributed computing. Simply put, the goal of consensus is to get several nodes to agree on something. It is a distributed computing concept that is used to provide a means of agreeing to a single version of truth by all peers on the distributed network.
# description: Consensus is one of the most important and fundamental problems in distributed computing. Simply put, the goal of consensus is to get several nodes to agree on something. It is a distributed computing concept that is used to provide a means of agreeing to a single version of truth by all peers on the distributed network.
ShowToc: true
TocOpen: false

cover:
    image: "Consensus Algorithms - Cover.png"
    alt: "Consensus Algorithms"
    caption: "Consensus Algorithms"
    relative: true  # To use relative path for cover image, used in hugo Page-bundles
 
---

## Consensus algorithm

Consensus is one of the most important and fundamental problems in distributed computing. Simply put, the goal of consensus is to get several nodes to agree on something. In distributed systems, consensus forces participants in the system to agree on consistent values across and elect a leader. It is a distributed computing concept that is used to provide a means of agreeing to a single version of truth by all peers on the distributed network. Consensus protocols also implement measures to prevent issues with split brain and stale replicas. Reliably reaching consensus despite network faults and process failures is a surprisingly hard problem to solve.

For example, if several people concurrently try to book the last seat on an airplane, or the same seat in a theater, or try to register an account with the same username, then a consensus algorithm could be used to determine which one of these mutually incompatible operations should be the winner.

A consensus algorithm must satisfy the following properties

1. Uniform agreement - No two nodes decide differently.
2. Integrity - No node decides twice.
3. Validity - If a node decides value v, then v was proposed by some node.
4. Termination - Every node that does not crash eventually decides some value.

Some well-known consensus algorithms are Paxos and Raft. Both these algorithms deliver similar performances, but Raft is less complex and easier to understand. Consul and Etcd implement Raft while ZooKeeper implements Paxos as thier respective consensus managers.

In computer science, the term consensus can be defined as 'given a cluster of N nodes and a set of proposals P1 to Pm every nonfailing node will eventually decide on a single proposal Px without the possibility to revoke that decision. All nonfailing nodes will decide on the same Px.'

The following two categories of consensus mechanism exist:

1. Byzantine fault tolerance-based, which is a more traditional approach based on rounds of votes
2. Proof-based or leader-based consensus whereby a leader is elected and proposes a final value

## Practical Byzantine Fault Tolerance Consensus

Practical Byzantine Fault Tolerance (PBFT) achieves state machine replication, which provides tolerance against Byzantine nodes. Protocols, such as PBFT, PAXOS, RAFT, and Federated Byzantine Agreement (FBA), are used in many different implementations of distributed systems and blockchains.

## Proof Based Consensus

**PROOF OF WORK**  
This type of consensus mechanism relies on proof that enough computational resources have been spent before proposing a value for acceptance by the network. This is used in bitcoin and other cryptocurrencies. Currently, this is the only algorithm that has proven astonishingly successful against Sybil attacks.

**PROOF OF STAKE**  
This algorithm works on the idea that a node or user has enough stake in the system; for example the user has invested enough in the system so that any malicious attempt would outweigh the benefits of performing an attack on the system. This idea was first introduced by Peercoin and is going to be used in the Ethereum blockchain. Another important concept in Proof of Stake (PoS) is coin age, which is a derived from the amount of time and the number of coins that have not been spent. In this model, the chances of proposing and signing the next block increase with the coin age.

**DELEGATED PROOF OF STAKE**  
Delegated Proof of Stake (DPOS) is an innovation over standard PoS whereby each node that has stake in the system can delegate the validation of a transaction to other nodes by voting. This is used in the bitshares blockchain.

**PROOF OF ELAPSED TIME**  
Introduced by Intel, it uses Trusted Execution Environment (TEE) to provide randomness and safety in the leader election process via a guaranteed wait time. It requires the Intel SGX (Software Guard Extensions) processor to provide the security guarantee and for it to be secure.

**DEPOSIT-BASED CONSENSUS**  
Nodes that wish to participate on the network must put in a security deposit before they can propose a block.

**PROOF OF IMPORTANCE**
This idea is important and different from Proof of Stake. Proof of importance not only relies on how much stake a user has in the system, but it also monitors the usage and movement of tokens by the user to establish a level of trust and importance. This is used in Nemcoin.

**FEDERATED CONSENSUS OR FEDERATED BYZANTINE CONSENSUS** 
Used in the stellar consensus protocol, nodes in this protocol keep a group of publicly trusted peers and propagates only those transactions that have been validated by the majority of trusted nodes.

**REPUTATION-BASED MECHANISMS**  
As the name suggests, a leader is elected on the basis of the reputation it has built over time on the network. This can be based on the voting from other members.

### Paxos

Paxos ( Lamport, L. (2001). Paxos made simple, SIGACT News 32(4): 51–58 - http://lamport.azurewebsites.net/pubs/paxos-simple.pdf) is a fault tolerant, distributed consensus protocol published in 1989. It is a protocol for  determining consensus in a network of unreliable distributed processes. The algorithm also ensures we have a leader election whenever there is a server failure. Paxos is usually used where durability is required (e.g., to replicate a file or a database), in which the amount of durable state could be large.  
The Paxos algorithm is used extensively by Amazon web services to power its platform. It is also used by Google chubby lock service (http://labs.google.com/papers/chubby.html). Cassandra uses the Paxos consensus protocol to make sure the writes go linearly.

A Paxos node can take up one of three roles:

- Proposer: This is the node driving the consensus.
- Acceptor: These are nodes that independently accept or reject the proposal.
- Learner: Learners are not directly involved in the consensus building process; they learn of the accepted values from the Acceptor. Usually, Learners and Acceptors are packaged together in a single component.

In Paxos, followers send commands to a leader. During normal operation, the leader receives a client’s command, assigns it a new command number (n), and then begins the nth instance of the consensus algorithm by sending messages to a set of acceptor processes. A gossip protocol occurs when one node transmits information about the new instances to only some of their known colleagues, and if one of them already knows from other sources about the new node, the first node’s propagation is stopped. Thus, the information about the node is propagated in an efficient and rapid way through the network.

Paxos operates as a sequence of proposals, which may or may not be accepted by a majority of the processes in the system. If a proposal isn’t accepted, it fails. Each proposal has a sequence number, which imposes a strict ordering on all of the operations in the system.

In the standard Paxos algorithm, proposers send two types of messages to acceptors: Prepare and Accept. In the first phase of the protocol, the proposer sends a sequence number to the acceptors. Each acceptor will agree to accept the proposal only if it has not yet seen a proposal with a higher sequence number. Proposers can try again with a higher sequence number if necessary. Proposers must use unique sequence numbers (drawing from disjoint sets, or incorporating their hostname into the sequence number, for instance).  
If a proposer receives agreement from a majority of the acceptors, it can commit the proposal by sending a commit message with a value.  
The strict sequencing of proposals solves any problems relating to ordering of messages in the system. The requirement for a majority to commit means that two different values cannot be committed for the same proposal, because any two majorities will overlap in at least one node. Acceptors must write a journal on persistent storage whenever they agree to accept a proposal, because the acceptors need to honor these guarantees after restarting.

ElasticSearch Zendiscovery bug: https://github.com/elastic/elasticsearch/issues/2488

### RAFT

Raft is a consensus algorithm that allows distributed systems to keep a shared and managed state (https://raft.github.io/). A visualization of RAFT consensus algorithm is available at http://thesecretlivesofdata.com/raft . A basic cluster can be run on a single node/leader, but if you want redundancy, at least three nodes allows for a single node failure. A Raft cluster is made of nodes that must maintain a replicated state machine in a consistent manner, no matter what: new nodes can join, old nodes can crash or become unavailable, but this state machine must be kept in sync.In Raft, messages and logs are sent only by the cluster leader to its peers, making the algorithm more understandable and easier to implement.

### Consensus algorithms in Blockchain

Consensus is the basis for the underlying protocol governing a blockchain’s operation. A consensus algorithm is the nucleus of a blockchain representing the method or protocol that commits the transaction. It is important, because we need to trust these transactions.

The Proof-of-Work (POW) consensus method was initiated by Bitcoin and it can be regarded as the granddaddy of these algorithms. POW rests on the popular Practical Byzantine Fault Tolerant that allows transactions to be safely committed according to a given state. An alternative to POW for achieving consensus is Proof-of-Stake.

One of the drawbacks of the Proof-of-Work algorithm is that it is not environmentally friendly, because it requires large amounts of processing power from specialized machines that generate excessive energy. A strong contender to POW will be the Proof-of-Stake (POS) algorithm which relies on the concept of virtual mining and token-based voting, a process that does not require the intensity of computer processing as the POW, and one that promises to reach security in a more cost-effective manner.

Finally, when discussing consensus algorithm, you need to consider the “permissioning” method, which determines who gets to control and participate in the consensus process. The three popular choices for the type of permissioning are:

Public (e.g., POW, POS, Delegated POS)  
Private (uses secret keys to establish authority within a confined blockchain)  
Semi-private (e.g., consortium-based, uses traditional Byzantine Fault Tolerance in a federated manner)

PoA is a consensus mechanism for blockchain in which consensus is achieved by referring to a list of validators (referred to as authorities when they are linked to physical entities). Validators are a group of accounts/nodes that are allowed to participate in the consensus; they validate the transactions and blocks.

Unlike PoW or PoS, there is no mining mechanism involved. There are several types of PoA protocols, and they vary depending on how they work. Hyperledger and Ripple are based on PoA. Hyperledger is based on PBFT, whereas ripple uses an iterative process.
