---
title: "Infrastructure as Code"
date: "2019-07-29"
categories: 
  - "cloud"
---

Infrastructure as code (IaC) is the process of managing and provisioning your resources through definition files or code. IaC allows the user to manage the lifecycle of infrastructure through code, so that the best practices of software development can be applied to infrastructure provisioning and management. Changes are made to definitions and then rolled out to systems through unattended processes that include thorough validation. It provides a centralized way to manage configuration in terms of implementation and version control. It emphasizes consistent, repeatable routines for provisioning and changing systems and their configuration. IaC provides speed, security, precision, and most importantly reproducibility while managing environments. This allows for the quick creation of infrastructure and servers using standardized patterns, easier management of patches and versions, automatic monitoring, and the replacement of faulty infrastructure components.

![](images/Infrastructure-as-code.png)

Infrastructure as Code

There are many benefits in designing infrastructure as code.

- Cost reduction, as you expend a lot less effort on simple and repetitive tasks.
- Speed of execution. Your DevOps team can release infrastructure and services a lot faster than they would have done before.
- Immutable infrastructure, which apply changes by rebuilding resources instead of modifying the existing resources.
- Reduces the risk of errors introduced through manual configuration or user-interface changes.
- Traceability, validation, and testing at each step helps reduce the number of errors and issues. Overall, this helps reduce risks and improves security.

## Principles of IaC

The principles of IaC are

- Systems can be easily reproduced - It should be possible to rebuild any element of the infrastructure effortlessly and reliably. Decisions about which software and versions to install on a server, how to choose a hostname, and so on should be captured in the scripts and tooling that provision it.
- Systems are disposable - Infrastructure resources should be easily created, destroyed, replaced, resized, and moved. Embracing disposable infrastructure can play a key role in improving service continuity
- Systems are consistent - The reproducibility principle above help to easily build multiple identical infrastructure elements. Being able to build and rebuild consistent infrastructure helps with configuration drift.
- Processes are repeatable - Any action you carry out on your infrastructure should be repeatable.
- Design is always changing - Making a change to an existing system should be easy and cheap. The most important measure to ensure that a system can be changed safely and quickly is to make changes frequently. This forces everyone involved to learn good habits for managing changes, to develop efficient, streamlined processes, and to implement tooling that supports doing so.

Puppet, Chef, Ansible, [Cloud formation](https://pradeeploganathan.com/cloud/aws-cloudformation/) and [Terraform](https://pradeeploganathan.com/cloud/terraform-getting-started/) are examples of tools used to author infrastructure as code. The key advantage of using these tools is that any system configuration can be defined in a text file at the design stage and changes can be managed through versioning. Containerization tools such as Docker, Rocket can be used for packaging, distributing, and running applications and processes. Cloud providers offer Infrastructure as Code services, such as [AWS CloudFormation](https://pradeeploganathan.com/cloud/aws-cloudformation/), Azure Resource Manager, and GCP Cloud Deployment Manager. These services manage the resource state and interdependencies automatically. They also facilitate governance and auditing because the service tracks the inventory of stacks and their components. [Terraform](https://pradeeploganathan.com/cloud/terraform-getting-started/) is also an industry standard for managing online resources.

> Photo by [Franck V.](https://unsplash.com/@franckinjapan?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/automation?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
