---
title: "Tekton Getting Started"
author: "Pradeep Loganathan"
date: 2022-01-25T11:01:47+10:00

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

Tekton provides a cloud-native, standardized set of building blocks for CI/CD systems. It is an [open-source project](https://github.com/tektoncd) and is part of the [Continuous Delivery Foundation](https://cd.foundation/projects/) set of projects. It runs natively on Kubernetes and can target any platform, language, or cloud. It extends the Kubernetes API and provides custom resources to create CI/CD pipelines. Tekton aims to make it easier and faster to build, test, and package up your source code. It allows developers to build, test, and deploy cloud-native, containerized applications across multiple Kubernetes providers.

Tekton was originally the build system for the Knative serverless workload platform. Because it provided value as a general-purpose CI/CD platform, it was converted to a standalone project and donated to the Continuous Delivery Foundation in March 2019.3

## Step

Steps are the most basic units used to create a pipeline. A step represents a single discrete operation that is part of the larger CI/CD pipeline. Each step defines the command or tool to be executed (e.g., Checkout code from a git branch, building a container image) and the container image that contains the command or tool. Each step runs in its container with a specific image, defining the command to be executed once the container starts. This ensures that the step is reproducible and immutable. Steps are used to create a task.  

## Task

A Task is a collection of steps that should be executed in a specific order. It is composed of several reusable, loosely coupled steps that perform a specific function. Steps in a task are generally related to each other. A task contains a minimum of one step while complex tasks can have many steps.Tasks get executed as Kubernetes Pods while steps in a Task map onto containers. A Task is run in a single pod, enabling steps to share a common volume and resources.
The [tekton catalog](https://github.com/tektoncd/catalog) contains a catalog of reusable task resources for everyday operations such as [Kubernetes actions](https://github.com/tektoncd/catalog/tree/main/task/kubernetes-actions), [GIT operations](https://github.com/tektoncd/catalog/tree/main/task/git-cli/0.3) etc.

## Pipeline

A pipeline is a list of [Tasks](#Task) needed to build and/or deploy your apps.

