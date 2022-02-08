---
title: "Deploying Sql Server Always On Availability Group on Kubernetes"
lastmod: 2022-01-31T11:00:08+10:00
date: 2022-01-31T11:00:08+10:00
draft: true
Author: Pradeep Loganathan
tags: 
  - sqlserver
  - Kubernetes
  - "high availability"
  - "disaster recovery"
categories:
  - Kubernetes
#slug: kubernetes/introduction-to-kubernetes-admission-controllers/
summary: In this post we will deploy MS Sql Server in a kubernetes cluster. We will then configure it as an always on availability group.
ShowToc: true
TocOpen: false
images:
  - Shaniwar-wada.png
cover:
    image: "Shaniwar-wada.png"
    alt: "Deploying Sql Server on Kubernetes for High Availability and Disaster Recovery"
    caption: "Deploying Sql Server on Kubernetes for High Availability and Disaster Recovery"
    relative: false # To use relative path for cover image, used in hugo Page-bundles
editPost:
  URL: "https://github.com/PradeepLoganathan/pradeepl-blog/tree/master/content"
  Text: "Edit this post on github" # edit text
  appendFilePath: true # to append file path to Edit link
---
## Always On Availability Group

SQL Server Always On Availability Groups provide a flexible option for achieving high availability and fault tolerance at the database level. It provides options to recover from disasters and allows for greater access to data. Before SQL Server 2017, an Always On Availability Group required Windows Server Failover Clustering (WSFC) when running on Windows and Pacemaker/Corosync when running on Linux. WSFC and Pacemaker are cluster managers which provide HA capabilities to the cluster where SQL server is deployed. On Windows clusters, WSFC monitors applications and resources. It automatically identifies and recovers from failure conditions. This capability provides great flexibility in managing the workload within a cluster and improves the overall availability of the system. WSFC has specific hardware and software compatibility requirements. Pacemaker and corosync are the most widely used clustering solution on Linux clusters. Corosync is a group communication system which provides specific guarantees about the total ordering of messages. It is responsible for messaging between nodes and ensures a consistent cluster state. Pacemaker is responsible for managing the resources on top of this cluster state. This is a highly scalable solution for high availability and disaster recovery on Linux.

However, all of this complexity is unnecessary when the architecture demands read scale workloads. In read scale workloads, the availability of the database is not a primary concern. This enables us to not worry about the cluster failover and other requirements for HA and DR. Read-Scale-Out utilizes the additional capacity of read-only replicas instead of sharing the read-write or primary replica. This ensures that read-only workloads like reports, long-running queries, API queries etc, are isolated from the main read-write workload. It also provides a great opportunity for the database to scale out and scale in. It does provide limited DR capabilities using manual failover when the read-only replicas are configured using synchronous commit mode.

SQL Server 2017 introduced Read Scale Availability groups which can be deployed without the need for a cluster manager. This architecture provides read-scale only. It doesn’t provide high availability. A Read Scale AG consists of one or more databases that are replicated to one or more SQL Servers and are a unit of failover. The SQL Server where transactions originate is called a primary replica. A SQL Server receiving changes is called a secondary replica. The primary replica is the one that is used to store read/write data. The secondary replica is used to provide read-only access to the data. The primary replica is also used to store logs and other system data. SQL Server will capture transaction log changes on a Primary and transmit them over a separate communication channel (called a database mirroring endpoint) to the Secondary replica. On the Secondary replica, the changes are first hardened to the local transaction log and then separately any necessary redo recovery operations are applied. Failover from a primary server to a secondary server can be performed manually when required.A Read-Only AG can be used to load-balance read workloads, for maintenance jobs such as backups, and consistency checks on the secondary databases.

## Synchronization Options

Availability Groups offer two synchronization options to synchronize the secondary replicas with the primary replica.

1. Synchronous Commit mode : In Synchronous commit mode, a transaction on the primary replica will wait for the transaction to commit on the primary and for log records associated with the transaction to be hardened on the secondary replica.

2. Asynchronous Commit mode : In Asynchronous commit mode, a transaction on the primary replica will only wait for the transaction to be committed on the primary. It does not wait for transactions to be hardened on the secondary replica.


## Persistent Storage

Since we are deploying a stateful workload on kubernetes we need to define the necessary storage structures. The cluster needs to provision storage, the pods need to mount the storage provisioned as volumes and a request for the storage should be defined in the manifest as a persistent volume claim. We would need to create these before we can deploy SQL Server on kubernetes.
### Storage Class

Storage classes are the foundation for dynamic provisioning of storage. We need to setup a storage class to define the type of storage that the persistent volumes will use. The PersistentVolume provisioner will use the storage class defined  and provision storage accordingly. I am deploying the cluster on Tanzu Kubernetes Grid (TKG) and defining the corresponding storage class. The storage class definition is as follows:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: sqlserver-sc-csi
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: csi.vsphere.vmware.com
parameters:
  datastoreurl: "ds:///vmfs/volumes/619fcf62-6b2914d8-21ee-000e1e535170/"
