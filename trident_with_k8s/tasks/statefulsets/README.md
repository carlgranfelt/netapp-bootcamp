# StatefulSets & Storage Consumption

**GOAL:**  

StatefulSets were introduced to be able to run stateful applications with the following benefits:  

- A stable pod hostname (instead of `podname-randomstring`)  
  - The podname will have a sticky identity, using an index, e.g. podname-0 podname-1 and podname-2 (and when a pod gets rescheduled, it’ll keep that identity)  
- StatefulSets allows stateful applications stable storage with volumes based on their ordinal number (podname-x)  
  - Deleting and/or scaling a StatefulSets down will not delete the volumes associated with the StatefulSet (preserving data)

A StatefulSet will also allow the stateful application to order the start-up and teardown:

- Instead of randomly terminating one pod (an instance of the application), the order is pre-determined
  - When scaling up it goes from 0 to n-1 (n = replication factor)
  - When scaling down it starts with the highest number (n-1) to 0
- This is useful to drain the data from a node before it can be shut down

For more information please see StatefulSets official documentation: <https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/>

***StatefulSets work differently to Deployments or DaemonSets when it comes to storage.*** 

***Deployments & DaemonSets use PVCs defined outside of them, whereas StatefulSets include the storage in their definition (_volumeClaimTemplates_).***
  
***Said differently, you can see a StatefulSet as a couple (POD + Storage). When it is scaled, both objects will be automatically created.***

In this exercise, we will create a MySQL StatefulSet & scale it.  

![Scenario12](../../../images/scenario12.jpg "Scenario12")

## A. Let's start by creating the application

Ensure you are in the correct working directory by issuing the following command on your rhel3 putty terminal in the lab:

```bash
[root@rhel3 ~]# cd /root/NetApp-LoD/trident_with_k8s/tasks/statefulsets/
```

This application is based on 3 elements:

- ConfigMap, which hosts some parameters for the application
- 2 services
- The StatefulSet (3 replicas of the application)

:mag:  
*A* **ConfigMap** *is an API object used to store non-confidential data in key-value pairs. Pods can consume ConfigMaps as environment variables, command-line arguments, or as configuration files in a volume. A ConfigMap allows you to decouple environment-specific configuration from your container images, so that your applications are easily portable.*  
:mag_right:  

```bash
[root@rhel3 ~]# kubectl create namespace mysql
namespace/mysql created

[root@rhel3 ~]# kubectl create -n mysql -f mysql-configmap.yaml
configmap/mysql created
[root@rhel3 ~]# kubectl create -n mysql -f mysql-services.yaml
service/mysql created
service/mysql-read created
[root@rhel3 ~]# kubectl create -n mysql -f mysql-statefulset.yaml
statefulset.apps/mysql created
```

It will take a few minutes for all the replicas to be created, it is suggested to use the _watch_ flag to monitor the deployments progress.  Use control-C to drop out of the watch and back to the prompt:

```bash
[root@rhel3 ~]# watch -n1 kubectl -n mysql get pod -o wide

mysql-0   1/2     Running   0          43s   10.36.0.1   rhel1   <none>           <none>
mysql-0   2/2     Running   0          52s   10.36.0.1   rhel1   <none>           <none>
mysql-1   0/2     Pending   0          0s    <none>      <none>   <none>           <none>
mysql-1   0/2     Pending   0          0s    <none>      <none>   <none>           <none>
mysql-1   0/2     Pending   0          4s    <none>      rhel2    <none>           <none>
mysql-1   0/2     Init:0/2   0          4s    <none>      rhel2    <none>           <none>
mysql-1   0/2     Init:1/2   0          24s   10.44.0.1   rhel2    <none>           <none>
mysql-1   0/2     Init:1/2   0          32s   10.44.0.1   rhel2    <none>           <none>
mysql-1   0/2     PodInitializing   0          40s   10.44.0.1   rhel2    <none>           <none>
...
```

Once you see that the second POD is up & running, you are good to go:

```bash
[root@rhel3 ~]# kubectl -n mysql get pod -o wide
NAME      READY   STATUS    RESTARTS   AGE   IP          NODE    NOMINATED NODE   READINESS GATES
mysql-0   2/2     Running   0          24h   10.36.0.1   rhel1   <none>           <none>
mysql-1   2/2     Running   1          24h   10.44.0.1   rhel2   <none>           <none>
```

Now, check the storage. You can see that 2 PVCs were created, one per POD.

```bash
[root@rhel3 ~]# kubectl get -n mysql pvc,pv
NAME                                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
persistentvolumeclaim/data-mysql-0   Bound    pvc-f348ec0a-f304-49d8-bbaf-5a85685a6194   10Gi       RWO            sc-file-rwx         5m
persistentvolumeclaim/data-mysql-1   Bound    pvc-ce114401-5789-454a-ba1c-eb5453fbe026   10Gi       RWO            sc-file-rwx         5m

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS        REASON   AGE
persistentvolume/pvc-ce114401-5789-454a-ba1c-eb5453fbe026   10Gi       RWO            Delete           Bound    mysql/data-mysql-1   sc-file-rwx                  5m
persistentvolume/pvc-f348ec0a-f304-49d8-bbaf-5a85685a6194   10Gi       RWO            Delete           Bound    mysql/data-mysql-0   sc-file-rwx                  5m
```

