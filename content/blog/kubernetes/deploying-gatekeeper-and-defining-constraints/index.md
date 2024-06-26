---
title: "Deploying OPA Gatekeeper and defining constraints"
lastmod: 2022-01-07T15:55:13+10:00
date: 2022-01-07T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - gatekeeper
  - Kubernetes
  - "admission controllers"
  - Policy
  - hardening
categories:
  - Kubernetes
  - security
  - policy

summary: In this post we will deploy gatekeeper to a kubernetes cluster. We will then define constraints and ensure that gatekeeper enforces those constraints.
ShowToc: true
TocOpen: open
images:
  - images/gatekeeper-opa.png
cover:
    image: "images/gatekeeper-opa.png"
    alt: "Deploying gatekeeper to a kubernetes cluster and defining constraints"
    caption: "Deploying gatekeeper to a kubernetes cluster and defining constraints"
    relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---

This blog post is a follow up to my [previous post]({{< ref "/blog/kubernetes/opa-gatekeeper">}}) introducing policy management and implementation using gatekeeper. In this post we will look at deploying gatekeeper, creating policies using constraints and constraint templates. We will create a constraint and test the same. To get started, let us create a cluster. We can deploy Gatekeeper to any kubernetes cluster on cloud providers or on premises. For this blog post , I am using Kind to create a cluster locally.

# Getting Started

We need to first create the cluster and install gatekeeper to get started.

## Create Cluster

Create a Kubernetes cluster locally using kind. I am creating a cluster named gatekeepercluster as below.

```shell
kind create cluster --name gatekeepercluster
```

We can now deploy gatekeeper into this cluster now that it has been created.

## Install OPA Gatekeeper

