---
title: "Terraform - getting started"
date: "2020-05-10"
categories: 
  - "architecture"
  - "cloud"
tags: 
  - "cloud"
  - "infrastructure"
  - "terraform"
---

### Introduction

Terraform is an open source tool created by HashiCorp to define [infrastructure as code](https://pradeeploganathan.com/cloud/infrastructure-as-code/) using a simple, declarative language called HCL . Terraform is used to deploy and manage infrastructure across a variety of cloud providers & virtualization platforms. It can be used to deploy infrastructure to all major cloud providers such as Azure, AWS, Digital ocean, and virtualization platforms such as VMware, Open stack, and others.

Terraform code is written in the HashiCorp Configuration Language (HCL) in files with the extension .tf. It is a declarative language, so your program needs to describe the infrastructure you want and Terraform will figure out how to create it. Using Terraform, we can create, configure, or delete resources. Terraform allows automatic resource provisioning by building dependency graphs. Compared to low-level REST APIs, scripting languages and SDKs, Terraform has a clean, high-level API. The state of your infrastructure is described, stored, versioned, and shared.

### Installing Terraform

Terraform is remarkably simple to get started with on any platform. To install Terraform on windows simply head over to the terraform downloads page [here](https://www.terraform.io/downloads.html) and download the zip file. Extract the binary to a folder. Add the folder to the path environment variable so that you can execute it from anywhere on the command line. If you use chocolatey then use the below command

> **Choco install terraform -y**

On macOS we can use homebrew to install terraform using the below command

> **brew install terraform**

### Terraform Components

Before starting off on terraform it is essential to understand the basic building blocks needed to create a terraform script to provision and deploy resources.

#### Provider

The provider is the connector to the underlying infrastructure you want to manage such as AWS, Azure, or a variety of other Cloud, network, storage, and SaaS services. A provider is responsible for understanding the API interactions and exposing the resources for the chosen platform. This is how your declarative code will interact with the management API of whichever platform you are building on. They provide configuration like connection details and authentication credentials. They provide the abstraction layer between Terraform’s configuration language and the management of resources within the service itself. Providers are not shipped with Terraform. To download the necessary providers, we need to run the terraform init command which installs any required providers. The provider block must be declared in code, though it can have varying degrees of configuration. A single set of configuration files/deployment can use more than a single provider.

To connect to AWS we need to use the below provider code

<script src="https://gist.github.com/PradeepLoganathan/19b215a1e03164fb3a12e0cf8b1e116c.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/19b215a1e03164fb3a12e0cf8b1e116c">View this gist on GitHub</a>

Adding Providers

All the required variables in the provider block can be replaced with environment variables to prevent committing secrets to the code repository. The below azure provider block has all its connection variables stored as environment variables ARM\_SUBSCRIPTION\_ID, ARM\_CLIENT\_ID, ARM\_TENANT\_ID etc.

<script src="https://gist.github.com/PradeepLoganathan/84dd91dce168028be109f6aa9d8ec96a.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/84dd91dce168028be109f6aa9d8ec96a">View this gist on GitHub</a>

Configure Providers

We can create a service principal that we can use as the identity used by the terraform scripts to create the necessary resources. We can create a service principal using the azure CLI command below. The below code creates a service principal with a contributor role with the scope restricted to the subscription indicated by the SUBSCRIPTION\_ID.

```
az ad sp create-for-rbac \
   --role="Contributor" \
   --scopes="/subscriptions/SUBSCRIPTION_ID"
```

This code outputs all the details needed to configure the azure provider similar to the below json payload.

{  
"appId": "00000000-0000-0000-0000-000000000000",  
"displayName": "azure-cli-2020-11-09-03-10-58",  
"name": "http://azure-cli-2020-11-09-03-10-58",  
"password": "0000-0000-0000-0000-000000000000",  
"tenant": "00000000-0000-0000-0000-000000000000"  
}

We can now export these to setup the terraform environment variables as below

```
 export ARM_CLIENT_ID="<insert appid from above>"
 export ARM_SUBSCRIPTION_ID="<insert subscriptionid>"
 export ARM_TENANT_ID="<insert tenant id from above>"
 export ARM_CLIENT_SECRET="<insert password from above>"
```

A full list of the available providers is on the terraform website [here](https://www.terraform.io/docs/providers/index.html).

#### Resources

Resources are the basic building blocks in a Terraform-defined deployment. Resources correspond to several kinds of provider-based resources. Resources represent the infrastructure components you want to manage - VNets, VPC's, networks, firewalls, DNS entries, etc. The parameters of a resource are reflective of that particular class of resource. The resource object is constructed of a type, name, and a block containing the configuration of the resource. There are, however, “meta-arguments” that Terraform makes available for all resources. An example of three different resources namely resource group, vnet and a subnet in Azure is below.

<script src="https://gist.github.com/PradeepLoganathan/80e3746fa512d562863c30425f1ae7cf.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/80e3746fa512d562863c30425f1ae7cf">View this gist on GitHub</a>

The first type of resource here is an azure resource group. Each type of the resource is linked to a provider; you can tell which by the leftmost value in the type, here azurerm. This indicates that this type of resource is provided by the azurerm provider, hence it is denoted as azurerm\_resource-group. The name of the resource is specified next. This name is defined by you—here we’ve named this rg. The name of the resource should describe what the resource is or does. The combination of type and name must be unique in your configuration. Hence there can be only one resource group named rg in your configuration.

#### Data

The data elements are optional elements and are primarily data sources. Data sources provide a mechanism to gather data from the provider. A data source represents a piece of read-only information that is fetched from the provider every time you run Terraform. It is a mechanism to query the provider’s APIs for data and to make that data available to the rest of your Terraform code. Data sources provide a mechanism to gather data from the provider. A data source represents a piece of read-only information that is fetched from the provider every time you run Terraform. Once you have defined a data source, you can use the data elsewhere in your Terraform configuration. Each Terraform provider exposes a variety of data sources. Data sources are most powerful when retrieving information about dynamic entities - those whose properties change value often. e.g AMI id's, regions etc.

<script src="https://gist.github.com/PradeepLoganathan/1e93428c729b853efb98d638da657bb7.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/1e93428c729b853efb98d638da657bb7">View this gist on GitHub</a>

The above code sample shows a data source to list azure subscriptions.

<script src="https://gist.github.com/PradeepLoganathan/1335d1d1ead87a49d90ddb679faf85d4.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/1335d1d1ead87a49d90ddb679faf85d4">View this gist on GitHub</a>

The above code sample shows a data source to list AMI's in AWS with additional filters.

#### Variables

Variables in Terraform are a fantastic way to define centrally controlled reusable values. The information in Terraform variables is saved independently from the deployment plans, which makes the values easy to read and edit from a single file. Variables in Terraform represent parameters for Terraform modules. A variable is defined in Terraform by using a variable block with a label. The label must be a unique name, you cannot have variables with the same name in a configuration. It is also good practice to include a description and type. The variable type specifies the [type constraint](https://www.terraform.io/docs/configuration/types.html) that the defined variable will accept. 

<script src="https://gist.github.com/PradeepLoganathan/cba3f3c7aabcf25afa907d11cb2e8351.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/cba3f3c7aabcf25afa907d11cb2e8351">View this gist on GitHub</a>

In the above example we have two variables, for location and vnet address space. The location variable is of type string and has a default value of australiaeast. The vnet\_address\_space variable is of type list and allows us to define a list of ip address ranges with a single default of 10.0.0.0/16.

The resources example above can now be modified to use these variables as shown below

<script src="https://gist.github.com/PradeepLoganathan/79a3c341a19ee6913b8b17cecce7f7cc.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/79a3c341a19ee6913b8b17cecce7f7cc">View this gist on GitHub</a>

The above example now uses variables to define the location of the resources and the address space of the virtual network.

Depending on the usage, the variables are divided into inputs and outputs. The input variables are used to define values that configure your infrastructure. These values can be used repeatedly without having to remember their every occurrence in the event it needs to be updated. For defining input variables, it's typical to create a separate `variables.tf` file and store the variable configurations in there.

Input variables can be assigned in many ways. They can be passed in when calling terraform apply/plan using the -var option. If we have many variables, then we can use a variables definition file generally named terraform.tfvars to assign variables. Terraform will automatically load variables from the variables definition file if it is named terraform.tfvars and placed in the same directory as the other tf files. The below example shows the input variables defined previously passed in as arguments to terraform apply

<script src="https://gist.github.com/PradeepLoganathan/53501c722ad5450ddaa86ddbecc6f3a6.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/53501c722ad5450ddaa86ddbecc6f3a6">View this gist on GitHub</a>

Output variables, in contrast, are used to get information about the infrastructure after deployment. These can be useful for passing on information such as IP addresses for connecting to the server.

<script src="https://gist.github.com/PradeepLoganathan/42f8464a27e74838f2a7a2f0d124fb85.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/42f8464a27e74838f2a7a2f0d124fb85">View this gist on GitHub</a>

In the above example we have a resource which defines a public IP address. We also have an output variable called pip which can be used to reference the public IP address created by the resource. A complete code sample to standup a Windows virtual machine in Azure using Terraform is [here](https://pradeeploganathan.com/iac/creating-a-windows-vm-using-terraform/).

In this post we looked at the basics of terraform and the HCL language. In the next post we will dig into terraform lifecycle and state management.

> Photo by [hohyeong lee](https://unsplash.com/@hoi_hoit?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/s/photos/building?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
