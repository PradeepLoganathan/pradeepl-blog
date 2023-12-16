---
title: "AWS CloudFormation"
date: "2019-07-26"
categories: 
  - "cloud"
---

## Introduction

AWS CloudFormation is an [Infrastructure as Code (IaC)]({{< ref "/blog/infrastructure-as-code">}}) tool for specifying resources in a declarative way. It is an alternative to using the AWS console, CLI, or various SDKs for deploying your AWS infrastructure. This service helps in creating and managing a collection of related AWS resources. The service is organized around the concept of templates & stacks. A cloudformation template typically describes a set of AWS resources and their configuration in order to start an application. We can create templates to describe AWS resources and any associated dependencies or runtime parameters required to run your application. In addition to provisioning AWS resources, CloudFormation can also be used to update them in an orderly and predictable manner. Terraform is an alternative to cloudformation. Configuration management tools such as Ansible and Puppet also include support for deploying AWS resources.

## Benefits

The benefits of CloudFormation are

- Consistency - It’s provides a consistent way to describe infrastructure on AWS. CloudFormation templates are a clear, well defined language to define infrastructure.

- Dependency management - It can handle dependencies between resources.

- Replicable - Using CloudFormation, you can create two identical environments and keep them in sync. This is especially useful when managing multiple environments or when we need to create an exact copy of an existing environment quickly.

- Customizable - You can insert custom parameters into CloudFormation templates to customize stack creation.

- Testable - Your infrastructure is testable if you can create it from a template. Just start a new infrastructure, run your tests, and shut it down again.

- Updatable - CloudFormation supports updates to your infrastructure. It will figure out the parts of the template that have changed and apply those changes as smoothly as possible to your infrastructure.

- Minimizes human Error - CloudFormation doesn’t get tired—even at 2 in the morning.

- Infrastructure Documentation - A CloudFormation template is a JSON/YAML document. You can treat it as code and use a version control system like Git to keep track of the changes.

- Cost - It’s free. CloudFormation comes at no additional charge.

## CloudFormation Template

A CloudFormation template is used to define one or more resources. A resource can be a S3 bucket, an IAM role, a Lambda function etc. A CloudFormation template is a convenient mechanism to group related resources in a single place. When you deploy your template, CloudFormation will create a stack that comprises the physical resources defined in your template. CloudFormation will deploy each resource, automatically determining any dependencies between each resource, and optimise the deployment so that resources can be deployed in parallel where applicable, or in the correct sequence when there are dependencies between resources.

The CloudFormation template is an extended data structure that you write using JSON or YAML. CloudFormation also has a visual designer to help lay out your planned infrastructure. The cloudformation template can be version controlled. A CloudFormation file is composed of the following sections:

```json
{
  "AWSTemplateFormatVersion": "version date",
  "Description": "Description",
  "Resources": {
    
  },
  "Parameters": {
    
  },
  "Mappings": {
    
  },
  "Conditions": {
    
  },
  "Metadata": {
    
  },
  "Outputs": {
    
  }
}
```
Cloudformation file structure

A brief description of each of the sections in the above template are listed here

- AWSTemplateFormatVersion: "version date". This is currently always 2010-09-09 and this represents the version of the template language used.

- Description: Description about the stack being created by the template. This section allows you to include some details or comments about the template.

- Resources: Resource definitions, this is the only required section.  This section describes which AWS services will be instantiated and their configurations. All resources must specify a Type property, which defines the type of resource and determines the various configuration properties available for each type.

- Parameters: Input parameters to configure the stack when launching a template. The Parameters property defines a set of input parameters that you can supply to your template. This is an ideal way to deal with multiple environments where you may have different input values between each environment.

- Mappings: Data mappings definitions . Useful when creating a generic template.

- Conditions: Setup conditions to setup resources or configuration using if conditions, logical operators etc.

- Metadata: Additional data about the template, also useful to group parameters on the UI

- Output: Section to output data, you can use it return the specific pieces of information from resources created using the template for e.g the URN of an SQS queue, Name of the S3 bucket etc.

The [CloudFormation user guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) describes the template structure in great detail. A very simple cloudformation template to create a S3 bucket is below.

```yaml
Resources:
  MyS3Bucket:
    Type: AWS::S3::Bucket
Outputs:
  BucketName:
    Value:
      Ref: MyS3Bucket
```

Simple Cloudformation template

Another simple cloudformation template to create an SQS queue is below. This cloudformation template uses outputs

```yaml
Resources:
  SQSQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: my-sqsqueue

Output:
  SQSQueueURL:
    Value: !Ref SQSQueue
    Export:
      Name: "SQSQueueURL"
  SQSQueueArn:
    Value: !GetAtt SQSQueue.Arn
    Export:
      Name: "SQSQueueArn"

```

SQS Queue- Cloudformation

## Cloudformation Stack

A stack is a set of resources that's created by a cloudformation template. When a template is launched to create resources, it is called a stack. A stack can represent a complete application or a part of the resources that are deployed from a specific template. For example, we can use separate stacks to create separate layers of our application ( Application layer and database layer as different stacks ). These can be deployed by separate teams, and these teams are hence able to maintain the segregation of duties, even when working in the cloud.

We can also specify stacks as part of templates, hence sort of nesting stacks within stacks. Supplying nested stacks allows us to create dependencies on complete stacks. For example, we would not want to deploy an EC2 stack before the VPC stack completes as there would be no VPC to deploy into and server stack creation would fail.

Once we provide a template to the CloudFormation service, the service stores that template in an S3 bucket. The template is analyzed for the correct syntax and, if the syntax is correct, the parameters are verified against the AWS account. If any of these are not correct, the CloudFormation service will throw an error before it begins the deployment of resources. If the syntax and parameter check passes, the service will initiate creation. It simultaneously reads the inputs in the template and processes them in parallel. We have to take this into consideration whenever we have resources that need to be created in sequence.

## Creating a CloudFormation stack

We can use the AWS CLI to create a cloudformation stack from a cloudformation template. In the below example I am using the create-stack command to create a stack from the [**simplecloudformationtemplate.yml**](https://gist.github.com/PradeepLoganathan/11601ed88d6b9e28ee0c9335917108e9#file-simplecloudformationtemplate-yml) template.


```shell
aws cloudformation create-stack --region ap-southeast-2 --stack-name helloworldstack --template-body file://./simplecloudformationtemplate.yml
```

Running the above command outputs a stackid as below

```shell
"StackId": "arn:aws:cloudformation:ap-southeast-2:090848583068:stack/helloworldstack/20ff2a70-af87-11e9-80b2-0613a29612d8"
```

We can use the command ```aws cloudformation list-stacks``` to list all stacks. The stack created above is listed using the command as below

```shell
"StackSummaries": \[  
{  
  "StackId": "arn:aws:cloudformation:ap-southeast-2:090848583068:stack/helloworldstack/20ff2a70-af87-11e9-80b2-0613a29612d8",  
  "StackName": "helloworldstack",  
  "CreationTime": "2019-07-26T09:24:12.065Z",  
  "StackStatus": "CREATE\_COMPLETE",  
  "DriftInformation": {  
  "StackDriftStatus": "NOT\_CHECKED"  
}
```
We can delete the stack, along with all its resources, using the below command. This command will clean up all resources created as part of the stack.

```shell
$ aws cloudformation delete-stack --region ap-southeast-2 --stack-name helloworldstack
```

While all of the above can be achieved by using the AWS CLI tools or the console , Cloudformation automates and provides other key capabilities, make it a key service to build infrastructure on the cloud.
