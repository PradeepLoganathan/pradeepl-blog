---
title: "Using Cluster Api to Create Kubernetes Clusters on Azure"
lastmod: 2021-12-14T15:55:13+10:00
date: 2021-12-14T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - CAPI
  - CAPZ
  - Cluster API
  - Kubernetes
  - Azure
categories:
  - Kubernetes
#slug: kubernetes/using-cluster-api-to-create-kubernetes-clusters-on-azure/
summary: In this post let’s look at using CAPI to deploy a Kubernetes cluster in Azure. The end goal is to create a Kubernetes cluster in Azure with three control plane nodes and three worker nodes.
ShowToc: true
TocOpen: true
images:
  - images/cluster-api-azure.png
cover:
    image: "images/cluster-api-azure.png"
    alt: "Using Cluster Api to Create Kubernetes Clusters on Azure"
    caption: "Using Cluster Api to Create Kubernetes Clusters on Azure"
    relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---

Cluster API (CAPI) allows for the creation, configuration, upgrade, downgrade, and teardown of Kubernetes clusters and their components. If you would like to understand Cluster API and how it enables cluster creation across multiple infrastructure providers, please read my blog post [here]({{< ref "/blog/kubernetes/kubernetes-cluster-api-capi-an-introduction" >}}). In this post let’s look at using CAPI to deploy a Kubernetes cluster in Azure. The end goal is to create a Kubernetes cluster in Azure with three control plane nodes and three worker nodes.

