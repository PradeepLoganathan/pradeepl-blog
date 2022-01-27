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
  - "post"dsfsdf
---

Tekton provides a cloud-native, standardized set of building blocks for CI/CD systems. It is an [open-source project](https://github.com/tektoncd) and is part of the [Continuous Delivery Foundation](https://cd.foundation/projects/) set of projects. It runs natively on Kubernetes and can target any platform, language, or cloud. It extends the Kubernetes API and provides custom resources to create CI/CD pipelines. Tekton aims to make it easier and faster to build, test, and package up your source code. It allows developers to build, test, and deploy cloud-native, containerized applications across multiple Kubernetes providers, build and deploy immutable images, version control IaC etc. Tekton can be used to perform advanced Kubernetes deployment/rollback strategies such as blue-green deployment, canary deployment, rolling updates etc.

Tekton was originally the build system for the Knative serverless workload platform. It was converted to a standalone project implementing a general-purpose CI/CD platform. It was donated to the Continuous Delivery Foundation in March 2019.

## Tekton Components

Tekton uses  a pipeline architecture composed of pipelines, tasks , steps and workspaces to provide a highly configurable continuous delivery mechanism. The github repo for Tekton pipelines is [here](https://github.com/tektoncd/pipeline). It uses Tekton triggers to enable continuous integration to trigger pipelines based on triggers defined. The github repo for Tekton triggers is [here](https://github.com/tektoncd/triggers). It also provides a CLI to interact with these components. The project is hosted on github [here](https://github.com/tektoncd/cli). Let us take a look at these components in detail.

## Tekton Pipelines

Tekton uses Kubernetes Custom Resource Definitions (CRD) to define the building blocks used to assemble CI/CD pipelines.The CRD's defined by Tekton are below.

### Step

Steps are the most basic units used to create a pipeline. A step represents a single atomic operation that is part of the larger CI/CD pipeline. Each step defines the command or tool to be executed (e.g., Checkout code from a git branch, building a container image) and the container image that contains the command or tool. Each step runs in a container with a specific image, defining the command to be executed once the container starts. This ensures that the step is reproducible and immutable. A step should ideally perform a single action. If a step has multiple actions then it should ideally be refactored to a Task. Steps are used to create a task.

### Task

A Task is a collection of steps that should be executed in a specific order. It is composed of several reusable, loosely coupled steps that perform a specific function. Steps in a task are generally related to each other. A task contains a minimum of one step while complex tasks can have many steps. A task is the basic unit of execution in Tekton. Tasks get executed as Kubernetes pods while steps in a Task map to containers. A Task is run in a single pod, enabling steps to share a common volume and resources. Tasks are usually designed to be independent of the data they operate on. Parameters can be used to customize the resources and behavior associated with a Task.

The [Tekton catalog](https://github.com/tektoncd/catalog) contains a catalog of reusable task resources for everyday operations such as [Kubernetes actions](https://github.com/tektoncd/catalog/tree/main/task/kubernetes-actions), [GIT operations](https://github.com/tektoncd/catalog/tree/main/task/git-cli/0.3) etc. Tasks are generally stitched together to create a pipeline.

A simple hello world task is defined below. This task has two steps named hello-one and hello-two referenced by ``spec.steps.name``. The step use the ubuntu image to create a container and print a text message.

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: hello-world-task
spec:
  steps:
    - name: hello-one
      image: ubuntu
      script: |
        set -e
        echo "Hello World from step one!"
    - name: hello-two
      image: ubuntu
      script: |
        set -e
        echo "Hello World from step two!"
```

### Pipeline

A Pipeline defines a workflow composed of a set of tasks to be executed in a specific order. A pipeline consists of one or more tasks, each of which may include several steps. The pipeline is composed of tasks that define the various parts of the workflow ( e.g build, test, manage artifact etc.) and these tasks are executed either sequentially, concurrently or as a directed acyclic graph. Some tasks may declare other tasks as dependencies and need to be run after the dependent task is complete. These tasks are run sequentially. Some tasks may not have any dependencies and are run concurrently. Pipelines are stateless, reusable, and parameterized. Tekton creates several pods based on the task and ensures all pods execute successfully. Pipelines can execute tasks on different Kubernetes nodes.

A sample pipeline is defined below. This pipeline has two tasks which are referenced by ``tasks.taskref.name``. This pipeline executes the tasks.

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
 name: hello-pipeline
spec:
 tasks:
 - name: hello-world
   taskRef:
    name: hello-world-task
 - name: hello-universe
   taskRef:
    name: hello-universe-task
```

### Workspace

A Workspace is a shared volume used by tasks and pipelines. This allows artifact data to be shared as input/output by tasks and pipelines.A workspace can be created as a ConfigMap, PersistenceVolumeChain, Secrets etc. A workspace can be used as a build cache to speed up the CI/CD process. It can also be used to access application configuration, credentials etc.

### TaskRun

A TaskRun is used to execute a task. A TaskRun will execute all the steps defined in the task. It will also contain the status of the task's execution and the status of the execution of each step. The TaskRun will execute until all the steps have been marked as successful.

```yaml
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
 name: hello-world-task-run
spec:
 taskRef:
  name: hello-world-task
```

### PipelineRun

A pipelinerun is used to execute a pipeline.A pipelinerun creates a Taskrun for each task in the pipeline. The tasks are executed in the order defined in the pipeline. The pipelinerun monitors the execution of the pipeline and reports on the progress and completion of the pipeline.

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
 generateName: run-simple-pipeline
spec:
 pipelineRef:
  name: hello-pipeline
```

## Tekton Triggers

Tekton triggers provides continuous integration functionality. The custom resource definitions detailed above need to be manually triggered to perform a build and deploy. We would need to use kubectl or Tekton CLI to start a Tekton pipeline. Tekton triggers introduces new custom resources to automate your CI/CD pipelines further. The CRD's are Trigger templates, Trigger bindings and Event listeners. It uses webhooks as a mechanism to trigger pipelines automatically.  Let us get to know these CRD's in a bit more detail.

### TriggerTemplates

A Trigger template defines a template for the resources that the trigger will create. The template defines the pipeline that should be triggered and the parameters the need to be passed to the pipelines.  
### TriggerBindings


### EventListeners

An event listener listens to incoming HTTP requests

