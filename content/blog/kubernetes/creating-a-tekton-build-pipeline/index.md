---
title: "Creating a Tekton Build and deploy Pipeline"
author: "Pradeep Loganathan"
date: 2022-04-11T23:40:28+10:00

draft: true
comments: true
toc: true
showToc: true

description: ""

cover:
    image: "cover.png"
    relative: true

images:

mermaid: true

tags:
  - "post"
---

In the previous post we worked through the building blocks of Tekton. In this post we will use that knowledge to build a tekton pipeline that will build and deploy a container image.

## Pipeline

To demonstrate the concepts, let us build a simple build and deploy pipeline using Tekton. The pipeline does a git clone of the source code, builds the code, creates a container and deploys the container to the Kubernetes cluster.

{{< mermaid >}}
flowchart  LR
A(Clone Source) --> B(Build)
B --> C{Test}
C --Tests pass--> D(Containerize)
C --Tests Fail--> E(Report Failure)
D ---> F(Deploy Container)
{{< /mermaid >}}

Each of the steps in the pipeline is a Tekton task. Let us start by installing Tekton, building the tasks and then adding them to the pipeline. Let us start by installing the core components first.

[![Spotify](https://spotify-github-readme.vercel.app/api/spotify)](https://open.spotify.com/embed/episode/6v8ugYvufK1WU6VHrHoonK)
<!-- 
<iframe style="border-radius:12px" src="https://open.spotify.com/embed/episode/6v8ugYvufK1WU6VHrHoonK?utm_source=generator" width="100%" height="232" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture"></iframe> -->

## Install Tekton Components

### Install Core components

Tekton can be installed on any kubernetes cluster version 1.15 or higher. For this blog post, I am deploying tekton on an Azure Kubernetes cluster with version 1.21.9. We can deploy the pipeline, trigger and the interceptor components as below. I strongly advise to run a ```kubectl get pods --namespace tekton-pipelines --watch``` command to see the status of the pods after installing each component. Ensure that the pods are running before installing the next set of components.

```shell
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
```

### Install Tekton Dashboard

The Tekton dashboard is a web application that can be used to monitor the status of the pipeline. The dashboard is installed as a service.  To access the dashboard we need to perform port forward the container port 9097 of the service.

```shell
kubectl apply --filename https://github.com/tektoncd/dashboard/releases/latest/download/tekton-dashboard-release.yaml

kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
```

### Install Tekton CLI

The Tekton CLI makes it easier to interact with Tekton pipelines. It is available as a binary package on the Tekton releases page. On linux it can be installed as below

```shell
curl -LO https://github.com/tektoncd/cli/releases/download/v0.23.1/tkn_0.23.1_Linux_x86_64.tar.gz
sudo tar xvzf tkn_0.23.1_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn
```

We can now use the tkn cli to check the version of installed components using the ```tkn version``` command. I get the below versions after installing the components.

```shell
Client version: 0.23.1
Pipeline version: v0.34.1
Triggers version: v0.19.1
Dashboard version: v0.25.0
```

We can now start building the tasks needed by the pipeline.

## Clone Source Task

This task has two steps. The first step clones the source code from the git repository . The second step lists the cloned directory. This is helpful when we want to see logs. Since this is a generic task, we can parameterize the task to make it reusable. The task takes a single parameter to the repository URL. The yaml for the checkout task is below.

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: clonesource
spec:
  params:
    - name: repository
      type: string
      description: HTTPS URL of the git repository to clone
  workspaces:
    - name: source
      description: The directory where the source code will be cloned
  steps:
    - name: clone
      image: alpine/git
      workingDir: $(workspaces.source.path)
      script: |
        git clone $(params.repository) ./source
    - name: list
      image: alpine
      workingDir: $(workspaces.source.path)
      command: ["ls", "-l", "./source"]
```

To test this task we can use the tkn cli to run it. We need to add this task to the cluster and then run the task.I generally add tasks to a specific namespace.

```bash
# create the namespace
kubectl create ns dev-pipelines

# create the clonesource task in the dev-pipelines namespace 
kubectl apply -f clonesource-task.yaml -n dev-pipelines

```

You can see the tasks in a namespace using the ```kubectl get tasks -n <<namespace>>``` command.

```bash
tkn task list -n dev-pipelines
NAME          DESCRIPTION   AGE
clonesource                 12 seconds ago
```

We can now run this task using the ```tkn task run``` command as below. I am passing the parameters and the workspace details to the task. We can use an emptyDir workspace to share the workspace between tasks. We can also use the ```--showlog``` option to see the logs of the task.

```bash
tkn task start clonesource \
 --showlog \
 --namespace dev-pipelines \
 --param repository=https://github.com/PradeepLoganathan/TektonSampleApp \
 --workspace name=source,emptyDir=""
 ```

 This produces the below output when the task is run. The task clones the source from the git repository and lists the cloned directory.

 ```bash
 TaskRun started: clonesource-run-qz4w2
Waiting for logs to be available...
[clone] Cloning into './source'...

[list] total 28
[list] drwxr-xr-x    2 root     root          4096 Apr 13 00:42 Controllers
[list] -rw-r--r--    1 root     root           557 Apr 13 00:42 Program.cs
[list] drwxr-xr-x    2 root     root          4096 Apr 13 00:42 Properties
[list] -rw-r--r--    1 root     root           327 Apr 13 00:42 TektonSampleApp.csproj
[list] -rw-r--r--    1 root     root           264 Apr 13 00:42 WeatherForecast.cs
[list] -rw-r--r--    1 root     root           127 Apr 13 00:42 appsettings.Development.json
[list] -rw-r--r--    1 root     root           151 Apr 13 00:42 appsettings.json
 ```

 The tkn cli creates a task run and runs the tasks. We can also create a taskrun to run the task. The taskrun provides the necessary details to run the task. The taskrun yaml is below.

 ```yaml
 apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  generateName: clonesource-tr-
spec:
  params:
    - name: repository
      value: https://github.com/PradeepLoganathan/TektonSampleApp.git
  workspaces:
    - name: source
      emptyDir: {}
  taskRef:
    name: clonesource
 ```

 We can now create the task run on the cluster and monitor the status of the task run.

 ```bash
 # Create the taskrun. This will create a taskrun with a generated name
  kubectl create -f clonesource-taskrun.yaml -n dev-pipelines

  # Monitor the taskrun
  tkn taskrun logs clonesource-tr-rt8m9 -n dev-pipelines
  ```

  <https://hashnode.com/post/tekton-ci-simplified-ckzleauyw0n6beks1diq6ejvv>