OPA Gatekeeper can be installed into your cluster by directly applying a manifest or by using a helm package. The installation details are listed [here](https://open-policy-agent.github.io/gatekeeper/website/docs/install/)). While I do not advocate using manifest files directly from online sources, we can safely do so for this blog post. I am installing version 3.7 of gatekeeper into the cluster using the manifest.

```shell
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.7/deploy/gatekeeper.yaml
```

This command produces the output below. It confirms that the necessary CRD's, mutating/validating webhooks, and admission controllers have been created.

```shell
namespace/gatekeeper-system created
resourcequota/gatekeeper-critical-pods created
customresourcedefinition.apiextensions.k8s.io/assign.mutations.gatekeeper.sh created
customresourcedefinition.apiextensions.k8s.io/assignmetadata.mutations.gatekeeper.shcreated
customresourcedefinition.apiextensions.k8s.io/configs.config.gatekeeper.sh created
customresourcedefinition.apiextensions.k8s.io/constraintpodstatuses.status.gatekeepersh created
customresourcedefinition.apiextensions.k8s.io/constrainttemplatepodstatuses.statusgatekeeper.sh created
customresourcedefinition.apiextensions.k8s.io/constrainttemplates.templatesgatekeeper.sh created
customresourcedefinition.apiextensions.k8s.io/modifyset.mutations.gatekeeper.shcreated
customresourcedefinition.apiextensions.k8s.io/mutatorpodstatuses.status.gatekeeper.shcreated
customresourcedefinition.apiextensions.k8s.io/providers.externaldata.gatekeeper.shcreated
serviceaccount/gatekeeper-admin created
Warning: policy/v1beta1 PodSecurityPolicy is deprecated in v1.21+, unavailable in v125+
podsecuritypolicy.policy/gatekeeper-admin created
role.rbac.authorization.k8s.io/gatekeeper-manager-role created
clusterrole.rbac.authorization.k8s.io/gatekeeper-manager-role created
rolebinding.rbac.authorization.k8s.io/gatekeeper-manager-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/gatekeeper-manager-rolebinding created
secret/gatekeeper-webhook-server-cert created
service/gatekeeper-webhook-service created
deployment.apps/gatekeeper-audit created
deployment.apps/gatekeeper-controller-manager created
Warning: policy/v1beta1 PodDisruptionBudget is deprecated in v1.21+, unavailable inv1.25+; use policy/v1 PodDisruptionBudget
poddisruptionbudget.policy/gatekeeper-controller-manager created
mutatingwebhookconfiguration.admissionregistration.k8s.iogatekeeper-mutating-webhook-configuration created
validatingwebhookconfiguration.admissionregistration.k8s.iogatekeeper-validating-webhook-configuration created
```

## Verify OPA Gatekeeper Installation

Now that the installation is complete, we can verify the deployment by checking if the necessary namespaces and pods are created and running.

```shell
kubectl get namespaces
```

This command produces the output below.

```shell
NAME                 STATUS   AGE
default              Active   27m
gatekeeper-system    Active   3m21s
kube-node-lease      Active   27m
kube-public          Active   27m
kube-system          Active   27m
local-path-storage   Active   27m
```

Gatekeeper installs all required components into a namespace called gatekeeper-system. We can see that the gatekeeper namespace has been created. We can check for pods running in this namespace.

```shell
kubectl get pods --namespace gatekeeper-system
```

This command produces the following output

```shell
NAME                                             READY   STATUS    RESTARTS   AGE
gatekeeper-audit-59d4b6fd4c-w89nm                1/1     Running   0          4m4s
gatekeeper-controller-manager-66f474f785-m8944   1/1     Running   0          4m3s
gatekeeper-controller-manager-66f474f785-p8msx   1/1     Running   0          4m4s
gatekeeper-controller-manager-66f474f785-vfzzb   1/1     Running   0          4m3s
```

We can see above that the gatekeeper-system namespace has been created and the necessary pods in the namespace are up and running. We now have a cluster with gatekeeper deployed successfully.

We can also check to see if the webhook that gatekeeper uses to listen to the API server events has been deployed

```shell
kubectl get validatingwebhookconfigurations
```

This command produces the below output confirming the presence of the webhook in the cluster.

```shell
NAME                                          WEBHOOKS   AGE
gatekeeper-validating-webhook-configuration   2          50s
```

Now we have deployed gatekeeper successfully. I have run into issues where it has taken some time for the gatekeeper components to be installed and any resource creation request fails as the webhook is still in the process of being deployed. This results in the below error

```shell
Error from server (InternalError): Internal error occurred: failed calling webhook"check-ignore-label.gatekeeper.sh": Post "https://gatekeeper-webhook-servicegatekeeper-system.svc:443/v1/admitlabel?timeout=3s": dial tcp 10.96.33.109:443:connect: connection refused
```

It is always better to wait for the components to be successfully created. We can do so using the Kubectl wait commands as below

```shell
kubectl wait --for=condition=available --timeout=600s deployment -n gatekeeper-system--all
kubectl -n gatekeeper-system wait --for=condition=Ready --timeout=600s pod -l gatekeeper.sh/operation=webhook
```

These commands confirm that all the necessary gatekeeper components have been created as seen in the below output

```shell
deployment.apps/gatekeeper-audit condition met
deployment.apps/gatekeeper-controller-manager condition met
pod/gatekeeper-controller-manager-66f474f785-dxrqw condition met
pod/gatekeeper-controller-manager-66f474f785-kkqdc condition met
pod/gatekeeper-controller-manager-66f474f785-klsz2 condition metdeployment.appsgatekeeper-audit condition met
deployment.apps/gatekeeper-controller-manager condition met
pod/gatekeeper-controller-manager-66f474f785-dxrqw condition met
pod/gatekeeper-controller-manager-66f474f785-kkqdc condition met
pod/gatekeeper-controller-manager-66f474f785-klsz2 condition met
```

Now that we have confirmed that all the gatekeeper components are up and running, let us create a [constraint template]({{< ref "/blog/kubernetes/opa-gatekeeper#constraint-template" >}}) and implement a [constraint]({{< ref "/blog/kubernetes/opa-gatekeeper#constraint" >}}).

# Creating and Implementing Constraints

We have successfully created a cluster, deployed opa gatekeeper and verified that all the components are working fine. We can now go onto defining a constraint template and implementing a constraint in our cluster.

## ConstraintTemplate

One of the policies that I have seen being applied in many clusters is the ability to pull images only from specific registries. This is a compliance policy which ensures that only vetted images are deployed into the cluster. It ensures that workloads do not use insecure images. Insecure images can result in a lot of issues including exfiltration of confidential data from workloads. This constraint template below is from the demo repository of Open Policy agent. This constraint template creates an allowlist of repositories ensuring that workloads do not pull images from unsafe repositories. Let’s get started on creating a constraint template to enable this.

```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: allowedrepos
spec:
  crd:
    spec:
      names:
        kind: AllowedRepos
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          properties:
            repos:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package allowedrepos
  
        violation[{"msg": msg}] {
            container := input.review.object.spec.containers[_]
            satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
            not any(satisfied)
            msg := sprintf("container <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
          }
  
        violation[{"msg": msg}] {
          container := input.review.object.spec.initContainers[_]
          satisfied := [good | repo = input.parameters.repos[_] ; good = contains(container.image, repo)]
          not any(satisfied)
          msg := sprintf("container <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
        } 
```

This container template validates all containers being created. If the containers have an image repository which is not part of the allow list of repositories it flags a violation. The allowed list of container repositories is passed in as a template parameter. It uses Rego policy language to specify the validation policy . I have authored a [blog post]({{< ref "/blog/kubernetes/open-policy-agent-opa#REGO" >}}) providing an introduction to rego. In this template the rego code extracts the container spec. It then checks if `` container.image `` contains any of the repos specified by the `` input.parameters.repo `` array and assigns the value to satisfied. If `` satisfied `` is not set, we know that the image was not pulled from the list of allowed repositories. The allowed list of repositories is passed in as a parameter as specified in line 14. The list of repositories is passed in as an array of strings. This is indicated by the data type of the parameter in line 15. Now that we have created the constraint template let us deploy it to the cluster.

## Apply Constraint Template

```shell
kubectl apply --f ClusterAllowedRepos.yaml
```

This deploys the constraint template as a custom resource into the cluster. We now use this template to create one to many constraint resources.

## Create Constraint

We can now create a constraint which implements the constraint template defined above.

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AllowedRepos
metadata:
  name: repo-is-openpolicyagent
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces:
      - "myapp"
  parameters:
    repos:
      - "mysecurerepo/"
```

We can use spec.match to specify the kubernetes resources to which the constraint applies. In the constraint above, we specify that the constraint applies to pods created in the myapp namespace. We use the ```spec.match.kinds``` to indicate that the constraint applies to all pods. We also pass the repo parameter to be matched against using  ```spec.parameters.repos```.

## Apply Constraint

We can now apply this constraint to the cluster using kubectl.

```shell
kubectl apply --filename ClusterAllowedRepos-Constraint.yaml
```

So far we have created a ConstraintTemplate which implements the logic for Constraint validation using rego. We then created an instance of this ConstraintTemplate by creating a Constraint object and passing in the necessary parameters. We now have all the building blocks to ensure that we can validate constraints on the kubernetes cluster. We can verify that the Constraint exists on the cluster by describing it as below.

```yaml
$ kubectl describe latestimage not-allowed
Name:         not-allowed
Namespace:
Labels:       <none>
Annotations:  <none>
API Version:  constraints.gatekeeper.sh/v1beta1
Kind:         LatestImage
Metadata:
  Creation Timestamp:  2021-12-14T00:24:59Z
  Generation:          1
  Managed Fields:
    API Version:  constraints.gatekeeper.sh/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
    Manager:      gatekeeper
    Operation:    Update
    Time:         2021-12-14T00:24:59Z
    API Version:  constraints.gatekeeper.sh/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        .:
        f:enforcementAction:
        f:match:
          .:
          f:kinds:
    Manager:         kubectl-client-side-apply
    Operation:       Update
    Time:            2021-12-14T00:24:59Z
  Resource Version:  117499
  UID:               53573f6f-cfad-42cf-8737-38d703d3483c
Spec:
  Enforcement Action:  dryrun
  Match:
    Kinds:
      API Groups:

      Kinds:
        Pod
Status:
  Audit Timestamp:  2021-12-14T00:26:52Z
  By Pod:
    Constraint UID:       53573f6f-cfad-42cf-8737-38d703d3483c
    Enforced:             true
    Id:                   gatekeeper-audit-59d4b6fd4c-w89nm
    Observed Generation:  1
    Operations:
      audit
      status
    Constraint UID:       53573f6f-cfad-42cf-8737-38d703d3483c
    Enforced:             true
    Id:                   gatekeeper-controller-manager-66f474f785-m8944
    Observed Generation:  1
    Operations:
      mutation-webhook
      webhook
    Constraint UID:       53573f6f-cfad-42cf-8737-38d703d3483c
    Enforced:             true
    Id:                   gatekeeper-controller-manager-66f474f785-p8msx
    Observed Generation:  1
    Operations:
      mutation-webhook
      webhook
    Constraint UID:       53573f6f-cfad-42cf-8737-38d703d3483c
    Enforced:             true
    Id:                   gatekeeper-controller-manager-66f474f785-vfzzb
    Observed Generation:  1
    Operations:
      mutation-webhook
      webhook
  Total Violations:  0
```

We are now ready to ensure that we can use the Constraint to validate container creation requests and ensure that they use container images from whitelisted repositories.

## Test  policy enforcement

To test the constraint created above, we can try and create a pod in the myapp namespace. We need to create the namespace initially as below.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
  labels:
   name: myapp
```

We can now create a pod definition that will be used to create a container.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: myapp
spec:
  containers:
  - image: busybox:1.28.4
    name: mybusy
    command: ["/bin/sh","-c","sleep 100000"]
```

If we now try to create the pod above it will fail the constraint and will not be allowed to be created.

```shell
$ kubectl apply -f test-pod.yaml
Error from server :  admission webhook "validation.gatekeeper.sh" denied the request: pod "test-pod" has an invalid image repo, allowed repos are ["mysecurerepo"]
```

# Conclusion

OPA Gatekeeper is a great toolset to define and enforce policies. OPA provides an open source engine to author declarative policies as code using rego and Gatekeeper uses these policies to enable resource validation and audit functionality in kubernetes clusters. The ability to create Clustertemplates enables policy reuse and parameterization. This allows operators to create policies to enforce regulatory and compliance requirements and validate them continuously.