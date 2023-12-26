---
title: "Kpack - Streamlining Container Builds in Kubernetes"
author: "Pradeep Loganathan"
date: 2023-12-06T10:17:38+10:00

draft: false
comments: true
toc: true
showToc: true
TocOpen: true

description: ""

cover:
    image: "images/kpack.png"
    relative: true

images:

mermaid: true

tags:
  - "kpack"
  - "CI/CD"
  - "buildpacks"
---
### Source Code

If you wish to follow along with the code used in this post, you can find it [on GitHub here](https://github.com/PradeepLoganathan/KpackKata).

# Kpack - Kubernetes native Buildpacks

Kpack is a Kubernetes-native build service that utilizes [Cloud Native Buildpacks]({{< ref "/blog/kubernetes/cloudnativebuildpacks" >}}) to transform application source code into OCI compliant container images. Kpack extends Kubernetes by creating new custom resources that implement CNB concepts for image configuration, builders, buildpacks and others. These CRDs allow users to define and manage Kpack resources using the kubernetes native declarative api. It fits seamlessly into the Kubernetes ecosystem, making it easier to integrate with existing Kubernetes-based workflows and tools.

Kpack offers several significant benefits for developing modern applications. It automates the image building process, which is essential for CI/CD pipelines. It automatically rebuilds images when it detects changes in the source code reducing manual intervention. It also automatically rebuilds images when it detects changes to the base images or buildpacks. This ensures that images are up-to-date and secure. It does this through automated [builder]({{< ref "/blog/kubernetes/cloudnativebuildpacks#buildpacks" >}}) updates. This ensures that the latest patches and updates are included in the base images, thus mitigating any newly identified vulnerabilities. 


# Kpack components and architecture

Kpack's architecture is designed to leverage Kubernetes features and resources, integrating seamlessly into a Kubernetes environment. It defines custom resource definitions(CRD) that implement cloud native buildpack concepts in kubernetes natively. It also defines custom operators to manage these custom resources. Let us take a look at each of these custom resources and how they are composed to achieve seamless image builds.

## ClusterStack 

The ClusterStack is a custom resource that provides the build and runtime base images used in the process of building container images. It can be considered as the kpack implementation of the [CNB stack]({{< ref "/blog/kubernetes/cloudnativebuildpacks#stack" >}})

It consists of two essential components: 
1. Build image - This is the base image used during the build phase. It contains the build-time dependencies and environment needed to compile or prepare your application. For example, for a Java application, the build image might contain the JDK and build tools like Maven or Gradle. 
2. Run image. This is the base image used for the runtime environment of your application. It is leaner than the build image and contains only the runtime dependencies. For instance, for a Java application, the run image might only contain the JRE.

```yaml
apiVersion: kpack.io/v1alpha2
kind: ClusterStack
metadata:
  name: base
spec:
  id: "io.buildpacks.stacks.jammy"
  buildImage:
    image: "paketobuildpacks/build-jammy-base"
  runImage:
    image: "paketobuildpacks/run-jammy-base"
```

## ClusterBuilder

A ClusterBuilder is a custom resource that specifies the set of buildpacks and the stack to be used for building container images across the Kubernetes cluster. It combines buildpacks and stacks to define how source code should be built into container images. It allows for flexible and consistent image building strategies, ensuring that applications are built efficiently and securely.

A ClusterBuilder consists of:

1. Stack: The ClusterBuilder references a ClusterStack, which provides the base OS images (build and run images) used during the build process. The stack ensures that your applications are built and run on consistent and controlled OS layers.

2. Store: The ClusterBuilder also references a ClusterStore, which contains buildpacks. Buildpacks are modular components that provide framework and runtime support for your applications. For example, there might be buildpacks for Dotnet, Java, Node.js, Python, etc.

3. Order of Buildpacks: The ClusterBuilder defines the order in which buildpacks should be tried during the build process. It allows specifying a sequence of buildpack groups, enabling the creation of custom build strategies.

An example clusterbuilder definition is below

```yaml
apiVersion: kpack.io/v1alpha2
kind: Builder
metadata:
  name: my-builder
  namespace: default
spec:
  serviceAccountName: kpack-service-account
  tag: pradeepl/my-builders:latest
  stack:
    name: base
    kind: ClusterStack
  store:
    name: default
    kind: ClusterStore
  order:
  - group:
    - id: paketo-buildpacks/dotnet-core
  - group:
    - id: paketo-buildpacks/java
  - group:
    - id: paketo-buildpacks/nodejs
```
## ClusterStore

ClusterStore is a custom resource that holds a collection of buildpacks used by Kpack to build container images. It provides a centralized and scalable way to manage buildpacks in a Kubernetes cluster. By decoupling buildpack management from individual builders, Kpack allows for greater flexibility and easier maintenance of the buildpacks used across different projects and teams in the cluster.

An example clusterstore definition is below

```yaml
apiVersion: kpack.io/v1alpha2
kind: ClusterStore
metadata:
  name: default
spec:
  sources:
  - image: gcr.io/paketo-buildpacks/dotnet-core
  - image: gcr.io/paketo-buildpacks/java
  - image: gcr.io/paketo-buildpacks/nodejs
```

## Image

An Image is a custom resource that represents the container image to be built from source code. It defines how to build your application from source, which builder to use, and where to push the resulting container image. 

The Image resource typically includes the following key components:

1. Source Code Location: Specifies where the source code for the image is located, usually a Git repository. It includes details like the repository URL and the specific branch or commit to build from.

2. Builder: Refers to a Builder or ClusterBuilder resource that should be used to build the image. The builder includes the stack (base images) and buildpacks necessary for building the application.

3. Tag: Defines the registry location (repository name and tag) where the built image will be pushed. This could be a Docker Hub repository, Google Container Registry, or any other container image registry.

4. Service Account: Specifies the Kubernetes service account that has the necessary credentials to access the source code repository and image registry.

5. Build Configuration: Additional build configuration settings, like environment variables, can be specified to customize the build process.

A sample image definition is below

```yaml
apiVersion: kpack.io/v1alpha2
kind: Image
metadata:
  name: sample-image
  namespace: default
spec:
  tag: pradeepl/myapp
  serviceAccountName: kpack-service-account
  builder:
    name: my-builder
    kind: Builder
  source:
    git:
      url: https://github.com/PradeepLoganathan/AccuWeather
      revision: 96976f0f4d9b5fceda838fb55c3235961dae4e6c
  syncPeriod: 30m
```

## Component relationship

The below diagram summarizes the relationship between the various kpack components

{{< mermaid >}}
graph TD
  CS[ClusterStack] -->|Defines OS layers| CB[ClusterBuilder]
  Store[ClusterStore] -->|Provides Buildpacks| CB
  CB -->|Used by| IR[Image]
  Repo[Source Code Repository] -->|Source for| IR
  IR -->|Image pushed to| Registry[Container Registry]
{{< /mermaid >}}

The ClusterStack Provides the OS layers for both the build and run environments. The ClusterStore supplies buildpacks that are used in the build process. The ClusterBuilder combines the OS layers from ClusterStack and buildpacks from ClusterStore to define how an application's source code should be built into a container image. The Image resource defines the application's build configuration, including its source, the builder it uses and the container registry where it pushes the built container image.

# Getting started with Kpack

Now that we understand Kpack and its architecture, let us get started by installing kpack and containerizing a dotnet application. We will pull the source code for this application from a public github repository and push the containerized image into a container registry.

## Installing Kpack

Kpack can be installed on any kubernetes cluster. To install kpack, download the latest Kpack release YAML from the [Kpack GitHub Releases page](https://github.com/pivotal/kpack/releases). Once you have the YAML file, apply it to your cluster ```kubectl apply -f <path-to-kpack-release.yaml>```. You can verify the installation by ensuring that the kpack pods are running successfully in the cluster using ```kubectl get pods -n kpack``` 

To install the Kpack CLI, known as kp, you can download the latest binary from the [Kpack Cli GitHub Releases page](https://github.com/buildpacks-community/kpack-cli/releases) and install it on your system. You can verify the install by using ```kp version``` command.

## Building an image with Kpack

The yaml definitions for the next steps are available on my github [here](https://github.com/PradeepLoganathan/KpackKata).

Now that we have installed Kpack on a kubernetes cluster, we can create the necessary custom resources such as clusterbuilder, clusterstack , clusterstore and image. Before creating these components we need to create a secret for registry access to be able to store our images and if using a private repository another secret to be able to pull code from the private code repository. 

You can create a secret as below

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-credentials
  namespace: default
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <BASE64_ENCODED_DOCKER_CONFIG>
```

To get <BASE64_ENCODED_DOCKER_CONFIG>, you need to base64 encode your Docker config JSON. Apply this secret ```kubectl apply -f registry-secret.yaml```. We now need to create the ClusterStack resource to provide the base image for build and run environments. I am using ```paketobuildpacks/build-jammy-base``` for the as the base image for the build environment and ```paketobuildpacks/run-jammy-base``` as the base image for the run environment. We can now define the buildpacks that will be used to build the dotnet application by creating the Clusterbuilder.I am creating a clusterbuilder with ```paketo-buildpacks/dotnet-core```, ```paketo-buildpacks/java``` and ```paketo-buildpacks/nodejs``` buildpacks. Now that we have the necessary custom resources, we can define an image resource to build the dotnet application. In this image resource, I provide the git url for the application repository, the builder to use and the tag for the container registry. Once this is applied , it will build the application and create the container image and push it to the container registry.

# Conclusion

In conclusion, Kpack stands out as an effective tool for automated, consistent, and secure container image builds in Kubernetes environments. Its deep integration with Cloud Native Buildpacks and Kubernetes makes it a valuable asset in modern cloud-native development, especially for organizations looking to enhance their CI/CD practices. In Kpack's architecture, each component plays a vital role in streamlining the process of building and managing container images in a Kubernetes environment. The interaction between ClusterStacks, ClusterBuilders, Image resources, and Source Providers creates an automated, efficient, and scalable system for container image creation and maintenance. This architecture not only facilitates consistent and secure image builds but also integrates smoothly with broader CI/CD workflows, making it a valuable tool in modern cloud-native development.