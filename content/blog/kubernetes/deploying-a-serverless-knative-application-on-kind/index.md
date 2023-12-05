---
title: "Deploying a serverless knative application on kind"
author: "Pradeep Loganathan"
date: 2022-01-21T11:32:59+10:00
lastmod: 2022-01-21T11:32:59+10:00

draft: false
comments: true
toc: true
showToc: true
TocOpen: false

summary: "In this post we will walk through steps to create a Knative serving instance on a local Kind cluster. We will deploy kourier as the networking layer. We will then deploy an application on this cluster and see it scaling up and down"

cover:
  image: "knative.png"
  relative: true
  alt: "Deploying a serverless knative application on kind"
  caption: "Deploying a serverless knative application on kind"

images:
  - cover.jpg
categories:
  - Kubernetes
tags:
  - "knative"
  - "kind"
  - "serverless"

 

---
> The code for this blog post is on github [here.](https://github.com/PradeepLoganathan/install-knative-on-kind-with-kourier)

Knative adds the necessary compoennts for deploying , running and managing serverless applications on Kubernetes. As a developer, I generally prefer to have knative running locally to develop and test my applications. In this blog post we will work through steps to  install knative on a kind cluster locally. We will then install kourier as the networking component. We will then deploy a sample application to test that everything ties up and we can deploy knative applications onto the local cluster. So lets get started.

{{< hugo-giphy-shortcode K5c3azAxtnKlAsO3Jv >}}

## Create the cluster using Kind

We need to initially setup the cluster on Kind. We need to create a cluster configuration manifest to expose port 80 and port 443 on the host. These ports will be needed by the knative kourier ingress. The cluster configuration manifest is below

```yaml
#filename: kind-knative-cluster.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.21.1@sha256:69860bda5563ac81e3c0057d654b5253219618a22ec3a346306239bba8cfa1a6
  extraPortMappings:
  - containerPort: 31080  # expose port 31380 of the node to port 80 on the host, later to be use by kourier ingress
    hostPort: 80
  - containerPort: 31443
    hostPort: 443
```

Create the kind cluster using the above configuration

```shell
kind create cluster --name knative --config kind-knative-cluster.yaml
```

```shell
Creating cluster "knative" ...
 ✓ Ensuring node image (kindest/node:v1.21.1) 🖼 
 ✓ Preparing nodes 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Set kubectl context to "kind-knative"
You can now use your cluster with:

kubectl cluster-info --context kind-knative

Not sure what to do next? 😅  Check out https://kind.sigs.k8s.io/docs/user/quick-start/

```

Check that the cluster is up and running using the below command

```shell
kubectl cluster-info --context kind-knative
```

## Deploy Knative serving components

Now that the cluster is up and running we can install the Knative serving components. We can start off by installing the custom resource definitions (CRD's). I am installing the CRD from the yaml file and also waiting to ensure that all the serving components are installed and running.

```shell
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-crds.yaml

kubectl wait --for=condition=Established --all crd
```

```shell
customresourcedefinition.apiextensions.k8s.io/certificates.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/configurations.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/clusterdomainclaims.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/domainmappings.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/ingresses.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/metrics.autoscaling.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/podautoscalers.autoscaling.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/revisions.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/routes.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/serverlessservices.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/services.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/images.caching.internal.knative.dev created
```

Once the CRD's are deployed, we can deploy the core components on the server. I am again using the yaml files available on github and am waiting for the components to be deployed and running.

```shell
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-core.yaml

kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-serving > /dev/null
```

```shell
namespace/knative-serving created
clusterrole.rbac.authorization.k8s.io/knative-serving-aggregated-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/knative-serving-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-edit created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-view created
clusterrole.rbac.authorization.k8s.io/knative-serving-core created
clusterrole.rbac.authorization.k8s.io/knative-serving-podspecable-binding created
serviceaccount/controller created
clusterrole.rbac.authorization.k8s.io/knative-serving-admin created
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-admin created
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-addressable-resolver created
customresourcedefinition.apiextensions.k8s.io/images.caching.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/certificates.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/configurations.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/clusterdomainclaims.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/domainmappings.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/ingresses.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/metrics.autoscaling.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/podautoscalers.autoscaling.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/revisions.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/routes.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/serverlessservices.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/services.serving.knative.dev unchanged
image.caching.internal.knative.dev/queue-proxy created
configmap/config-autoscaler created
configmap/config-defaults created
configmap/config-deployment created
configmap/config-domain created
configmap/config-features created
configmap/config-gc created
configmap/config-leader-election created
configmap/config-logging created
configmap/config-network created
configmap/config-observability created
configmap/config-tracing created
horizontalpodautoscaler.autoscaling/activator created
Warning: policy/v1beta1 PodDisruptionBudget is deprecated in v1.21+, unavailable in v1.25+; use policy/v1 PodDisruptionBudget
poddisruptionbudget.policy/activator-pdb created
deployment.apps/activator created
service/activator-service created
deployment.apps/autoscaler created
service/autoscaler created
deployment.apps/controller created
service/controller created
deployment.apps/domain-mapping created
deployment.apps/domainmapping-webhook created
service/domainmapping-webhook created
horizontalpodautoscaler.autoscaling/webhook created
poddisruptionbudget.policy/webhook-pdb created
deployment.apps/webhook created
service/webhook created
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.serving.knative.dev created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.serving.knative.dev created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.domainmapping.serving.knative.dev created
secret/domainmapping-webhook-certs created
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.domainmapping.serving.knative.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.serving.knative.dev created
secret/webhook-certs created
```

## Setup Knative serving using Kourier

### Install Kourier
We need to now setup the serving layer for Knative. I am using Kourier as it has the lowest resource requirements and connects to the Knative ingress CRD's directly.

I am installing kourier from the knative repository on github. It also makes sense to wait for the necessary components to be up and running.

```shell
kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.0.0/kourier.yaml

kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n kourier-system

kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-serving
```

```shell
namespace/kourier-system created
configmap/kourier-bootstrap created
configmap/config-kourier created
serviceaccount/net-kourier created
clusterrole.rbac.authorization.k8s.io/net-kourier created
clusterrolebinding.rbac.authorization.k8s.io/net-kourier created
deployment.apps/net-kourier-controller created
service/kourier created
deployment.apps/3scale-kourier-gateway created
service/kourier configured
service/kourier-internal created
```

Kourier is now installed in the `` kourier-system ``  namespace.
Now that Kourier is installed, it sets up a local DNS pointing to 127.0.0.1.nip.io. We can use dig to ensure dns resolution as below.

### Kourier DNS resolution

```shell
EXTERNAL_IP="127.0.0.1"
KNATIVE_DOMAIN="$EXTERNAL_IP.nip.io"
echo KNATIVE_DOMAIN=$KNATIVE_DOMAIN
dig $KNATIVE_DOMAIN
```

Running dig should output the below

```shell
; <<>> DiG 9.16.1-Ubuntu <<>> 127.0.0.1.nip.io
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18981
;; flags: qr rd ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;127.0.0.1.nip.io.              IN      A

;; ANSWER SECTION:
127.0.0.1.nip.io.       0       IN      A       127.0.0.1

;; Query time: 20 msec
;; SERVER: 172.24.112.1#53(172.24.112.1)
;; WHEN: Fri Jan 21 12:04:36 AEST 2022
;; MSG SIZE  rcvd: 66
```

We will need to patch to configure DNS for Knative serving.

```shell
kubectl patch configmap -n knative-serving config-domain -p "{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}"
```

Now that we have setup Kourier as the default networking layer, we can configure it to listen to HTTP port 80 and https port 443 on the node. We can use the below service definition to do so.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kourier-ingress
  namespace: kourier-system
  labels:
    networking.knative.dev/ingress-provider: kourier
spec:
  type: NodePort
  selector:
    app: 3scale-kourier-gateway
  ports:
    - name: http2
      nodePort: 31080
      port: 80
      targetPort: 8080
    - name: https
      nodeport: 31443
      port: 443
      targetport: 8443
```

We can apply the above service by using kubectl

```shell
kubectl apply -f kourier.yaml
```

### Knative Kourier configuration

we can now configure knative to use kourier as below.

```shell
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'
```

Knative deployment is now complete and Kourier has been configured as the networking layer for Knative. All pods in the knative-serving and kourier-system namespaces should be up and running. You can check this as below

```shell
kubectl get pods -n knative-serving
kubectl get pods -n kourier-system
```

```shell
NAME                                      READY   STATUS    RESTARTS   AGE
activator-68b7698d74-x5lfg                1/1     Running   1          2m25s
autoscaler-6c8884d6ff-xtfc9               1/1     Running   1          2m25s
controller-76cf997d95-tsm7c               1/1     Running   1          2m25s
domain-mapping-57fdbf97b-qh7hw            1/1     Running   1          2m25s
domainmapping-webhook-66c5f7d596-5fp92    1/1     Running   1          2m25s
net-kourier-controller-6f68cbb74f-szdnm   1/1     Running   1          2m55m
webhook-7df8fd847b-jdkdg                  1/1     Running   2          2m25s

NAME                                      READY   STATUS    RESTARTS   AGE
3scale-kourier-gateway-77849dcc96-dsxm2   1/1     Running   1          2m55m
```

All pods are up and running. We have now successfully installed Knative on Kind. We have also setup Kourier as the networking layer for Knative.

## Deploy your first Knative app

Now that the Knative cluster and the networking compoenents are all up and running we can now deploy an application onto this cluster. I will be using a knative sample application from this [github repository.](https://github.com/knative-sample/helloworld-go). A container image of this application is [here.](https://console.cloud.google.com/gcr/images/knative-samples/GLOBAL/helloworld-go)

```shell
kn service create hello \
--image gcr.io/knative-samples/helloworld-go \
--port 8080 \
--env TARGET=Knative
```

Once this is done, let us wait for the knative service to be ready as below

```shell
kubectl wait ksvc hello --all --timeout=-1s --for=condition=Ready
```

```shell
service.serving.knative.dev/hello condition met
```

We can get the URL of this service using 

```shell
SERVICE_URL=$(kubectl get ksvc hello -o jsonpath='{.status.url}')
echo $SERVICE_URL
```

```shell
http://hello.default.127.0.0.1.nip.io
```

Let's test the service 

```shell
curl $SERVICE_URL
```

Calling the service produces the below output.

```shell
Hello Knative!
```

We can now check the pods to see how they scale up and scale down based on requests flowing in. I ran the below commands along with running the above curl command in a loop. We can see the containers being created and terminating based on reuests being queued.

```shell
kubectl get pod -l serving.knative.dev/service=hello -w
NAME                                      READY   STATUS    RESTARTS   AGE
hello-00001-deployment-659dfd67fb-gk74w   2/2     Running   0          53s

kubectl get pod -l serving.knative.dev/service=hello -w
NAME                                      READY   STATUS    RESTARTS   AGE
hello-00001-deployment-659dfd67fb-5ps9x   2/2     Running   0          90s
hello-00001-deployment-659dfd67fb-5ps9x   2/2     Terminating   0          2m25s
hello-00001-deployment-659dfd67fb-5ps9x   1/2     Terminating   0          2m27s
hello-00001-deployment-659dfd67fb-wgnkj   0/2     Pending       0          0s
hello-00001-deployment-659dfd67fb-wgnkj   0/2     Pending       0          0s
hello-00001-deployment-659dfd67fb-wgnkj   0/2     ContainerCreating   0          0s
hello-00001-deployment-659dfd67fb-wgnkj   1/2     Running             0          1s
hello-00001-deployment-659dfd67fb-wgnkj   2/2     Running             0          1s
hello-00001-deployment-659dfd67fb-5ps9x   0/2     Terminating         0          2m55s
hello-00001-deployment-659dfd67fb-5ps9x   0/2     Terminating         0          2m56s
hello-00001-deployment-659dfd67fb-5ps9x   0/2     Terminating         0          2m56s

kubectl get pod -l serving.knative.dev/service=hello -w
NAME                                      READY   STATUS    RESTARTS   AGE
hello-00001-deployment-659dfd67fb-5ps9x   2/2     Running   0          90s
hello-00001-deployment-659dfd67fb-5ps9x   2/2     Terminating   0          2m25s
hello-00001-deployment-659dfd67fb-5ps9x   1/2     Terminating   0          2m27s
hello-00001-deployment-659dfd67fb-wgnkj   0/2     Pending       0          0s
hello-00001-deployment-659dfd67fb-wgnkj   0/2     Pending       0          0s
hello-00001-deployment-659dfd67fb-wgnkj   0/2     ContainerCreating   0          0s
hello-00001-deployment-659dfd67fb-wgnkj   1/2     Running             0          1s
hello-00001-deployment-659dfd67fb-wgnkj   2/2     Running             0          1s
hello-00001-deployment-659dfd67fb-5ps9x   0/2     Terminating         0          2m55s
hello-00001-deployment-659dfd67fb-5ps9x   0/2     Terminating         0          2m56s
hello-00001-deployment-659dfd67fb-5ps9x   0/2     Terminating         0          2m56s
hello-00001-deployment-659dfd67fb-wgnkj   2/2     Terminating         0          88s
hello-00001-deployment-659dfd67fb-npmr5   0/2     Pending             0          0s
hello-00001-deployment-659dfd67fb-npmr5   0/2     Pending             0          0s
hello-00001-deployment-659dfd67fb-npmr5   0/2     ContainerCreating   0          0s
hello-00001-deployment-659dfd67fb-npmr5   1/2     Running             0          2s
hello-00001-deployment-659dfd67fb-npmr5   2/2     Running             0          2s
hello-00001-deployment-659dfd67fb-wgnkj   1/2     Terminating         0          90s
```

Now we have a sample Knative application deployed locally on kind, using Kourier as the networking layer. We can see containers being dynamically created and terminated based on requests being queued.
