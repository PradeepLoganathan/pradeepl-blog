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

A DockerFile is the most popular mechanism for building container images. It is a combination of the Dockerfile format and the Dockerfile syntax. Dockerfile is a text file that describes how to build a container image. It is a simple text file that specifies a base image along with a series of instructions to execute on top of it. There are several competing container image formats such as [Docker](https://github.com/moby/moby/blob/master/image/spec/v1.md), [appc](https://github.com/rkt/rkt/blob/v1.30.0/Documentation/app-container.md), [LXD](https://ubuntu.com/blog/lxd-2-0-image-management-512) and others.

The Open Container Initiative (OCI) provides a specification for container images. It is a common format for container images. This standardization of the container image specification 

Buildpacks produce container images that adhere to the OCI image specification and can run on any container platform. 
Buildpacks provide a higher-level abstraction above Dockerfiles designed to build apps

[//]: # (https://www.padok.fr/en/blog/container-docker-oci)
[//]: # (https://aws.amazon.com/blogs/containers/creating-container-images-with-cloud-native-buildpacks-using-aws-codebuild-and-aws-codepipeline/)


![Build OCI Containers](images/Cloud-native-buildpack.png)