```

We can now create this storage class in the kubernetes cluster as below.

```shell
kubectl apply -f storageclass.yaml
```

### Persistent Volumes

We need to create persistent volumes and persistent volume claims for the primary and secondary SQL Servers. The persistent volume will be created in the datastore that we have configured in the storage class. The size of the persistent volume in this example will be 8Gi. The persistent volume can be created in the namespace where the SQL Server is deployed. We need to create 3 persistent volumes for the primary and secondary SQL Servers as below.

The PVC for the primary SQL server can be created as below

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mssql-primary
  annotations:
    volume.beta.kubernetes.io/storage-class: sqlserver-sc-csi
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
```

The PVC for the secondary SQL servers can be created as below

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mssql-secondary1
  annotations:
    volume.beta.kubernetes.io/storage-class: sqlserver-sc-csi
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
```

The PVC for the additional secondary replica is below

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mssql-secondary2
  annotations:
    volume.beta.kubernetes.io/storage-class: sqlserver-sc-csi
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
```

We can now create these persistent volume claims in the kubernetes cluster as below.

```shell
kubectl apply -f pvcprimary.yaml
kubectl apply -f pvcsecondary-one.yaml
kubectl apply -f pvcsecondary-two.yaml
```

We can confirm that the necessary persistent volumes have been created by using ```kubectl get pv```. I get the below output from ```kubectl get pv```

```shell
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                      STORAGECLASS       REASON   AGE
pvc-441cf08e-1d3d-41d6-b7ff-ab92c631a83d   8Gi        RWO            Delete           Bound    default/mssql-secondary2   sqlserver-sc-csi            2m1s
pvc-52a51d31-9aad-4885-8f23-5dfd25b997d5   8Gi        RWO            Delete           Bound    default/mssql-secondary1   sqlserver-sc-csi            6s
pvc-9cbe6b05-eaf0-45a2-b2c3-4038448e470c   8Gi        RWO            Delete           Bound    default/mssql-primary      sqlserver-sc-csi            4m40s
```

We can also confirm that the necessary persistent volume claims have been created by using ```kubectl get pvc```. I get the below output from ```kubectl get pvc```

```shell
NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
mssql-primary      Bound    pvc-9cbe6b05-eaf0-45a2-b2c3-4038448e470c   8Gi        RWO            sqlserver-sc-csi   5m11s
mssql-secondary1   Bound    pvc-52a51d31-9aad-4885-8f23-5dfd25b997d5   8Gi        RWO            sqlserver-sc-csi   35s
mssql-secondary2   Bound    pvc-441cf08e-1d3d-41d6-b7ff-ab92c631a83d   8Gi        RWO            sqlserver-sc-csi   2m30s
```

## Secrets

The SQL Server credentials are stored as Kubernetes secrets. The secret is stored in the cluster and is referenced by the Sql Server deployment. This also ensures that the secret is not part of the deployment manifest. The secrets can be created in the namespace where the SQL Server is deployed. The secrets are created as below.

```shell
kubectl create secret generic mssql-secret --from-literal=SA_PASSWORD="MySQLP@ssw0rdF0rSQL"
```

We have now created all the necessary prerequisites for the SQL Server deployment. We can now deploy the SQL Server in the kubernetes cluster. We need to deploy a SQL Server instance configured as primary and two SQL Server instances configured as secondary read only replicas.

## Primary SQL Server

We deploy the primary instance of SQL server as a kubernetes deployment and expose it using a Kubernetes service. The deployment manifest is below. I have highlighted the critical parts of the manifest.