## B. Let's write some data into the database

To connect to MySQL, we will use another POD which will connect to the master DB (`mysql-0`).  
**Copy & paste the whole block at once:**

```bash
[root@rhel3 ~]# kubectl run mysql-client -n mysql --image=mysql:5.7 -i --rm --restart=Never --\
 mysql -h mysql-0.mysql <<EOF
CREATE DATABASE test;
CREATE TABLE test.messages (message VARCHAR(250));
INSERT INTO test.messages VALUES ('hello');
EOF
```

Let's check that the operation was successful by reading the database, through the service called `_mysql-read_`:

```bash
[root@rhel3 ~]# kubectl run mysql-client -n mysql --image=mysql:5.7 -i -t --rm --restart=Never -- mysql -h mysql-read -e "SELECT * FROM test.messages"
If you don't see a command prompt, try pressing enter.
+---------+
| message |
+---------+
| hello   |
+---------+
pod "mysql-client" deleted
```

## C. Where are my reads coming from?

In the current setup, _writes_ are done on the master DB, wheareas _reads_ can come from any DB POD.  

Let's check this!  

First, open a new Putty window & connect to RHEL3. You can then run the following, which will display the ID of the database followed by a timestamp:

```bash
[root@rhel3 ~]# kubectl run mysql-client-loop -n mysql --image=mysql:5.7 -i -t --rm --restart=Never -- bash -ic "while sleep 1; do mysql -h mysql-read -e 'SELECT @@server_id,NOW()'; done"
+-------------+---------------------+
| @@server_id | NOW()               |
+-------------+---------------------+
|         100 | 2020-04-07 10:22:32 |
+-------------+---------------------+
+-------------+---------------------+
| @@server_id | NOW()               |
+-------------+---------------------+
|         101 | 2020-04-07 10:22:33 |
+-------------+---------------------+
```

As you can see, _reads_ are well distributed between all the PODs.  
Keep this window open for now...

## D. Let's scale

Scaling an application with Kubernetes is pretty straightforward & can be achieved with the following command:

```bash
[root@rhel3 ~]# kubectl scale statefulset mysql -n mysql --replicas=3
statefulset.apps/mysql scaled
```

You can use the `kubectl -n mysql get pod -o wide ` with the `watch` parameter again to see the new POD starting.  
When done, you should have something similar to this:

```bash
[root@rhel3 ~]# watch -n1 kubectl -n mysql get pod -o wide 
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   2/2     Running   0          12m
mysql-1   2/2     Running   0          12m
mysql-2   2/2     Running   0          3m13s
```

Notice the last POD is _younger_ that the other ones...  

Again, check the storage. You can see that a new PVC was automatically created.

```bash
[root@rhel3 ~]# kubectl get -n mysql pvc,pv  
NAME                                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
persistentvolumeclaim/data-mysql-0   Bound    pvc-f348ec0a-f304-49d8-bbaf-5a85685a6194   10Gi       RWO            sc-file-rwx         15m
persistentvolumeclaim/data-mysql-1   Bound    pvc-ce114401-5789-454a-ba1c-eb5453fbe026   10Gi       RWO            sc-file-rwx         15m
persistentvolumeclaim/data-mysql-2   Bound    pvc-8758aaaa-33ab-4b6c-ba42-874ce6028a49   10Gi       RWO            sc-file-rwx         6m18s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS        REASON   AGE
persistentvolume/pvc-8758aaaa-33ab-4b6c-ba42-874ce6028a49   10Gi       RWO            Delete           Bound    mysql/data-mysql-2   sc-file-rwx                  6m17s
persistentvolume/pvc-ce114401-5789-454a-ba1c-eb5453fbe026   10Gi       RWO            Delete           Bound    mysql/data-mysql-1   sc-file-rwx                  15m
persistentvolume/pvc-f348ec0a-f304-49d8-bbaf-5a85685a6194   10Gi       RWO            Delete           Bound    mysql/data-mysql-0   sc-file-rwx                  15m
```

Also, if the second window is still open, you should start seeing new `id` ('102' anyone?):

```bash
+-------------+---------------------+
| @@server_id | NOW()               |
+-------------+---------------------+
|         101 | 2020-04-07 10:25:51 |
+-------------+---------------------+
+-------------+---------------------+
| @@server_id | NOW()               |
+-------------+---------------------+
|         102 | 2020-04-07 10:25:53 |
+-------------+---------------------+
+-------------+---------------------+
| @@server_id | NOW()               |
+-------------+---------------------+
|         100 | 2020-04-07 10:25:54 |
+-------------+---------------------+
```

Go back to your Grafana dashboard to check what is happening (<http://192.168.0.141>).  

## E. Clean up

```bash
[root@rhel3 ~]# kubectl delete namespace mysql
namespace "mysql" deleted
```

## F. What's next

You can now move on to:  

- [Resize a iSCSI CSI PVC](../resize_block):   
or jump ahead to...  
- [On-Demand Snapshots & PVC clones](../snpashots_clones):   
- [Dynamic export policy management ](../dynamic_exports):  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
