---
title: "Building a secure and high-performance AKS Kubernetes cluster using Terraform"
date: "2020-11-14"
categories: 
  - "azure"
  - "iac"
  - "kubernetes"
  - "terraform"
tags: 
  - "azure"
  - "cluster"
  - "kubernetes"
---

I have been part of a couple of build outs where we built [Kubernetes](https://pradeeploganathan.com/kubernetes/kubernetes-concepts-pods/) clusters to run our cloud workloads. These builds involved deploying AKS clusters using terraform and AzDO. Designing the AKS infrastructure is key to ensure that the cloud workloads running on them can be deployed, secured, and hosted effectively. In this post I am documenting the general steps involved in building out a Kubernetes infrastructure on Azure Kubernetes Service (AKS) using terraform and deploy workloads using Azure devops (AzDO) and Helm charts.

You can follow along as we build the AKS Kubernetes cluster using the code at [this github repository](https://github.com/PradeepLoganathan/azure_aks_terraform).

I generally breakdown my terraform code into multiple terraform modules and files based on the function they perform. The files are named based on the functionality provided by them. The terraform binary will read all the resources defined in all the templates and create a dependency tree in memory and deploy resources starting from the root node. Let us start by building the various parts if the infrastructure and bringing them all together to build the terraform cluster.

### Providers

The main.tf template defines the resource providers needed and configures the backend for the solution. We are using the Azure resource manager and the Azure Active directory providers for this solution. We can also configure the backend used by terraform for state management. We use an Azure blob store as the back end for the terraform state files. This blog post shows how to configure an Azure blob store as the back end for terraform.

<script src="https://gist.github.com/PradeepLoganathan/f52a57faab1cca9d4f98b84e3fcef4dd.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/f52a57faab1cca9d4f98b84e3fcef4dd">View this gist on GitHub</a>

Configuring providers in main.tf

### Variables

The variables.tf template declares variables and contains values for variables which terraform needs to deploy the solution. They are like parameters in ARM templates and contains values which need to specified explicitly for terraform to create resources. We can override these values during deployment and provide default values. The below gist contains a snapshot of some of the variables required to build the Kubernetes cluster. The complete variables file for the solution is [here](https://github.com/PradeepLoganathan/azure_aks_terraform/blob/main/variables.tf).

<script src="https://gist.github.com/PradeepLoganathan/676626759247d54a1bba44ddb3589c06.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/676626759247d54a1bba44ddb3589c06">View this gist on GitHub</a>

Declaring variables

### Resource Group

We can now create a resource group which will group all the resources needed to create our Kubernetes cluster in the aks\_rg manifest file as below. resource\_prefix and location are variables declared in the variables.tf file. These provide the values needed to create the resource group.

<script src="https://gist.github.com/PradeepLoganathan/60529aec67a8ecc5066178b51bad8f19.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/60529aec67a8ecc5066178b51bad8f19">View this gist on GitHub</a>

Creating Resource group

### Network resources

Let us next create the network resources needed to standup the AKS cluster. The network resources are generally created as part of the hub and spoke network design and we can pass in the necessary identifiers but for the sake of completeness of this post, I am creating the necessary network resources in aks\_network.tf file. In the below gist I am creating a vnet and adding a subnet to it. I am then creating a route table and associating it with the subnet. It is important to note that all nodes created in the Kubernetes cluster will be associated with this subnet.

<script src="https://gist.github.com/PradeepLoganathan/96ac4338e38712b2aa57d1840bd17211.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/96ac4338e38712b2aa57d1840bd17211">View this gist on GitHub</a>

Creating Network resources

### Log Monitoring

Monitoring is critical to successfully managing the AKS instance. AKS provides seamless integration between the cluster and Azure log analytics to monitor container logs. To enable monitoring, we need to create a log analytics workspace resource. This resource is created in the aks\_loganalytics.tf file in the code sample and I have added the same to the gist below. The log analytics workspace name should be unique globally and we can ensure this by generating and adding a random id into the name.

<script src="https://gist.github.com/PradeepLoganathan/efbd83c65b34500b375e9ebd8c7c99a8.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/efbd83c65b34500b375e9ebd8c7c99a8">View this gist on GitHub</a>

Creating Log analytics workspace

### Kubernetes Cluster

Now that we have the necessary prerequisites to create a Kubernetes cluster, we can get started with defining the azurerm\_kubernetes\_cluster resource. The Kubernetes cluster is configured in the aks\_cluster.tf file in the github sample. Configuring the Kubernetes cluster is an involved process. However, we can work through configuring it in incremental logical steps to build a secure and high-performance system. We will start by configuring the basic properties of the cluster

#### Basic Properties

The basic properties of the cluster include its name, location, resource group and a bunch of other properties. We can use the private\_cluster\_enabled flag to indicate if we want to build a private kubernetes cluster.In a private cluster traffic between the nodes and the API server does not leave the private network. We will not be building a private cluster and hence I have set this flag to false. We can use the kubernetes\_version to specify the version of kubernetes that needs to be installed on the cluster. When an AKS cluster is deployed a second resource group gets created for the worker nodes. We can specify the name for this resource group using the node\_resource\_group property. The dns\_prefix forms part of th fully qualified domain name used to access the clsuter. The below gist shows these properties and their values in the sample.

<script src="https://gist.github.com/PradeepLoganathan/c2f878b8f1dad80624755b9b7bdfc2aa.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/c2f878b8f1dad80624755b9b7bdfc2aa">View this gist on GitHub</a>

Defining Basic AKS configuration

#### Default Node Pool

Node pools contain the underlying VM's that host pods. There are two types of node pools, the system node pool, and the user node pool. The system node pool hosts critical system pods which are required to run Kubernetes ( CoreDNS, Kuberentes Dashboard, tunnelfront, metrics-server, omsagent etc. ). The user node pool hosts custom user pods which contain the application workload. There can be only one system node pool in the AKS cluster. We can setup multiple user node pools. We can host applications on the system node pool too. However, it is recommended to schedule your application pods on user node pools and dedicate system node pools to only critical system pods. The default node pool block defines the number of nodes and the type of VM that the cluster uses.

In this block we can specify the Kubernetes version to install, the node count, availability zones and the vm type to use. Here I have specified VM scale sets for the nodes spread across availability zones which have been configured in variables.tf. To ensure that application workloads are not scheduled on the default node pool I am using taints to constrain the type of workloads that can be scheduled on the default node pool. I am using the "CriticalAddonsOnly=true:NoSchedule" taint to ensure this. This is specified in the var.system\_node\_pool.taints variable. I am also configuring the subnet for the default node pool to point to the subnet created earlier as part of setting up the network stack. The subnet id is obtained by referencing the azurerm\_subnet.aks\_subet.id reference.

<script src="https://gist.github.com/PradeepLoganathan/164e2fd11991e1a5d72c80fd905eca71.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/164e2fd11991e1a5d72c80fd905eca71">View this gist on GitHub</a>

Create Default node pool

#### Network Profile

AKS supports two networking models namely Kubenet networking and Azure CNI networking. Microsoft recommends choosing CNI networking for production deployments. With CNI networking every pod gets an IP address from the subnet and can be accessed directly. These IP addresses must be unique across the address space and need to be planned carefully to avoid IP address exhaustion. Each node hosts multiple pods (the default is 30) and in a cluster of 3 nodes we would easily need to plan for 90 IP addresses.

<script src="https://gist.github.com/PradeepLoganathan/339bb419573a9ee15b3387bef9c57abf.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/339bb419573a9ee15b3387bef9c57abf">View this gist on GitHub</a>

We can specify CNI networking by setting the network\_plugin to azure. The network\_policy parameter sets up the network policy to be used with Azure CNI. The choices are Azure and Calico. I have set it to Azure here. We are customizing cluster egress by setting the outbound type property to userDefinedRouting. Since we are using UDR we will need to specify the route tables with a NVA hop destination. The route tables have been previously setup in the network definition file.

#### Addons

The addon\_profile block allows us to specify addons to be installed. In the below addon\_profile block, I am installing the azure policy, Kube dashboard and the oms agent addons. The OMS agent addon connects the pods to the log analytics workspace created earlier enabling rich cluster insights.

<script src="https://gist.github.com/PradeepLoganathan/b830835aed06cb81361b7c9ad1dfa53b.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/b830835aed06cb81361b7c9ad1dfa53b">View this gist on GitHub</a>

Addons to be installed

We would need to create a log analytics workspace and retrieve the resource ID of the log analytics workspace. Now that we have all the pieces of the infrastructure ready, we can go ahead and initialize terraform to ensure that the necessary modules are downloaded. once terraform is initialized we can validate that our code is good to go. If I run terraform apply as below, terraform will indicate the infrastructure changes that it will perform to standup the Kubernetes cluster on AKS.

![](images/terraform-plan.png)

Terraform Plan

The output of terraform plan is below

<script src="https://gist.github.com/PradeepLoganathan/aa1c57a8d0fbbc7865a545773a28a4b8.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/aa1c57a8d0fbbc7865a545773a28a4b8">View this gist on GitHub</a>

![](images/terraform-apply-1024x488.png)

Terraform Apply -auto-approve