{{< highlight yaml "linenos=table,hl_lines=10-11 18-19 ,linenostart=1" >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mssqlag-primary-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mssql-primary
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mssql-primary
    spec:
      terminationGracePeriodSeconds: 10
      securityContext:
        fsGroup: 10001
      hostname: mssql-primary
      containers:
      - name: mssql-primary
        image: mcr.microsoft.com/mssql/server:2019-CU15-ubuntu-20.04
        ports:
         - containerPort: 1433
        env:
        - name: ACCEPT_EULA
          value: "Y"
        - name: MSSQL_PID
          value: "Developer"
        - name: MSSQL_ENABLE_HADR
          value: "1"
        - name: MSSQL_AGENT_ENABLED
          value: "true"
        - name: MSSQL_SA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mssql-secret
              key: SA_PASSWORD
        resources:
          limits:
            memory: 4G
        volumeMounts:
        - name: mssqldb
          mountPath: /var/opt/mssql
      volumes:
      - name: mssqldb
        persistentVolumeClaim:
          claimName: mssql-primary  
---
 # Create the load balancing service
apiVersion: v1
kind: Service
metadata:
  name: mssql-primary
spec:
  selector:
    app: mssql-primary
  ports:
    - name: sqlserver
      port: 1433
      targetPort: 1433
    - name: endpoint
      port: 5022
      targetPort: 5022
  type: LoadBalancer  

{{< /highlight >}}

The key parts of this deployment manifest are

* On line 10, we specify the strategy type as recreate. This ensures that when we perform an upgrade Kubernetes will scale down the current version to zero before creating new pods and replicaset with the new version. This is essential since SQL Server maintains exclusive locks on files. This would cause the new pods to fail to start if the old pods were still using the files.
* On line 18, we specify the security context. The ```spec.securityContext.fsGroup``` property defines the group ID that will be configured as the group owner for any filesystem mounts in the pod.
* On line 20, we set the ```template.pod.spec.hostname``` property to ensure that we can set a persistent server name. If this is not set , the sql server instance will have a name with the structure DeploymentName-PodTemplateHash-PodID.
* On line 23, we specify the image to use. In this case we are deploying the 2019-CU15-ubuntu-20.04 image of SQL Server.
* On line 43, We are specifying a persistent volume at /var/opt/mssql. This is where the SQL Server database files will be stored. The volume is created using a persistent volume claim created earlier.

## Secondary SQl Server

We are deploying two secondary replicas. The replicas are configured as read only replicas. The deployment is as below.

{{< highlight yaml "linenos=table,hl_lines=10-11 18-19,linenostart=1" >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mssqlag-secondary1-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mssql-secondary1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mssql-secondary1
    spec:
      terminationGracePeriodSeconds: 30
      hostname: mssql-secondary1
      securityContext:
        fsGroup: 10001
      containers:
      - name: mssql-secondary1
        image: mcr.microsoft.com/mssql/server:2019-latest
        ports:
         - containerPort: 1433
        env:
        - name: ACCEPT_EULA
          value: "Y"
        - name: MSSQL_PID
          value: "Developer"
        - name: MSSQL_ENABLE_HADR
          value: "1"
        - name: MSSQL_AGENT_ENABLED
          value: "true"
        - name: MSSQL_SA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mssql-secret
              key: SA_PASSWORD  
        resources:
          limits:
            memory: 4G
        volumeMounts:
        - name: mssqldb
          mountPath: /var/opt/mssql
      volumes:
      - name: mssqldb
        persistentVolumeClaim:
          claimName: mssql-secondary1  
---
apiVersion: v1
kind: Service
metadata:
  name: mssql-secondary1
spec:
  selector:
    app: mssql-secondary1
  ports:
    - name: sqlserver
      port: 1433
      targetPort: 1433
    - name: endpoint
      port: 5022
      targetPort: 5022  
  type: LoadBalancer
{{< /highlight >}}

The other read-ony replica is deployed as below

{{< highlight yaml "linenos=table,hl_lines=8 15-17,linenostart=1" >}}

apiVersion: apps/v1
kind: Deployment
metadata:
  name: mssqlag-secondary2-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mssql-secondary2
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mssql-secondary2
    spec:
      terminationGracePeriodSeconds: 10
      hostname: mssql-secondary2
      securityContext:
        fsGroup: 10001
      containers:
      - name: mssql-secondary2
        image: mcr.microsoft.com/mssql/server:2019-latest
        ports:
         - containerPort: 1433
        env:
        - name: ACCEPT_EULA
          value: "Y"
        - name: MSSQL_PID
          value: "Developer"
        - name: MSSQL_ENABLE_HADR
          value: "1"
        - name: MSSQL_AGENT_ENABLED
          value: "true"
        - name: MSSQL_SA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mssql-secret
              key: SA_PASSWORD
        resources:
          limits:
            memory: 4G
        volumeMounts:
        - name: mssqldb
          mountPath: /var/opt/mssql
      volumes:
      - name: mssqldb
        persistentVolumeClaim:
          claimName: mssql-secondary2  
---
apiVersion: v1
kind: Service
metadata:
  name: mssql-secondary2
spec:
  selector:
    app: mssql-secondary2
  ports:
    - name: sqlserver
      port: 1433
      targetPort: 1433
    - name: endpoint
      port: 5022
      targetPort: 5022
  type: LoadBalancer    

{{< /highlight >}}

We have now created 3 instances of SQl Server configured with the necessary storage and security. We have also created a load balancer service to expose the necessary ports and endpoints. We are now ready to configure the deployed SQl Servers to form a read scale availability group.

## Configuring the Read Scale Availability Group

### Configuring the Primary SQL Server

We need to perform the following steps on the sql server instance that we plan to use as the primary.

1. Create a database in full AG mode
2. The next step is to take a full backup of all databases that will be part of the availability group. We will not be able to add them to an Availability Group until this has been done.
3. Create logins for AG members.
4. Create a master key and certificate.
5. Copy the master key and certificate to the same directory on secondary replicas.
6. Create AG endpoint on port 5022.
7. Create AG primary replica.
8. Add database to AG

