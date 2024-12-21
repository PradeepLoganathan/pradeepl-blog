---
title: "Creating RabbitMQ clusters on Kubernetes"
author: "Pradeep Loganathan"
date: 2022-03-04T13:07:13+10:00

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

RabbitMQ provides clustering and high availability out of the box. It is a highly available system that is designed to be highly scalable and fault-tolerant. We can deploy a RabbitMQ cluster on Kubernetes. There are multiple options to deploy a RabbitMQ cluster on Kubernetes. The easiest option is to use the official RabbitMQ Operator.

## Create the Kubernetes cluster

Let us define the cluster name, location and the resource group as variables.

```shell
export CLUSTER_NAME=RabbitCluster
export LOCATION=australiaeast
export RESOURCE_GROUP_NAME=RabbitMQResourceGroup
```

We can now login to azure using the below command. This opens the browser and creates a session.

```shell
az login
```

We can now create a resource group. I am creating a resource group in australiaeast region using the variables defined above.

```shell
az group create --location ${LOCATION} --name ${RESOURCE_GROUP_NAME}
```

We are now ready to create a cluster. I am creating a cluster named RabbitCluster in the resource group RabbitMQResourceGroup. I am also defining the zones where the agent nodes are deployed using the --zones parameter. I am distributing the nodes across all 3 zones. In this case we have 3 nodes spread across 3 zones.

```shell
az aks create \
    --resource-group ${RESOURCE_GROUP_NAME} \
    --name ${CLUSTER_NAME} \
    --generate-ssh-keys \
    --vm-set-type VirtualMachineScaleSets \
    --load-balancer-sku standard \
    --node-count 3 \
    --zones 1 2 3
```

Once the cluster is created we can merge the cluster credentials into kubeconfig using the below command

```shell
az aks get-credentials --resource-group ${RESOURCE_GROUP_NAME} --name ${CLUSTER_NAME}
```

we can now verify that the AKS nodes are distributed across the specified region and availability zone using the below command.

```shell
kubectl get nodes -o custom-columns=NAME:'{.metadata.name}',REGION:'{.metadata.labels.topology\.kubernetes\.io/region}',ZONE:'{metadata.labels.topology\.kubernetes\.io/zone}'
```

This command will return the following output indicating the nodes are distributed across the specified region and availability zone. We can see below that the nodes are distributed across all 3 zones in australia east region.

```shell
NAME                                REGION          ZONE
aks-nodepool1-35366113-vmss000000   australiaeast   australiaeast-1
aks-nodepool1-35366113-vmss000001   australiaeast   australiaeast-2
aks-nodepool1-35366113-vmss000002   australiaeast   australiaeast-3
```

I can also use the below command to get further information about node distribution

```shell
kubectl describe nodes | grep -e "Name:" -e "failure-domain.beta.kubernetes.io/zone"
```

This produces the below output providing further information about node distribution.

```shell
Name:               aks-nodepool1-35366113-vmss000000
                    failure-domain.beta.kubernetes.io/zone=australiaeast-1
Name:               aks-nodepool1-35366113-vmss000001
                    failure-domain.beta.kubernetes.io/zone=australiaeast-2
Name:               aks-nodepool1-35366113-vmss000002
                    failure-domain.beta.kubernetes.io/zone=australiaeast-3
```

## RabbitMQ Cluster Operator

A Kubernetes operator is type of controller that simplifies complex deployments.An operator manages the installation, configuration, upgrade  It extends the kubernetes API with custom resource definitions (CRD). The RabbitMQ cluster operator automates the provisioning and management of RabbitMQ on Kubernetes clusters.

## Deploy the RabbitMQ cluster operator

We now have an AKS cluster deployed with nodes distributed across the specified region and availability zone. We can now deploy the RabbitMQ cluster operator. We can deploy the cluster operator by applying it to the cluster from github as below

```shell
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml
```

If you are using Krew plugin manager you can install the rabbitmq plugin to deploy the rabbitmq operator. You can install the rabbitmq plugin using the below command.

```shell
kubectl krew install rabbitmq
```

Once this is done we can install the rabbitmq operator using the below command.

```shell
kubectl rabbitmq install-cluster-operator
```

## Define the RabbitMQ Cluster
