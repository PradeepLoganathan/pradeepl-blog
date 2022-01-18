---
title: "Kubernetes Gatekeeper – An introduction"
lastmod: 2022-01-07T15:55:13+10:00
date: 2022-01-07T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - Gatekeeper
  - OPA
  - Kubernetes
categories:
  - Kubernetes
#slug: kubernetes/kubernetes-opa-gatekeeper-an-introduction/
summary: Gatekeeper is a Kubernetes-native policy controller that enables resource validation and audit functionality for a Kubernetes cluster. It is an open-source customizable Kubernetes admission webhook used for cluster policy administration and governance.
ShowToc: true
TocOpen: false
images:
  - rafael-hoyos-weht-FnabIfupjwo-unsplash.jpg
cover:
    image: "rafael-hoyos-weht-FnabIfupjwo-unsplash.jpg"
    alt: "Kubernetes Gatekeeper – An introduction"
    caption: "Kubernetes Gatekeeper – An introduction"
    relative: false # To use relative path for cover image, used in hugo Page-bundles
---


## Introduction

[Gatekeeper](https://github.com/open-policy-agent/gatekeeper) is a Kubernetes-native policy controller that enables resource validation and audit functionality for a Kubernetes cluster. It is an open-source customizable [Kubernetes admission webhook](https://pradeepl.com/blog/kubernetes/introduction-to-kubernetes-admission-controllers/) used for cluster policy administration and governance. It evaluates Kubernetes resource creation/modification requests against defined policies to determine whether to allow or deny a Kubernetes resource from being created, modified, or deleted. The policy evaluation happens on the server-side as the API request flows through the Kubernetes API server. This ensures that there is a single centralized point of policy evaluation per cluster. It uses [Open Policy Agent (OPA)](https://pradeepl.com/blog/kubernetes/introduction-to-open-policy-agent-opa/) for policy definition and evaluation.

Gatekeeper uses the OPA constraint framework to create custom resource definition (CRD)-based policies. Using CRDs provides a Kubernetes native experience, allows for separation of concerns, and decouples policy authoring from policy implementation. Policy authors can create policy templates which are referred to as constraint templates. The constraint template models the policy definition. These constraint templates can be shared and reused across clusters. Constraints are implemented using constraint templates. These constraints implement and enforce the policies defined by the constraint templates. Gatekeeper uses these constraints to enable resource validation and audit functionality. Gatekeeper can be implemented in any Kubernetes cluster.

## Gatekeeper Components

Gatekeeper is primarily composed of three parts:

* A webhook server and a generic ValidatingWebhookConfiguration that is deployed to the Kubernetes cluster
* A constraint template, which describes the admission control policy.
* One or many constraints based on the constraint templates created in the previous step.

This design allows for a flexible approach separating policy definition and policy implementation. This design enables us for example, to build a template for the policy “all namespaces must have the necessary mandatory labels” and then deploy a constraint to implement “all namespaces must have a costcenter label”. Using a template-based approach allows for parameterization of the policy template. This enables a single constraint template to be used across multiple clusters. Using the previous example, we can parameterize the template to specify that all pods must have a cost center label. We can also implement another constraint using the same template to specify that all pods must have an environment label. Let us look at these various components of Gatekeeper in further detail.

### Constraint Template

A constraint template models the policy definition as a template. The constraint template uses rego to define the policy. The rego code is stored in the template. Creating the policy definition as a template allows for parameterization as the rego defined in the template can also be parameterized. This allows the constraint template to be portable and reusable across multiple clusters. Constraint templates are testable and can be internally developed or community-sourced. [This](https://github.com/open-policy-agent/gatekeeper-library) [repo](https://github.com/open-policy-agent/gatekeeper-library/tree/master/src/general) contains several community defined constraint templates covering different policies. Constraint templates are created as custom resource definitions that are persisted in the cluster. They are applied using constraint objects.

### Defining Constraint Templates

A constraint template is a custom resource definition (CRD) and follows the standard Kubernetes CRD specification defined [here](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions). They can be defined using YAML and deployed using Kubectl. Let us create a constraint template defining a policy that enforces labels that need to be present on resources created in the cluster. This template can be parameterized so that the labels that need to be enforced can be defined per cluster and are not hardcoded in the policy definition template. This allows for the policy definition in the template to be abstracted away from the policy implementation in the constraint.

The constraint template to implement the above policy can be defined as below

```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: clusterrequiredlabels
  annotations:
   description: "Constraint to enforce required labels"
spec:
  crd:
    spec:
      names:
        kind: ClusterRequiredLabels
      validation:
        # Schema defn for 'parameters' field
        openAPIV3Schema:
          properties:
            labels:
              type: array
              items: 
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package clusterrequiredlabels

        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("you must provide labels: %v", [missing])
        }     
```

Let us understand the above constraint template definition in detail. It is composed of three main parts.

1. Kubernetes required CRD metadata. This constraint template specifies an `apiVersion` and `kind` that are part of the custom resources used by Gatekeeper. The `spec.crd.spec` block defines the custom resource definition of the constraint type. The `names` field sets the resource type’s name.
2. Schema definition for input parameters. This is defined by the `validation` field. This field is optional. It is used to define the input parameters field names and types using an openapi V3 schema. In the above template we have a single parameter called labels that is an array of string. This parameter is used to define the labels that are required to be specified by the Kubernetes resource creation or update request.
3. The policy definition. The `spec.targets` field defines the policy rego code. The rego code checks the input array specified in the kubectl command and reviews the labels array. If the provided labels array does not contain the required labels, it throws a violation. The msg section specifies the message that is sent back to the user when the policy is violated.

### Constraint

A constraint is an instance of the constraint template. It supplies the constraint template with parameters if any. To use the constraint template defined above we need to create and deploy a constraint resource. This constraint resource can be used to pass the parameters defined by the constraint template to be checked against the policy defined in it.

### Defining Constraints

Let us now create a constraint resource to implement the constraint template defined above. The constraint template checks for the presence of required labels on the Kubernetes resources being created. We can use this constraint template to ensure that any namespace created has a costcenter label. The constraint resource is defined as below

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: ClusterRequiredLabels
metadata:
  name: costcenterlabelrequired
  annotations:
    description: "Constraint to enforce required labels"
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels: ["costcenter"]
```

The constraint CRD is composed of two main parts

* Kubernetes metadata – The constraint template and the constraint are linked by specifying the constraint template name in the constraint `kind`. In this case the constraint kind specifies ClusterRequiredLabels which links it to the above constraint template.
* The Spec – In the spec the `` `match` `` field defines the scope of the constraint. In this case we are limiting this constraint to namespaces. We are passing in the required labels as a string array into the constraint template. In this case we are passing in a single string “costcenter” which is the required label. We can similarly define another constraint CRD to specify other labels as the required.

We can use the same constraint template to define another constraint specifying environment as a required label. The constraint definition is below

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: ClusterRequiredLabels
metadata:
  name: costcenterlabelrequired
  annotations:
    description: "Constraint to enforce required labels"
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels: ["environment"]
```

The above constraints can be used to ensure that namespaces created in a cluster have the necessary labels. The constraints are parameterized and are portable. They can be tested easily as they use rego to define the policy.

## Platform implementations

Open Policy Agent/Gatekeeper is extensively used by many platforms to implement policy implementation, policy governance and best practices. [VMWare’s Tanzu Mission Control](https://tanzu.vmware.com/content/blog/vmware-tanzu-mission-control-expands-its-policy-management-capabilities) (TMC) uses OPA/Gatekeeper as the underlying mechanism to define, deploy, and ensure security and compliance across cluster fleets. This enables centralized management and supporting best practices across hundreds of clusters. TMC provides a bunch of predefined constraint templates for a wide variety of policy types, including access, image, network, and quota policies. [Azure policy](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes) extends gatekeeper to offer centralized, consistent policy management across AKS clusters.

In the [next blog post](https://pradeepl.com/blog/kubernetes/deploying-gatekeeper-and-defining-constraints/) we will look at deploying gatekeeper to a kubernetens cluster, defining constraints and applying constraints to a cluster.
