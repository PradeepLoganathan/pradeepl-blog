---
title: "Cloudnativebuildpacks"
author: "Pradeep Loganathan"
date: 2022-02-10T12:25:09+10:00

draft: true
comments: true
toc: true
showToc: true

description: ""

cover:
    image: "cover.png"
    relative: true

images:


tags:
  - "post"
---

Container images are a popular and standard format to package applications. Container images bundle a program and its dependencies into a single artifact under a root filesystem.  The Open Container Initiative (OCI) provides a specification for container images called the Container Image Format (CIF). CIF is a format for storing container images that is used by Docker, Kubernetes, and other container orchestration platforms.

A DockerFile is the most popular mechanism for building container images. It is a combination of the Dockerfile format and the Dockerfile syntax. Dockerfile is a text file that describes how to build a container image. It is specifies a base image along with a series of instructions to execute on top of it. The instructions are written in a simple language that is similar to shell commands. The docker build engine processes  the docker file to produce container images that adhere to the OCI specification.

However there are issues with using a Dockerfile for generating container images. The primary ones are

1. Each development team creates their own Dockerfile for each deployable unit. The base images and included frameworks are different for each image. This makes it difficult to manage and maintain.
2. Non standard docker files can create non reproducible builds. Examples are using the latest tag or using apt-get to install packages.
3. The image may not be optimized.
4. Security patches issued by vendors for CVE's are not automatically applied to the image.
5. Operational concerns may bleed into the development loop which is not ideal for the development team.

A simple example of the problem with development teams creating container images using docker files is below.

![Individual Docker files](images/Independent-docker-files.png)

Each container above is a separate image. The images package a node based application. Each image uses different unix distributions and node versions. There is no standardization of the images. The images are not optimized for performance, they are not reproducible, they are not secure and the images are not optimized for operational concerns. A CVE in any of the base images will need the operations and the development teams to check all images for vulnerabilities and apply patches manually.

Buildpacks produce container images that adhere to the OCI image specification and can run on any container platform. 
Buildpacks provide a higher-level abstraction above Dockerfiles designed to build apps

[//]: # (https://www.padok.fr/en/blog/container-docker-oci)
[//]: # (https://aws.amazon.com/blogs/containers/creating-container-images-with-cloud-native-buildpacks-using-aws-codebuild-and-aws-codepipeline/)


![Build OCI Containers](images/Cloud-native-buildpack.png)
