---
title: "Terraform - Getting Started"
lastmod: 2020-10-11T15:55:13+10:00
date: 2020-10-11T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
categories: 
  - "architecture"
  - "cloud"
tags: 
  - "cloud"
  - "infrastructure as code"
  - "terraform"
  - "IaC"
  - "gitops"
  - "platformengineering"

summary: Terraform is an open source tool created by HashiCorp to define infrastructure as cod using a simple, declarative language called HCL. Terraform is used to deploy and manage infrastructure across a variety of cloud providers & virtualization platforms. It can be used to deploy infrastructure to all major cloud providers such as Azure, AWS, Digital ocean, and virtualization platforms such as VMware, Open stack, and others.
ShowToc: true
TocOpen: true
images:
  - images/terraform-getting-started.png
cover:
  image: "images/terraform-getting-started.png"
  alt: "Terraform - getting started"
  caption: "Terraform - getting started"
  relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---

In today's rapidly evolving tech landscape, the concept of Infrastructure as Code (IaC) has revolutionized how we manage and provision infrastructure. As I explored in my [previous post on IaC]({{< ref "/blog/infrastructure-as-code" >}}), this paradigm shift involves managing infrastructure with code-based tools, providing agility, consistency, and repeatability.

Terraform stands out in this domain. It's not just a tool but a game changer in how we approach infrastructure automation. In this post, we delve into Terraform, a key player in the IaC arena, to understand its mechanics, benefits, and why it's becoming the go-to solution for many DevOps professionals. We'll explore its core components, how it fits into the IaC model, and provide hands-on examples to get you started. Whether you're new to Terraform or looking to deepen your understanding, this post will guide you through its essentials and best practices, building upon the foundations laid in our discussion on IaC.

# Introduction

Terraform is an open source tool created by HashiCorp to define [infrastructure as code]({{< ref "/blog/infrastructure-as-code" >}}) using a simple, declarative language called HashiCorp Configuration Language(HCL), or optionally JSON. Terraform is used to deploy and manage infrastructure across a variety of cloud providers & virtualization platforms. It can be used to deploy infrastructure to all major cloud providers such as Azure, AWS, Digital ocean, and virtualization platforms such as VMware, Open stack, and others.

Terraform code is written in the HashiCorp Configuration Language (HCL) in files with the extension .tf. It is a declarative language, so your program needs to describe the infrastructure you want and Terraform will figure out how to create it. Using Terraform, we can create, configure, or delete resources. Terraform allows automatic resource provisioning by building dependency graphs. Compared to low-level REST APIs, scripting languages and SDKs, Terraform has a clean, high-level API. The state of your infrastructure is described, stored, versioned, and shared.

# Installing Terraform

