---
title: "Creating a Windows VM using Terraform"
date: "2020-05-18"
categories: 
  - "iac"
  - "terraform"
tags: 
  - "devops"
  - "iac"
  - "terraform"
---

This post is a follow up on the [Terraform 101]({{< ref "/blog/terraform-getting-started">}}) sessions for the Sunshine Coast dotnet user group. The slides and the code from the session are below.

## Slides

<iframe src="//www.slideshare.net/slideshow/embed_code/key/hpSI3Kh84vIIu6" width="595" height="485" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen></iframe>

**[Terraform 101](//www.slideshare.net/pradeep_loganathan/terraform-101-234192420 "Terraform 101")** from **[Pradeep Loganathan](https://www.slideshare.net/pradeep_loganathan)**

## Creating a Windows Virtual Machine

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

The above code is not at all production ready and was used as part of a live coding exercise to use Terraform to create a Windows VM. The above code creates the VM password as plain text which is not ideal. The password can be generated and printed as an output if necessary.

> Photo by [Wengang Zhai](https://unsplash.com/@wgzhai?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
