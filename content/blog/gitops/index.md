---
title: "GitOps"
author: "Pradeep Loganathan"
date: 2022-07-07T14:06:19+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - devops
  - gitops
  - cicd
categories:
  - platformengineering
summary: GitOps is a methodology for continuous deployment using a Git repository as the single source of truth. The repository contains the YAML manifests or Helm charts for the Kubernetes resources to be created. The Git repo is used to store, track and version control changes to these YAML files.
ShowToc: true
TocOpen: false
images:
  - images/gitops-process.svg

cover:
    image: "Gitops-cover.png"
    alt: "GitOps"
    caption: "GitOps"
    relative: true  # To use relative path for cover image, used in hugo Page-bundles
 
---

## What is GitOps ?

GitOps is a methodology for continuous deployment using a Git repository as the single source of truth. The Git repository is the source of truth for both declarative infrastructure as well as application workloads. The repository contains the YAML manifests or Helm charts for the Kubernetes resources to be created. The Git repo is used to store, track and version control changes to these YAML files containing the Kubernetes configuration such as Namespaces, Deployments, Pods, Services, Ingress, DaemonSets, ConfigMaps, Secrets etc. The Git repo stores the desired system state. Changes to the runtime state versus the desired state is managed by examining Git diffs and using Git primitives to roll back and reconcile the live state.

GitOps makes Git the source of truth where you specify the desired state of your entire system. Teams introduce changes to the cluster state or application configuration, through a CI pipeline. These updates/changes are stored in a Git repository as Git Commits and can be versioned. Changes between versions can be compared and rolled back if necessary. Changes are explicit and approved through pull requests. A dedicated GitOps component reads approved changes from the Git repository and applies the changes to the Kubernetes cluster through a CD pipeline. This provides for separation of concerns and also ensures that the Git repository reflects the current state of the cluster irrespective of who made the change and when. Any change to a defined branch will trigger the relevant updates to the cluster. The Git repo acts as a backup in case of catastrophic failures and allows for recovery from scratch.

GitOps as a methodology for managing Kubernetes clusters and applications was initially proposed by Alexis Richardson, co-founder and CEO of Weaveworks in a series of [blog posts](https://www.weave.works/blog/gitops-operations-by-pull-request) in 2017. Weaveworks used the GitOps methodology with their Kubernetes environments. The GitOps working group in CNCF is building a GitOps manifesto that standardizes [GitOps principles](https://github.com/open-gitops/documents/blob/main/PRINCIPLES.md). THis group has participation from Weaveworks, Codefresh, Microsoft and others. While the GitOps principles have been solidified the tooling around GitOps is evolving and improving.

![GitOps Process](images/gitops-process.svg "Simplified GitOps workflow")

## DevOps vs GitOps

DevOps is a well established patterns for delivering cloud native applications. DevOps generally takes a push approach where infrastructure updates are *pushed* into the runtime environment. This requires a good knowledge and understanding of the various environments and the current state of these environments. In a GitOps model we use the *pull* approach where the GitOps operator pulls changes based on any updates to the desired state. The GitOps operator is responsible for resolving the state changes and applying them to the runtime environment.

In a DevOps model the application pipelines and the deployment pipelines are disconnected and exclusive. The pipeline to build the runtime environment generally consists of IaC scripts which are run once for a static one time build of the environment. The application pipelines are run multiple times to build and deploy the application to this static runtime environment. In the GitOps model the desired runtime environment is described in the Gir repository. Teams make changes to the desired state by creating Git commits. The updated to the desired state are then rolled into the runtime environment by agents which pull in these changes and deploy them automatically.

In the DevOps methodology we use Terraform, Ansible, Helm, Kubectl and other tools to script out the environment. In GitOps we use an autonomous agent(Operator) to perform tasks such as create, delete or update the environment based on the declarative manifest in Git. The operator is responsible for reconciling the environment definition in Git with the current state of the environment. We do not run Kubectl apply or Terraform apply directly on a runtime environment in GitOps.

## Principles of GitOps

The principles of GitOps are:

* __Declarative configuration__ - The System state is described declaratively. Instead of providing a series of instructions on how to build the infrastructure, applying configurations and deploying the application, we declare the end state of what is needed. Declarative configuration is idempotent and can be run multiple times without any impact to the system consistency.

* __Version controlled, immutable storage__ - Git is the source of truth. The desired system state is versioned in Git. Multiple Git branches can be created to apply changes to different environments. A pull-request (PR) based approval process can be used along with gated check in to ensure that only approved changes are deployed to the environment.

* __Automated delivery__ - Git is the single place for operations (create, change, delete) performed by autonomous agents. An approved Git commit will result in a new deployment and a Git revert would rollback changes.

* __Autonomous agents__ - Software agents known as operators enforce the desired state and alert on drift. These agents monitor the environment and alert for any divergence from the repository. It automatically corrects the divergence.

* __Closed loop__ - Delivery of approved system state changes is automated.

## Why do GitOps ?

GitOps extends DevOps by taking it's best practices such as version control, collaboration, continuous deployment and applying these to environment automation through application deployment, configuration, and infrastructure. GitOps allows developers and DevOps teams to version control the infrastructure and ship applications faster.

The key benefits of GitOps are

* __Standardized workflow__ -  Git as the source of truth improves Developer Experience and ensures easy adoption. Developers are familiar with Git. GitOps applies a consistent development workflow to operations. All operations are performed through Git commands.

* __Auditability__ - Tracking both application code & infrastructure definition in Git results in a full audit trail and compliance. GitOps promotes collaboration between development, security and operations using Git as the collaboration tool. Code reviews result in better stability of systems experiencing a high rate of change.

* __Consistency__ - Infrastructure as a code results in easier rollback, more consistency, & standardization. Automation provides consistency reducing errors.

* __Reliabiity__ - Continuous sync and Configuration drift detection results in reliable environments.

* __Enhanced Security__ - Shifting security left to the GitOps operator. Security is also maintained as code. Traceability of who made/approved a change is automatically provided. Changes to the runtime state can only be applied by automated agents. The need for external access to the system through tools like ssh, rdp etc is eliminated. Controls applied on the Git repository control who can make changes to which parts of the system.

## GitOps Operators

There are many GitOps operators out there, but the two main ones are [Flux](https://fluxcd.io/) and [Argo CD](https://argoproj.github.io/). The Flux and Argo CD GitOps operators are designed to work with Kubernetes. However, GitOps is not limited to Kubernetes operators alone. [Kubestack](https://www.kubestack.com/) is a Terraform based GitOps framework. We will look at each of these operators in detail in future posts.