Terraform is remarkably simple to get started with on any platform. To install Terraform on windows simply head over to the terraform downloads page [here](https://www.terraform.io/downloads.html) and download the zip file. Extract the binary to a folder. Add the folder to the path environment variable so that you can execute it from anywhere on the command line. If you use chocolatey then use the below command

```shell
Choco install terraform -y
```

On macOS we can use homebrew to install terraform using the below command

```shell
brew install terraform
```
Confirm your installation by opening your command line or terminal and typing ```terraform -v```. You should see the installed version of Terraform displayed.

# Terraform Components

Before starting off on terraform it is essential to understand the basic building blocks needed to create terraform based automation to provision and deploy resources.

## Providers

The provider is the connector to the underlying cloud or infrastructure service that you want to manage such as AWS, Azure, or other on-premises services. A provider is responsible for understanding the API interactions and exposing the resources for the chosen platform. Each provider offers a unique set of resources and data sources that you can use to manage that service's infrastructure components. For example, the AWS provider allows you to manage AWS resources like EC2 instances, S3 buckets, etc. This is how your declarative code will interact with the management API of whichever platform you are building on. They provide the abstraction layer between Terraform’s configuration language and the management of resources within the service itself. Providers are not shipped with Terraform. To download the necessary providers, we need to run the terraform init command which installs any required providers. To use a provider, you must declare it in your Terraform configuration, often specifying necessary details like version and region. This declaration allows Terraform to interact with the respective service's API, thus enabling the creation, management, and updating of resources under that provider.A single set of configuration files/deployment can use more than a single provider.

To connect to AWS using the AWS provider, we need to use the below code

```terraform
provider "aws" { 
  access_key = "XXXXXXXXXXX" 
  secret_key = "XXXXXXXXXXX" 
  region = "us-west-1"
  version = "=2.8.0"
} 
```

All the required variables in the provider block can be replaced with environment variables to prevent committing secrets to the code repository. The below azure provider block has all its connection variables stored as environment variables ARM\_SUBSCRIPTION\_ID, ARM\_CLIENT\_ID, ARM\_TENANT\_ID etc.

```terraform
provider "azurerm" {
  version = "=2.8.0"
  features {}
}
```

We can create a service principal that we can use as the identity used by the terraform scripts to create the necessary resources. We can create a service principal using the azure CLI command below. The below code creates a service principal with a contributor role with the scope restricted to the subscription indicated by the SUBSCRIPTION\_ID.

```shell
az ad sp create-for-rbac \
   --role="Contributor" \
   --scopes="/subscriptions/SUBSCRIPTION_ID"
```

This code outputs all the details needed to configure the azure provider similar to the below json payload.

```json
{  
"appId": "00000000-0000-0000-0000-000000000000",  
"displayName": "azure-cli-2020-11-09-03-10-58",  
"name": "http://azure-cli-2020-11-09-03-10-58",  
"password": "0000-0000-0000-0000-000000000000",  
"tenant": "00000000-0000-0000-0000-000000000000"  
}
```

We can now export these to setup the terraform environment variables as below

```shell
 export ARM_CLIENT_ID="<insert appid from above>"
 export ARM_SUBSCRIPTION_ID="<insert subscriptionid>"
 export ARM_TENANT_ID="<insert tenant id from above>"
 export ARM_CLIENT_SECRET="<insert password from above>"
```

A full list of the available providers is on the terraform website [here](https://www.terraform.io/docs/providers/index.html).

## Resources

Resources are the basic building blocks in a Terraform-defined deployment. Resources correspond to several kinds of provider-based resources. Resources represent the infrastructure components you want to manage - VNets, VPC's, networks, firewalls, DNS entries, etc. Each resource type is specific to its provider and has a set of configurable parameters.The parameters of a resource are reflective of that particular class of resource. The resource object is constructed of a type, name, and a block containing the configuration of the resource. There are, however, “meta-arguments” that Terraform makes available for all resources. When you declare a resource in your configuration, Terraform knows how to create, update, and delete that specific infrastructure piece. An example of three different resources namely resource group, vnet and a subnet in Azure is below.

```json
#create the resource group
resource "azurerm_resource_group" "rg" {
    name = "ateam-resource-group"
    location = "australiaeast"
}

#create the virtual network
resource "azurerm_virtual_network" "vnet1" {
    resource_group_name = azurerm_resource_group.rg.name
    location = "australiaeast"
    name = "dev"
    address_space = ["10.0.0.0/16"]
}

#create a subnet within the virtual network
resource "azurerm_subnet" "subnet1" {
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet1.name
    name = "devsubnet"
    address_prefixes = ["10.0.0.0/24"]
}
```

The first type of resource here is an azure resource group. Each type of the resource is linked to a provider; you can tell which by the leftmost value in the type, here azurerm. This indicates that this type of resource is provided by the azurerm provider, hence it is denoted as azurerm\_resource-group. The name of the resource is specified next. This name is defined by you—here we’ve named this rg. The name of the resource should describe what the resource is or does. The combination of type and name must be unique in your configuration. Hence there can be only one resource group named rg in your configuration.

## Modules

Modules are containers for multiple resources that are used together. A module can include resources, variables, outputs, and even other modules. They are used to create reusable, composable, and maintainable components. Modules allow users to encapsulate a set of resources and configurations into a single logical unit, which can then be reused across different projects or shared with others. For example, if you're creating a module for a basic Azure network infrastructure, your module might include resources like a virtual network, subnets, and network security groups.

This modular approach not only helps in organizing your Terraform configurations but also promotes the reuse of code, making your infrastructure management more efficient and error-resistant.

## Data Sources

In Terraform, data sources allow you to fetch and compute data from outside of Terraform which can then be used within your Terraform configuration. Data sources provide a mechanism to gather data from the provider. A data source represents a piece of read-only information that is fetched from the provider every time you run Terraform. It is a mechanism to query the provider’s APIs for data and to make that data available to the rest of your Terraform code. Data sources can retrieve information like an AWS AMI ID or an Azure subscription ID, which can be used to configure resources. Once you have defined a data source, you can use the data elsewhere in your Terraform configuration. Each Terraform provider exposes a variety of data sources. Data sources are most powerful when retrieving information about dynamic entities - those whose properties change value often. e.g AMI id's, regions etc.

```terraform
data "azurerm_subscription" "current" {
}

output "current_subscription_display_name" {
  value = data.azurerm_subscription.current.display_name
}
```

The above code sample shows a data source to list azure subscriptions.

```terraform
data "aws_ami" "web" {
  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:Component"
    values = ["web"]
  }

  most_recent = true
}
```

The above code sample shows a data source to list AMI's in AWS with additional filters.

## Variables

Variables in Terraform are a fantastic way to define centrally controlled reusable values. They are are used to make your Terraform configurations more dynamic and flexible.The information in Terraform variables is saved independently from the deployment plans, which makes the values easy to read and edit from a single file. Variables in Terraform represent parameters for Terraform modules. A variable is defined in Terraform by using a variable block with a label. The label must be a unique name, you cannot have variables with the same name in a configuration. It is also good practice to include a description and type. The variable type specifies the [type constraint](https://www.terraform.io/docs/configuration/types.html) that the defined variable will accept. 

```terraform
variable "location" {
    type = string
    description = "Azure location of terraform server environment"
    default = "australiaeast"

}

variable "vnet_address_space" { 
    type = list
    description = "Address space for Virtual Network"
    default = ["10.0.0.0/16"]
}
```


In the above example we have two variables, for location and vnet address space. The location variable is of type string and has a default value of australiaeast. The vnet\_address\_space variable is of type list and allows us to define a list of ip address ranges with a single default of 10.0.0.0/16.

The resources example above can now be modified to use these variables as shown below

```terraform
#create the resource group
resource "azurerm_resource_group" "rg" {
    name = "ateam-resource-group"
    location = var.location
}

#create the virtual network
resource "azurerm_virtual_network" "vnet1" {
    resource_group_name = azurerm_resource_group.rg.name
    location = var.location
    name = "dev"
    address_space = var.vnet_address_space
}

#create a subnet within the virtual network
resource "azurerm_subnet" "subnet1" {
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet1.name
    name = "devsubnet"
    address_prefixes = ["10.0.0.0/24"]
}
```

The above example now uses variables to define the location of the resources and the address space of the virtual network.

### Input variables

Depending on the usage, the variables are divided into inputs and outputs. The input variables are used to define values that configure your infrastructure. These values can be used repeatedly without having to remember their every occurrence in the event it needs to be updated. For defining input variables, it's typical to create a separate ```variables.tf``` file and store the variable configurations in there.

Input variables can be assigned in many ways. They can be passed in when calling terraform apply/plan using the -var option. If we have many variables, then we can use a variables definition file generally named terraform.tfvars to assign variables. Terraform will automatically load variables from the variables definition file if it is named terraform.tfvars and placed in the same directory as the other tf files. The below example shows the input variables defined previously passed in as arguments to terraform apply

```terraform
terraform apply -var="location=australiaeast" -var "vnet_address_space=[`"10.0.0.0/16`"]"
```

### Output variables

Output variables, in contrast, are used to get information about the infrastructure after deployment. These can be useful for passing on information such as IP addresses for connecting to the server.

```terraform
##create the network interface for the VM
resource "azurerm_public_ip" "pub_ip" {
    name = "vmpubip"
    location = "australiaeast"
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Dynamic"
}

output "pip" {
    description = "Public IP Address of Virtual Machine"
    value = azurerm_public_ip.pub_ip.ip_address
}
```

In the above example we have a resource which defines a public IP address. We also have an output variable called pip which can be used to reference the public IP address created by the resource. Both input and output variables enhance modularity and reusability in your Terraform configurations, making them more maintainable and scalable.

# State Management

Terraform's state management tracks the state of your infrastructure in a state file. This file maps your real-world resources to your configuration, helping Terraform keep track of what it has created and manage changes efficiently. This state file, is typically named ```terraform.tfstate```, and includes metadata about the infrastructure like resource IDs and attributes. Terraform uses this state to map real-world resources to your configuration and to keep track of dependencies. This allows for efficient and safe changes to your infrastructure, as Terraform can determine what needs to be created, updated, or deleted. It's crucial to handle this state file carefully, especially in team environments, to avoid conflicts and maintain consistency. For distributed teams or more complex setups, remote state backends such as Terraform Cloud can be used for better state management.

# Executing Infrastructure Change - Plan & Apply

In the previous sections, we explored Terraform's core components, such as providers, resources, modules, and state management. Understanding these elements is crucial for creating and managing your infrastructure. Now, let's delve into two fundamental Terraform commands that bring your configurations to life: ```terraform plan``` and ```terraform apply```. These commands represent the execution phase of Terraform, where your infrastructure planning turns into reality. They ensure that the changes you make are predictable, safe, and aligned with your infrastructure goals.

**Terraform Plan**: This command is used for creating an execution plan. It enables you to preview the changes that Terraform plans to make to your infrastructure, based on your configuration files. This step is crucial for verifying that the changes match your expectations before any changes are actually made to the infrastructure.

**Terraform Apply**: After reviewing the plan, the terraform apply command is used to apply the proposed changes. This command will alter the infrastructure to match the desired state described in the configuration files. It's essential to review the plan carefully before applying it, as this step will make actual changes to your infrastructure.

These commands ensure that you have full visibility and control over the changes Terraform will make, reducing the risk of unintended consequences.

# Terraform in Action: Setting Up an Azure Virtual Machine

We have so far understood how terraform enables infrastructure automation using IaC principles, and the various components of terraform. Let us now put in action by using terraform to provision a Windows virtual machine in Azure. We will use the azure terraform provider and create the necessary resources such a an Azure resource group, virtual network, subnets, network interfaces and other components needed to provision a virtual machine. The terraform code is below

```terraform
provider "azurerm" {
  version = "=2.8.0"
  features {}
}

#create the resource group
resource "azurerm_resource_group" "rg" {
    name = "ateam-resource-group"
    location = "australiaeast"
}

#create the virtual network
resource "azurerm_virtual_network" "vnet1" {
    resource_group_name = azurerm_resource_group.rg.name
    location = "australiaeast"
    name = "dev"
    address_space = ["10.0.0.0/16"]
}

#create a subnet within the virtual network
resource "azurerm_subnet" "subnet1" {
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet1.name
    name = "devsubnet"
    address_prefixes = ["10.0.0.0/24"]
}

##create the network interface for the VM
resource "azurerm_public_ip" "pub_ip" {
    name = "vmpubip"
    location = "australiaeast"
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "vmnic" {
    location = "australiaeast"
    resource_group_name = azurerm_resource_group.rg.name
    name = "vmnic1"

    ip_configuration {
        name = "vmnic1-ipconf"
        subnet_id = azurerm_subnet.subnet1.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.pub_ip.id
    }
}

##end creating network interface for the VM


##create the actual VM
resource "azurerm_windows_virtual_machine" "devvm" {
    name = "development-vm"
    location = "australiaeast"
    size = "Standard_A1_v2"
    admin_username = "pradeep"
    admin_password = "kq7UciQluJt%3dtj"
    resource_group_name = azurerm_resource_group.rg.name

    network_interface_ids = [azurerm_network_interface.vmnic.id]
    
    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer = "WindowsServer"
        sku = "2016-Datacenter"
        version = "latest"
    }

}
##end creating VM
```

This Terraform script begins by specifying the Azure provider and its version. The script then proceeds to create a resource group, a virtual network, and a subnet within the network, all located in Australia East. Next, it sets up a network interface for a virtual machine, including a public IP. Finally, it concludes with the creation of an Azure Windows Virtual Machine, specifying its size, admin credentials, network interface, and OS image details. This example serves as a practical demonstration of using Terraform to deploy resources in Azure.

To apply this terraform script, we need to follow these steps

 - Initialize Terraform: Run ```terraform init``` in your project directory. This command initializes the project, installs the Azure provider, and prepares Terraform to manage the infrastructure.

 - Create an Execution Plan: Execute ```terraform plan```. This command lets you preview the changes Terraform will make without actually applying them. It's a good practice to review this plan to ensure it aligns with your expected changes.

 - Apply the Configuration: Run ```terraform apply```. Terraform will prompt you to confirm before it makes any changes. Once confirmed, Terraform will proceed to create the resources as defined in your script.

 # Next steps

If you're new to the concept of Infrastructure as Code, which forms the foundation for tools like Terraform and practices like GitOps, you might find [my introductory guide on Infrastructure as Code]({{< ref "/blog/infrastructure-as-code">}}) helpful.
To understand how Terraform can be integrated into a GitOps workflow, enhancing automation and consistency in infrastructure management, check out my detailed post on [GitOps]({{< ref "/blog/gitops">}}) and [Gitops using ArgoCD]({{< ref "/blog/gitops-with-argocd">}}).
If you are ready to take a leap and start off on something more hands-on, my blog post on [Building a kubernetes cluster on AKS]({{< ref "blog/building-a-secure-and-high-performance-aks-kubernetes-cluster-using-terraform">}}) would be an ideal next stop to build on your knowledge of terraform to provision a kubernetes cluster.

For a deeper dive into Terraform, including practical demonstrations of setting up and managing resources on Azure, check out my detailed walkthroughs and video sessions from my meetups: [Getting Started with Terraform on Azure - Part 1]({{< ref "blog/getting-started-with-terraform-on-azure-part-1" >}}) and [Part 2]({{< ref "blog/getting-started-with-terraform-on-azure-part-2" >}}). These sessions complement the insights shared here, offering a visual and interactive approach to mastering Terraform.