The code for this blog post is on GitHub [here](https://github.com/PradeepLoganathan/capi-azure-cluster-create).

### Installing Prerequisites

We can use KIND to create the bootstrap cluster. You can also use MiniKube to create the bootstrap cluster.

### Install Kind

KIND can be downloaded from its GitHub repository based on your platform. I am using Ubuntu (WSL2) and used the below commands to install kind. Once installed check the version of Kind to ensure that you can run it fine.

```console
>curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
>sudo chmod +x ./kind
>sudo mv ./kind /usr/local/bin/kind
    
#check kind version
> kind --version
kind version 0.11.1
```

Check your install of Kind for the version. I have downloaded the 0.11.1 version of Kind. I had issues with the previous version of Kind. The next step is to create a kind cluster and check the pods created as below

```console
#Create the kind cluster
>kind create cluster

> kubectl get pods -A
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
kube-system          coredns-558bd4d5db-98vmp                     1/1     Running   0          29m
kube-system          coredns-558bd4d5db-jw58j                     1/1     Running   0          29m
kube-system          etcd-kind-control-plane                      1/1     Running   0          30m
kube-system          kindnet-b4622                                1/1     Running   0          29m
kube-system          kube-apiserver-kind-control-plane            1/1     Running   0          30m
kube-system          kube-controller-manager-kind-control-plane   1/1     Running   0          30m
kube-system          kube-proxy-95wg5                             1/1     Running   0          29m
kube-system          kube-scheduler-kind-control-plane            1/1     Running   0          30m
local-path-storage   local-path-provisioner-547f784dff-rncr2      1/1     Running   0          29m
```

### Install Cluster API tooling

We need to download the cluster API tooling from GitHub and copy it over to a location in your path.

```console
#Download the appropriate executable for your platform
>curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.0.1/clusterctl-linux-amd64 -o clusterctl
>chmod +x ./clusterctl
>sudo mv ./clusterctl /usr/local/bin/clusterctl
```

Check to ensure that you can execute Clusterctl

```console
#checking the clusterctl version
>clusterctl version
clusterctl version: &version.Info{Major:"1", Minor:"0", GitVersion:"v1.0.1", itCommit:"2887be851a4384bb000d2a498099f96fe0920cd1", #GitTreeState:"clean", BuildDate:"2021-11-12T17:30:16Z", GoVersion:"go1.16.8", Compiler:"gc", Platform:"linux/amd64"}
```

Clusterctl is the primary tool used to create and manage clusters. It is analogous to Kubectl in a lot of ways and mirrors it in terms of managing clusters.

## Initialize Azure provider prerequisites

We need to setup a bunch of environment variables which are necessary for Cluster API to connect to Azure and provision the control plane and the workload clusters. The Azure provider (CAPZ) will utilize this to connect and provision the clusters. I am using JQ to query the json returned. The -r parameter removes the quotes from the output.

### Create Service principal

We need to create a service principal to connect to azure and assign it to the necessary environment variables. The environment variables need to be base 64 encoded.

```shell
#Login to azure
az login

#Create a service principal
az ad sp create-for-rbac --role contributor

#Set the azure subscription id
export AZURE_SUBSCRIPTION_ID=$(az account show --query 'id' --output tsv)

#Set the azure tenant id
export AZURE_SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --role contributor)

#Set the client id
export AZURE_CLIENT_ID=$(echo $AZURE_SERVICE_PRINCIPAL | jq -r '.appId') 

#Set the client secret
export AZURE_CLIENT_SECRET=$(echo $AZURE_SERVICE_PRINCIPAL | jq -r '.password')

#Set the tenant id
export AZURE_TENANT_ID=$(echo $AZURE_SERVICE_PRINCIPAL | jq -r '.tenant')

# Base64 encode the variables
export AZURE_SUBSCRIPTION_ID_B64="$(echo -n "$AZURE_SUBSCRIPTION_ID" | base64 | tr -d \n')"
export AZURE_TENANT_ID_B64="$(echo -n "$AZURE_TENANT_ID" | base64 | tr -d '\n')"
export AZURE_CLIENT_ID_B64="$(echo -n "$AZURE_CLIENT_ID" | base64 | tr -d '\n')"
export AZURE_CLIENT_SECRET_B64="$(echo -n "$AZURE_CLIENT_SECRET" | base64 | tr -d '\n')"
```

We have now created the necessary environmental variables required by CAPI to create a cluster in Azure. These variables can also be specified in a Yaml file.

### Enable Multi-Tenancy

To enable single controller multi-tenancy, a different Identity can be added to the Azure Cluster that will be used as the Azure Identity when creating Azure resources related to that cluster. Azure achieves this using the [aad-pod-identity library](https://azure.github.io/aad-pod-identity/). The service principal created above is used to create an AzureClusterIdentity resource. We need to create a kubernetes secret using the SP credentials created above.

```shell
# Settings needed for AzureClusterIdentity used by the AzureCluster
export AZURE_CLUSTER_IDENTITY_SECRET_NAME="cluster-identity-secret"
export CLUSTER_IDENTITY_NAME="cluster-identity"
export AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE="default"


# Create a secret to include the password of the Service Principal identity created iAzure
# This secret will be referenced by the AzureClusterIdentity used by the AzureCluster
kubectl create secret generic "${AZURE_CLUSTER_IDENTITY_SECRET_NAME}--from-literal=clientSecret="${AZURE_CLIENT_SECRET}"
```

## Initialize Management cluster

With all the above out of the way we are now ready to initialize our management cluster as below

```shell
# Initialize the management cluster
>clusterctl init --infrastructure azure

Fetching providers
Installing cert-manager Version="v1.5.3"
Waiting for cert-manager to be available...
Installing Provider="cluster-api" Version="v1.0.1" TargetNamespace="capi-system"
Installing Provider="bootstrap-kubeadm" Version="v1.0.1"TargetNamespace="capi-kubeadm-bootstrap-system"
Installing Provider="control-plane-kubeadm" Version="v1.0.1"TargetNamespace="capi-kubeadm-control-plane-system"
I1206 17:45:23.490778    6091 request.go:665] Waited for 1.024684562s due toclient-side throttling, not priority and fairness, request: #GET:https://127.0.01:35691/apis/cluster.x-k8s.io/v1alpha3?timeout=30s
Installing Provider="infrastructure-azure" Version="v1.0.1"TargetNamespace="capz-system"

Your management cluster has been initialized successfully!

You can now create your first workload cluster by running the following:

clusterctl generate cluster [name] --kubernetes-version [version] | kubectl apply -f -took 1m 6s 
```

If you run get pods you will not be able to see the CAPI and CAPZ pods running. The output from get pods after initializing the cluster for Azure is below.

```shell
>kubectl get pods -A
NAMESPACE                          NAME                                                             READY   STATUS   RESTARTS   AGE
capi-kubeadm-bootstrap-system      capi-kubeadm-bootstrap-controller-manager-58945b95bf-87lvj       1/1     Running  0          9m46s
capi-kubeadm-control-plane-system  capi-kubeadm-control-plane-controller-manager-58fc8f8c7c-9w5pm   1/1     Running  0          9m45s
capi-system                        capi-controller-manager-576744d8b7-8rwsn                         1/1     Running  0          9m48s
capz-system                        capz-controller-manager-5bb77c9cf4-8vzwb                         1/1     Running  0          9m42s
capz-system                        capz-nmi-svrht                                                   1/1     Running  0          9m42s
cert-manager                       cert-manager-848f547974-82nx2                                    1/1     Running  0          10m
cert-manager                       cert-manager-cainjector-54f4cc6b5-qrnxf                          1/1     Running  0          10m
cert-manager                       cert-manager-webhook-7c9588c76-lwqwg                             1/1     Running  0          10m
kube-system                        coredns-558bd4d5db-98vmp                                         1/1     Running  0          40m
kube-system                        coredns-558bd4d5db-jw58j                                         1/1     Running  0          40m
kube-system                        etcd-kind-control-plane                                          1/1     Running  0          41m
kube-system                        kindnet-b4622                                                    1/1     Running  0          40m
kube-system                        kube-apiserver-kind-control-plane                                1/1     Running  0          41m
kube-system                        kube-controller-manager-kind-control-plane                       1/1     Running  0          41m
kube-system                        kube-proxy-95wg5                                                 1/1     Running  0          40m
kube-system                        kube-scheduler-kind-control-plane                                1/1     Running  0          41m
local-path-storage                 local-path-provisioner-547f784dff-rncr2                          1/1     Running  0          40m
```    

## Create Workload Cluster

Now that we have our management cluster up and running, we can spin up the workload clusters.

### Workload Cluster Configuration

We need to setup the configuration needed to spin up the workload clusters. I am specifying the azure region as eastus and am selecting “standard\_D2s\_v3” as the VM type. Please be aware of your quota limits as this may prevent cluster creation.

```shell
#Set the azure location
export AZURE_LOCATION="eastus"

#Select VM types.
export AZURE_CONTROL_PLANE_MACHINE_TYPE="Standard_D2s_v3"
export AZURE_NODE_MACHINE_TYPE="Standard_D2s_v3"
```
### Workload template generation

We use the generate cluster command specifying the cluster name, the kubernetes version and the number of control plane and worker machine counts.

```shell
#Generate the cluster configuration
clusterctl generate cluster pradeepl-cluster --kubernetes-version v1.22.0 --control-plane-machine-count=3 --worker-machine-count=3  > pradeep-capz-cluster.yaml
```    

We can now apply the generated yaml to generate the cluster in azure as below

```shell
>kubectl apply -f pradeep-capz-cluster.yaml

cluster.cluster.x-k8s.io/pradeepl-cluster created
azurecluster.infrastructure.cluster.x-k8s.io/pradeepl-cluster created
kubeadmcontrolplane.controlplane.cluster.x-k8s.io/pradeepl-cluster-control-planecreated
azuremachinetemplate.infrastructure.cluster.x-k8s.io/pradeepl-cluster-control-planecreated
machinedeployment.cluster.x-k8s.io/pradeepl-cluster-md-0 created
azuremachinetemplate.infrastructure.cluster.x-k8s.io/pradeepl-cluster-md-0 created
kubeadmconfigtemplate.bootstrap.cluster.x-k8s.io/pradeepl-cluster-md-0 created
azureclusteridentity.infrastructure.cluster.x-k8s.io/cluster-identity created
```
We can query using the azure cli to check if the resource group (pradeepl-cluster) and the corresponding resources have been created as below. We can see below the that “pradeepl-cluster” resource group and the necessary resources have been created. This was surprisingly fast.

```shell
>az group list -o table

#List the resource groups
Name                               Location       Status
---------------------------------  -------------  ---------
pradeepl-cluster                   eastus         Succeeded
cloud-shell-storage-southeastasia  southeastasia  Succeeded
NetworkWatcherRG                   australiaeast  Succeeded

#list the resources in the cluster
>az resource list -g pradeepl-cluster -o table

Name                                                           ResourceGroup    Location    Type                                          Status
  
-------------------------------------------------------------  ---------------- ----------  --------------------------------------------  --------
pradeepl-cluster-vnet                                          pradeepl-cluster eastus      Microsoft.Network/virtualNetworks
pradeepl-cluster-controlplane-nsg                              pradeepl-cluster eastus      Microsoft.Network/networkSecurityGroups
pradeepl-cluster-node-nsg                                      pradeepl-cluster eastus      Microsoft.Network/networkSecurityGroups
pradeepl-cluster-node-routetable                               pradeepl-cluster eastus      Microsoft.Network/routeTables
pip-pradeepl-cluster-apiserver                                 pradeepl-cluster eastus      Microsoft.Network/publicIPAddresses
pip-pradeepl-cluster-node-subnet-natgw                         pradeepl-cluster eastus      Microsoft.Network/publicIPAddresses
node-natgateway                                                pradeepl-cluster eastus      Microsoft.Network/natGateways
pradeepl-cluster-public-lb                                     pradeepl-cluster eastus      Microsoft.Network/loadBalancers
pradeepl-cluster-control-plane-n24kv-nic                       pradeepl-cluster eastus      Microsoft.Network/networkInterfaces
pradeepl-cluster-control-plane-n24kv                           pradeepl-cluster eastus      Microsoft.Compute/virtualMachines
pradeepl-cluster-control-plane-n24kv_OSDisk                    PRADEEPL-CLUSTER eastus      Microsoft.Compute/disks
pradeepl-cluster-control-plane-n24kv_etcddisk                  PRADEEPL-CLUSTER eastus      Microsoft.Compute/disks
pradeepl-cluster-control-plane-n24kv/CAPZ.Linux.Bootstrapping  pradeepl-cluster eastus      Microsoft.Compute/virtualMachines/extensions
pradeepl-cluster-md-0-jv86m-nic                                pradeepl-cluster eastus      Microsoft.Network/networkInterfaces
pradeepl-cluster-md-0-zlw9q-nic                                pradeepl-cluster eastus      Microsoft.Network/networkInterfaces
pradeepl-cluster-md-0-547cl-nic                                pradeepl-cluster eastus      Microsoft.Network/networkInterfaces
pradeepl-cluster-md-0-jv86m                                    pradeepl-cluster eastus      Microsoft.Compute/virtualMachines
pradeepl-cluster-md-0-zlw9q                                    pradeepl-cluster eastus      Microsoft.Compute/virtualMachines
pradeepl-cluster-md-0-547cl                                    pradeepl-cluster eastus      Microsoft.Compute/virtualMachines
pradeepl-cluster-md-0-jv86m_OSDisk                             PRADEEPL-CLUSTER eastus      Microsoft.Compute/disks
pradeepl-cluster-md-0-547cl_OSDisk                             PRADEEPL-CLUSTER eastus      Microsoft.Compute/disks
pradeepl-cluster-md-0-zlw9q_OSDisk                             PRADEEPL-CLUSTER eastus      Microsoft.Compute/disks
pradeepl-cluster-control-plane-whq5x-nic                       pradeepl-cluster eastus      Microsoft.Network/networkInterfaces
pradeepl-cluster-control-plane-whq5x                           pradeepl-cluster eastus      Microsoft.Compute/virtualMachines
pradeepl-cluster-control-plane-whq5x_etcddisk                  PRADEEPL-CLUSTER eastus      Microsoft.Compute/disks
pradeepl-cluster-control-plane-whq5x_OSDisk                    PRADEEPL-CLUSTER eastus      Microsoft.Compute/disks
pradeepl-cluster-md-0-jv86m/CAPZ.Linux.Bootstrapping           pradeepl-cluster eastus      Microsoft.Compute/virtualMachines/extensions
pradeepl-cluster-md-0-547cl/CAPZ.Linux.Bootstrapping           pradeepl-cluster eastus      Microsoft.Compute/virtualMachines/extensions
pradeepl-cluster-md-0-zlw9q/CAPZ.Linux.Bootstrapping           pradeepl-cluster eastus      Microsoft.Compute/virtualMachines/extensions
pradeepl-cluster-control-plane-whq5x/CAPZ.Linux.Bootstrapping  pradeepl-cluster eastus      Microsoft.Compute/virtualMachines/extensions
pradeepl-cluster-control-plane-qcjcx-nic                       pradeepl-cluster eastus      Microsoft.Network/networkInterfaces
pradeepl-cluster-control-plane-qcjcx                           pradeepl-cluster eastus      Microsoft.Compute/virtualMachines
pradeepl-cluster-control-plane-qcjcx_OSDisk                    PRADEEPL-CLUSTER eastus      Microsoft.Compute/disks
pradeepl-cluster-control-plane-qcjcx_etcddisk                  PRADEEPL-CLUSTER eastus      Microsoft.Compute/disks
pradeepl-cluster-control-plane-qcjcx/CAPZ.Linux.Bootstrapping  pradeepl-cluster eastus      Microsoft.Compute/virtualMachines/extensions
```

We can also now check for the status of the cluster and describe the cluster as below

```shell
#Get the cluster
>kubectl get cluster
NAME               PHASE         AGE   VERSION
pradeepl-cluster   Provisioned   25m   

#use clusterctl to describe the cluster
>clusterctl describe cluster pradeepl-cluster

NAME                                                                 READY  SEVERITY REASON                       SINCE MESSAGE                                                                              
/pradeepl-cluster                                                   True                                         16m                                                                                        
├─ClusterInfrastructure - AzureCluster/pradeepl-cluster             True                                         24m                                                                                        
├─ControlPlane - KubeadmControlPlane/pradeepl-cluster-control-plane True                                         16m                                                                                        
│ └─3 Machines...                                                   True                                          21m    Seepradeepl-cluster-#control-plane-cxrlg, pradeepl-cluster-control-plane-dslrs, ...  
└─Workers                                                                                                                                                                                                    
  └─MachineDeployment/pradeepl-cluster-md-0                          False  Warning  WaitingForAvailableMachines  26m    Minimum availability #requires 3 replicas, current0 available                        
    └─3 Machines...                                                 True                                          20m    Seepradeepl-cluster-md-0-#df59c5897-8lv6j, pradeepl-cluster-md-0-df59c5897-f2rrs,
```  

We can see from the above output that the cluster is partially up and running. The control plane nodes are all running but the workers are yet to startup. We can get the kubeconfig to interact with the cluster as below.

```shell
>clusterctl get kubeconfig pradeepl-cluster > pradeepl-cluster.kubeconfig
```

The worker nodes are not up and running as we need to deploy the CNI components. [Azure does not currently support Calico networking](https://projectcalico.docs.tigera.io/reference/public-cloud/azure). CAPZ clusters built with the default Calico config applied will not have a working DNS. As a workaround, we need to deploy this Calico spec that uses VXLAN encapsulation for pod traffic. We can deploy the azure Calico CNI using the template as below

```shell
>kubectl --kubeconfig=./pradeepl-cluster.kubeconfig apply -f https://rawgithubusercontent.com/kubernetes-sigs/cluster-api-provider-azure/main/templates/addonscalico.yaml

configmap/calico-config created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.orgcreated
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.orgcreated
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalicoorg created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalicoorg created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalicoorg created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.orgcreated
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.orgcreated
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crdprojectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.orgcreated
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
daemonset.apps/calico-node created
serviceaccount/calico-node created
deployment.apps/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
Warning: policy/v1beta1 PodDisruptionBudget is deprecated in v1.21+, unavailable in v125+; use policy/v1 PodDisruptionBudget
poddisruptionbudget.policy/calico-kube-controllers created
```

If we describe the cluster now, we should be able to see the control plane as well as the worker nodes up and running.

```shell
#use clusterctl to describe the cluster to check if everything is in ready state
>clusterctl describe cluster pradeepl-cluster
NAME                                                                 READY  SEVERITY REASON  SINCE MESSAGE                                                                              
/pradeepl-cluster                                                   True                    27m                                                                                        
├─ClusterInfrastructure - AzureCluster/pradeepl-cluster             True                    35m                                                                                        
├─ControlPlane - KubeadmControlPlane/pradeepl-cluster-control-plane True                    27m                                                                                        
│ └─3 Machines...                                                   True                     32m    See pradeepl-cluster-control-plane-cxrlg,pradeepl-cluster-control-plane-dslrs, ...  
└─Workers                                                                                                                                                                               
  └─MachineDeployment/pradeepl-cluster-md-0                         True                    20s                                                                                        
    └─3 Machines...                                                 True                     31m    See pradeepl-cluster-md-0-df59c5897-8lv6j,pradeepl-cluster-md-0-df59c5897-f2rrs, ...
```

We now have a Kubernetes cluster running in Azure with 3 control plane nodes and 3 worker nodes. We can deploy workloads and manage them using Kubectl.