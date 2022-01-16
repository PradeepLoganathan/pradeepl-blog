---
title: "Using Cluster Api to Create Kubernetes Clusters on AWS"
lastmod: 2021-12-15T15:55:13+10:00
date: 2021-12-15T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - CAPI
  - CAPA
  - Cluster API
  - Kubernetes
  - AWS
categories:
  - Kubernetes
#slug: kubernetes/using-cluster-api-to-create-kubernetes-clusters-on-azure/
summary: In this post let’s look at using CAPI to deploy a Kubernetes cluster in AWS. The end goal is to create a Kubernetes cluster in AWS with three control plane nodes and three worker nodes.
ShowToc: true
TocOpen: false
images:
  - possessed-photography-jIBMSMs4_kA-unsplash.jpg
cover:
    image: "possessed-photography-jIBMSMs4_kA-unsplash.jpg"
    alt: "Using Cluster Api to Create Kubernetes Clusters on AWS"
    caption: "Using Cluster Api to Create Kubernetes Clusters on AWS"
    relative: false # To use relative path for cover image, used in hugo Page-bundles
---

Cluster API (CAPI) allows for the creation, configuration, upgrade, downgrade, and teardown of Kubernetes clusters and their components.If you would like to understand Cluster API and how it enables cluster creation across multiple infrastructure providers, please read my blog post [here](https://pradeepl.com/blog/kubernetes/kubernetes-cluster-api-capi-an-introduction/). In this post let’s look at using CAPI to deploy a Kubernetes cluster in AWS. The end goal is to create a Kubernetes cluster in AWS with three control plane nodes and three worker nodes.

## Installing Prerequisites

We can use KIND to create the bootstrap cluster. You can also use MiniKube to create the bootstrap cluster.

### Install Kind

KIND can be downloaded from its GitHub repository based on your platform. I am using Ubuntu (WSL2) and used the below commands to install kind. Once installed check the version of Kind to ensure that you can run it fine.

```shell
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
sudo chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

#check kind version
kind --version
#kind version 0.11.1
```

Check your install of Kind for the version. I have downloaded the 0.11.1 version of Kind. I had issues with the previous version of Kind. The next step is to create a kind cluster and check the pods created as below

```shell
#Create the kind cluster
kind create cluster

kubectl get pods -A

NAMESPACE            NAME                                         READY  STATUS    RESTARTS   AGE
kube-system          coredns-558bd4d5db-98vmp                     1/1    Running   0          29m
kube-system          coredns-558bd4d5db-jw58j                     1/1    Running   0          29m
kube-system          etcd-kind-control-plane                      1/1    Running   0          30m
kube-system          kindnet-b4622                                1/1    Running   0          29m
kube-system          kube-apiserver-kind-control-plane            1/1    Running   0          30m
kube-system          kube-controller-manager-kind-control-plane   1/1    Running   0          30m
kube-system          kube-proxy-95wg5                             1/1    Running   0          29m
kube-system          kube-scheduler-kind-control-plane            1/1    Running   0          30m
local-path-storage   local-path-provisioner-547f784dff-rncr2      1/1    Running   0          29m
```

Kind uses docker locally to simulate a full-fledged Kubernetes cluster

### Install Cluster API tooling

We need to download the cluster API tooling from GitHub and copy it over to a location in your path.

```shell
#Download the appropriate executable for your platform
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.02/clusterctl-linux-amd64 -o clusterctl
chmod +x ./clusterctl
sudo mv ./clusterctl /usr/local/bin/clusterctl
```

Check to ensure that you can execute Clusterctl

```shell
#I am checking the clusterctl version
clusterctl version

clusterctl version: &version.Info{Major:"1", Minor:"0", GitVersion:"v1.0.2",GitCommit:"89db44e9a462028267ed49295359fe9db2a6a10a", GitTreeState:"clean",BuildDate:"2021-12-06T17:52:47Z", GoVersion:"go1.16.8", Compiler:"gc",Platform:"linux/amd64"}
```

Clusterctl is the primary tool used to create and manage clusters. It is analogous to Kubectl in a lot of ways and mirrors it in terms of managing clusters.

## Initialize AWS provider prerequisites

To get started with creating the K8s cluster on AWS we need to setup our environment variables to be able to authenticate. I am setting the below environment variables (these are temporary credentials, and the environment is long gone ;-))

```shell
#Set aws enviroment variables
export AWS_ACCESS_KEY_ID=EURA3A3DYSLB2SD454V2
export AWS_SECRET_ACCESS_KEY=/589eSbwgxdYCKHyBHx7qLOZKokLfNBK3I0RN72D
exportAWS_SESSION_TOKEN=JJoKb3FpE2luX2MjXXYaCXVzLWVhc3QtMSJHMEUCIQCMqnR0JnCzte1KYSKH+VbkHKz5h5Pi9xqjxq4qeEc0gIgJ8PKS3+BjaqtaZWInKOf1RJ+OsRKX90487SgjQz4SMqowIIPxAAGgw2wMzgzMzI2MTEiDDdrNbTHFIO3JCSvDCqAAuyHPH55z2fu0j2VeWypfSjtirdWHlvCLVBxAfyDM0shRBt9cg8SVizPnujfOaa2P6Z3XQooTFvrt0eP8iXcHAuhEEva5/2aH5Zl2Bw2dimoYWvztM8ZL5m1iKrm/HBpmLegaJFGtAuYq3SRYxXGlQvrA4UWyXCk3IDW+inrpEsucL+bII2GmKJ2FNjw9rQZPj/Pril9VRS+pPeHiVvuRDATLpU2VtnJ3ShHMeZV5pbA5lcgesbsj3r6wbQcoFxBgZFKkvGaAplcNdZgZISWoMZOaESKJXLL1GdbDh7ej3yJKwQn5Irki1ISd8rY3rRxPdnYw8JaQjgY6nQHvFS0+ez067q1jGE9jLfZArQwb1rZmV8FtRFg7WQFljv5wH9tbQu6Yx4Bx6TO4n+BAcAuWXCZKJqfCUThwkplAX/K1382lFnGw+RFRznepkFj8UT6EfGA7yadJJhT7Q4+Or4N3R+q3I+kY++m8rGlVxrUkbtLsd2i2tndXsSViFdwrZ9XhPew7ONSTuhXL4srF0OkZxWb9i4ICt
export AWS_DEFAULT_REGION=us-east-1
```

