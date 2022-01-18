---
title: "Deploying gatekeeper to a kubernetes cluster and defining constraints"
lastmod: 2022-01-07T15:55:13+10:00
date: 2022-01-07T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - gatekeeper
  - Kubernetes
  - "admission controllers"
categories:
  - Kubernetes
#slug: kubernetes/introduction-to-kubernetes-admission-controllers/
summary: In this post we will deploy gatekeeper to a kubernetes cluster. We will then define constraints and ensure that gatekeeper enforces those constraints.
ShowToc: true
TocOpen: false
images:
  - Shaniwar-wada.png
cover:
    image: "Shaniwar-wada.png"
    alt: "Deploying gatekeeper to a kubernetes cluster and defining constraints"
    caption: "Deploying gatekeeper to a kubernetes cluster and defining constraints"
    relative: false # To use relative path for cover image, used in hugo Page-bundles
editPost:
  URL: "https://github.com/PradeepLoganathan/pradeepl-blog/tree/master/content"
  Text: "Edit this post on github" # edit text
  appendFilePath: true # to append file path to Edit link
---

This blog post is a follow up to my [previous post](https://pradeepl.com/blog/kubernetes/kubernetes-gatekeeper-an-introduction/) introducing policy management and implementation using gatekeeper. In this post we will look at deploying gatekeeper, creating policies using constraints and constraint templates. We will create a constraint and test the same. To get started, let us create a cluster locally.

## Create Cluster

Create a Kubernetes cluster locally using kind. I am creating a cluster named gatekeepercluster as below.

```shell
kind create cluster --name gatekeepercluster
```

After the cluster has been created, we can now deploy gatekeeper.

## Deploy Gatekeeper

Gatekeeper can be installed into your cluster by directly applying the manifest or by using a helm package. The installation details are listed [here](https://open-policy-agent.github.io/gatekeeper/website/docs/install/)). While I do not advocate using manifest files directly from online sources, we can safely do so for this blog post. I am installing version 3.7 of gatekeeper into the cluster using the manifest.

```shell
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.7/deploy/gatekeeper.yaml
```

This command produces the output below.

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
kubectl -n gatekeeper-system wait --for=condition=Ready --timeout=600s pod -lgatekeeper.sh/operation=webhook
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

Now that we have confirmed that all the gatekeeper components are up and running, let us create a constraint template and implement a constraint.

## ConstraintTemplate

One of the policies that I have seen being applied in many clusters is the ability to pull images only from specific registries. This template is from the demo repository of Open Policy agent. This policy enables the creation of an allowlist for repositories ensuring that workloads do not pull images from unsafe repositories. Let’s get started on creating a constraint template to enable this.

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
          satisfied := [good | repo = input.parameters.repos[_] ; good = contains(container.image, repo)]
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

This container template checks containers being created and indicates a violation, if the containers have an image repository which is not part of the allow list. I have authored a [blog post](https://pradeepl.com/kubernetes/introduction-to-open-policy-agent-opa/#REGO) to help understand rego. In this template the rego code at line 24 extracts the container spec. It then checks if `` `container.image` `` contains any of the repos specified by the `` `input.parameters.repo` `` array in line 25 and assigns the value to satisfied. If satisfied is not set, we know that the image was not pulled from the list of allowed repositories. The allowed list of repositories is passed in as a parameter as specified in line 14. The list of repositories is passed in as an array of strings. This is indicated by the data type of the parameter in line 15. Now that we have created the constraint template let us deploy it to the cluster.

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

We can use spec.match to specify the kubernetes resources to which the constraint applies. In the constraint above at line we specify that the constraint applies to pods created in the myapp namespace.

## Apply Constraint

```shell
kubectl apply --filename ClusterAllowedRepos-Constraint.yaml
```

## Check for Violations

```yaml
> kubectl describe latestimage not-allowed
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

## Test the policy enforcement

```shell
> kubectl run nginx --image nginx:latest
Error from server ([not-allowed] container <nginx> uses an image tagged with latest<nginx:latest>. Do not use latest. Use a specific version number.): admission webhook"validation.gatekeeper.sh" denied the request: [not-allowed] container <nginx> usesan image tagged with latest <nginx:latest>. Do not use latest. Use a specific versionnumber.
```
