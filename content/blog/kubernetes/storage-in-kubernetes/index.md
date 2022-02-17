---
title: "Storage in Kubernetes"
author: "Pradeep Loganathan"
date: 2022-01-31T09:18:48+10:00

draft: true
comments: true
toc: true
showToc: true

description: ""

cover:
    image: "cover.png"
    relative: true

images:

mermaid: true


tags:
  - "post"
---


## Kubernetes Storage concepts

Applications that run on Kubernetes can be stateless or stateful. 

Kubernetes provides a structured way to manage persistent storage. It provides API's to manage persistent storage. It provides the following storage API objects

1. Volume: A volume is a container that is used to store data.
2. Persistent Volume: A persistent volume is a volume that is stored in the cluster.
3. Persistent Volume Claim: A persistent volume claim is a request for a persistent volume.
4. Storage Class: A storage class is a specification for a persistent volume.

Let us look at each of the above storage types in further detail.

{{< mermaid >}}
  graph LR
      A --- B
      B-->C[fa:fa-ban forbidden]
      B-->D(fa:fa-spinner);
{{< /mermaid >}}

### Volumes

Volumes are the fundamental abstraction of storage in kubernetes. A volume is a storage device exposed by a node that is accessible to containers on the node. Volumes are mounted into containers in a pod allowing containers to access storage as a local filesystem. It can be mounted as a read-only or read-write volume. It can be mounted by more than one container in a pod allowing the pods to share data. A volume has an explicit lifetime that coincides with its pod. It is defined as part of the pod spec. When the pod is deleted access to the volume is removed but the data in the volume is not destroyed. There are different types of volumes. The full list of volume types is [here.](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes) There are many volume types for the various cloud environments, networked filesystems and various other needs. The configuration values for the volumes are dependent on the volume type. For example, an NFS volume would need to be configured with the NFS server location and the path.

To define a volume in kubernetes, we need to specify the type of volume and the volume name. `` emptyDir `` volume is the simplest type of volume. It creates an empty volume which can be used by the application running in the pod. By default, emptyDir volumes are persisted on the medium backing the node, either disk, SSD or network storage. A volume of type emptyDir  lasts for the lifetime of the Pod. It continues to exist even if the Container terminates and restarts. In the example below, I am creating a volume named scratchvolume of type emptyDir in lines 15-17. This volume is mounted in the pod by specifying the volume name in lines 11-13.

{{< highlight yaml "linenos=table,hl_lines=15-17 11-13,linenostart=1" >}}
apiVersion: v1
kind: Pod
metadata:
  name: testpod
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: samplecontainer

    volumeMounts:
      - mountPath: /scratch
        name: scratchvolume

  volumes:
    - name: scratchvolume
      emptyDir: {}
{{< / highlight >}}

Another example of a volume is a volume of type ConfigMap. A ConfigMap is a mechanism to inject application configuration data into pods. The data stored in the ConfigMap is mounted as a volume and is read using standard file I/O calls. Below is an example pod manifest with a configmap.

{{< highlight yaml "linenos=table,hl_lines=9-18,linenostart=1" >}}
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
    - name: test
      image: busybox
      volumeMounts:
        - name: config-vol
          mountPath: /etc/config
  volumes:
    - name: config-vol
      configMap:
        name: log-config
        items:
          - key: log_level
            path: log_level
{{< / highlight >}}

### Persistent Volumes

Persistent volumes are storage resources provisioned ahead of time by the cluster administrator. Persistent volumes can be provisioned statically or dynamically. Persistent volumes are used to store data on the cluster. Persistent volumes are backed by a storage medium such as a disk, SSD or network storage. Persistent volumes are defined in the cluster configuration. 