We also need to install the clusterawsadm which is used to manage IAM objects and credentials. It creates the cloudformation stack needed by CAPA. The cloudformation stack contains the necessary roles and policies needed by CAPA. Download the clusterawsadm binary from github and move it to your path as below.

```shell
curl -L https://github.com/kubernetes-sigs/cluster-api-provider-aws/releasesdownload/v1.2.0/clusterawsadm-linux-amd64 -o clusterawsadm
chmod +x clusterawsadm
sudo mv clusterawsadm /usr/local/bin
```

Check that you can execute the clusterawsadm binary

```shell
#check version of clusterawsadm
clusterawsadm version
clusterawsadm version: &version.Info{Major:"1", Minor:"2", GitVersion:"v1.20", GitCommit:"c356b7e776a70f5ce70a039641ef5b2e992d2d43",GitTreeState:"clean", BuildDate:"2021-12-10T15:48:32Z", GoVersion:"go1.17.3",AwsSdkVersion:"v1.40.56", Compiler:"gc", Platform:"linux/amd64"}
```

Create the necessary stack

```
clusterawsadm bootstrap iam create-cloudformation-stack
```

This command creates it globally once per account. Since i had already created the stack previously, I did not have to run this command again.

```shell
# Create the base64 encoded credentials using clusterawsadm.
# This command uses your environment variables and encodes
# them in a value to be stored in a Kubernetes Secret.
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentialsencode-as-profile)
```

Now we are good to start creating the cluster. We can create the aws cluster as below

```shell
clusterctl init --infrastructure aws
```

The above command creates a local bootstrap cluster in Kind. The output of the command is below

```shell
Fetching providers
Installing cert-manager Version="v1.5.3"
Waiting for cert-manager to be available...
Installing Provider="cluster-api" Version="v1.0.2"TargetNamespace="capi-system"
Installing Provider="bootstrap-kubeadm" Version="v1.0.2"TargetNamespace="capi-kubeadm-bootstrap-system"
Installing Provider="control-plane-kubeadm" Version="v1.0.2"TargetNamespace="capi-kubeadm-control-plane-system"
I1223 17:22:26.599799   18228 request.go:665] Waited for 1.015640605s due toclient-side throttling, not priority and fairness, request: GET:https://127.00.1:45165/apis/controlplane.cluster.x-k8s.io/v1beta1?timeout=30s
Installing Provider="infrastructure-aws" Version="v1.2.0"TargetNamespace="capa-system"

Your management cluster has been initialized successfully!

You can now create your first workload cluster by running the following:

clusterctl generate cluster [name] --kubernetes-version [version] | kubectlapply -f -
 ```

We can check that the Cluster API provider for AWS is running on the local bootstrap cluster as below. We can see that the controller is running in the capa-system namespace.

```shell
kubectl get pods -A

NAMESPACE                          NAME                                                           READY  STATUS    RESTARTS   AGE
capa-system                        capa-controller-manager-76bfb66c8d-jffln                       1/1    Running   0          58s
capi-kubeadm-bootstrap-system      capi-kubeadm-bootstrap-controller-manager-554f694c57-kshkb     1/1    Running   0          61s
capi-kubeadm-control-plane-system  capi-kubeadm-control-plane-controller-manager-cf88668b-vsvq7   1/1    Running   0          60s
capi-system                        capi-controller-manager-d9844b75d-dzghk                        1/1    Running   0          63s
cert-manager                       cert-manager-848f547974-hjjnq                                  1/1    Running   0          80s
cert-manager                       cert-manager-cainjector-54f4cc6b5-tm75d                        1/1    Running   0          81s
cert-manager                       cert-manager-webhook-7c9588c76-cmbf8                           1/1    Running   0          80s
kube-system                        coredns-558bd4d5db-5d82q                                       1/1    Running   0          101s
kube-system                        coredns-558bd4d5db-qlg2r                                       1/1    Running   0          101s
kube-system                        etcd-kind-control-plane                                        1/1    Running   0          110s
kube-system                        kindnet-m89ld                                                  1/1    Running   0          101s
kube-system                        kube-apiserver-kind-control-plane                              1/1    Running   0          109s
kube-system                        kube-controller-manager-kind-control-plane                     1/1    Running   0          110s
kube-system                        kube-proxy-gd8n5                                               1/1    Running   0          101s
kube-system                        kube-scheduler-kind-control-plane                              1/1    Running   0          110s
local-path-storage                 local-path-provisioner-547f784dff-chq4d                        1/1    Running   0          101s
```
