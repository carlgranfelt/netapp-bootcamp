# Impacts of deleting Snapshots and PVs

PVC, Snapshots & Clones (ie PVC-from-snapshot) are 3 related, but independent, Kubernetes objects.  

However, at the infrastructure level, within ONTAP, these objects have a tight relationship.  

So, what happens if you delete a PVC or a snapshot, how does it affect other objects?  

Well, the good news is that there is no impact...  

## A. Prepare the environment

At this point, you should have:

- a PVC (*blog-content*)
- a Snapshot (*blog-snapshot*)
- a Clone (*pvc-from-snap*)

Also, if you have already been through the other sub-tasks, you may still have PODs & Services configured.  

Let's start by cleaning this up (remove the Deployment & the services, so that we can work on PVCs).  

Depending on which sub-tasks you have alraedy done, you can use one or both of the following blocks:

```bash
[root@rhel3 ~]# kubectl delete -n ghost-snap-clone all -l scenario=snap
service "blog" deleted
deployment.apps "blog" deleted

[root@rhel3 ~]# kubectl delete -n ghost-snap-clone all -l scenario=clone
service "blogclone" deleted
deployment.apps "blogclone" deleted
```

Once the cleanup is done, you will only have the following left:

```bash
[root@rhel3 ~]# kubectl get -n ghost-snap-clone pvc,volumesnapshot
NAME                                     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
persistentvolumeclaim/blog-content             Bound    pvc-d5511709-a2f7-4d40-8f7d-bb3e0cd50316   5Gi        RWX            storage-class-nas   23m
persistentvolumeclaim/pvc-from-snap   Bound    pvc-525c8fff-f48b-4f7a-b5c3-8aa6230ff72f   5Gi        RWX            storage-class-nas   10m

NAME                                                     READYTOUSE   SOURCEPVC   SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS    SNAPSHOTCONTENT                                    CREATIONTIME   AGE
volumesnapshot.snapshot.storage.k8s.io/blog-snapshot   true         mydata                              5Gi           csi-snap-class   snapcontent-e4ab0f8c-5cd0-4797-a087-0770bd6f1498   16m            16m

[root@rhel3 ~]# tridentctl -n trident get volume
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   |   STORAGE CLASS   | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
| pvc-525c8fff-f48b-4f7a-b5c3-8aa6230ff72f | 5.0 GiB | storage-class-nas | file     | b24a8ae8-a8af-478c-816a-33145116f798 | online | true    |
| pvc-d5511709-a2f7-4d40-8f7d-bb3e0cd50316 | 5.0 GiB | storage-class-nas | file     | b24a8ae8-a8af-478c-816a-33145116f798 | online | true    |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+

[root@rhel3 ~]# tridentctl -n trident get snapshot
+-----------------------------------------------+------------------------------------------+
|                     NAME                      |                  VOLUME                  |
+-----------------------------------------------+------------------------------------------+
| snapshot-e4ab0f8c-5cd0-4797-a087-0770bd6f1498 | pvc-d5511709-a2f7-4d40-8f7d-bb3e0cd50316 |
+-----------------------------------------------+------------------------------------------+
```

## B. Seek & destroy : PVC

Let's start by deleting the parent PVC.  

```bash
[root@rhel3 ~]# kubectl delete -n ghost-snap-clone pvc blog-content
persistentvolumeclaim "blog-content" deleted
```

This operation took no time, & here is what we have left within our namespace in Kubernetes:

```bash
[root@rhel3 ~]# kubetcl get -n ghost-snap-clone pvc,pv
NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
mydata-from-snap   Bound    pvc-525c8fff-f48b-4f7a-b5c3-8aa6230ff72f   5Gi        RWX            storage-class-nas   75m
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS        REASON   AGE
pvc-525c8fff-f48b-4f7a-b5c3-8aa6230ff72f   5Gi        RWX            Delete           Bound    ghost/pvc-from-snap   storage-class-nas            75m

[root@rhel3 ~]# kubetl get -n ghost-snap-clone volumesnapshot
NAME              READYTOUSE   SOURCEPVC   SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS    SNAPSHOTCONTENT                                    CREATIONTIME   AGE
blog-snapshot   true         blog-content                              5Gi           csi-snap-class   snapcontent-e4ab0f8c-5cd0-4797-a087-0770bd6f1498   81m            82m
```

As expected, the *blog-content* PVC & its PV are gone from the configuration.  

However, what do we see from a Trident point of view:

```bash
[root@rhel3 ~]# tridentctl -n trident get volumes
+------------------------------------------+---------+-------------------+----------+--------------------------------------+----------+---------+
|                   NAME                   |  SIZE   |   STORAGE CLASS   | PROTOCOL |             BACKEND UUID             |  STATE   | MANAGED |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+----------+---------+
| pvc-525c8fff-f48b-4f7a-b5c3-8aa6230ff72f | 5.0 GiB | storage-class-nas | file     | b24a8ae8-a8af-478c-816a-33145116f798 | online   | true    |
| pvc-d5511709-a2f7-4d40-8f7d-bb3e0cd50316 | 5.0 GiB | storage-class-nas | file     | b24a8ae8-a8af-478c-816a-33145116f798 | deleting | true    |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+----------+---------+

[root@rhel3 ~]# tridentctl -n trident get snapshot
+-----------------------------------------------+------------------------------------------+
|                     NAME                      |                  VOLUME                  |
+-----------------------------------------------+------------------------------------------+
| snapshot-e4ab0f8c-5cd0-4797-a087-0770bd6f1498 | pvc-d5511709-a2f7-4d40-8f7d-bb3e0cd50316 |
+-----------------------------------------------+------------------------------------------+
```

We still have 2 volumes configured!  

Notice that the volume we just removed is in a *deleting* state.  

Trident is actually going to physically remove the volume only once every CSI Snapshots are deleted!

## C. Seek & destroy : Snapshot

Let's delete the CSI Snapshot we created earlier.

```bash
[root@rhel3 ~]# kubectl get -n ghost-snap-clone volumesnapshot
NAME              READYTOUSE   SOURCEPVC   SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS    SNAPSHOTCONTENT                                    CREATIONTIME   AGE
blog-snapshot   true         blog-content                              5Gi           csi-snap-class   snapcontent-e4ab0f8c-5cd0-4797-a087-0770bd6f1498   126m           127m

[root@rhel3 ~]# kubectl delete -n ghost-snap-clone volumesnapshot blog-snapshot
volumesnapshot.snapshot.storage.k8s.io "blog-snapshot" deleted
```

This operation takes a little bit more time than the PVC deletion.  

Let's look at what we have left:

```bash
[root@rhel3 ~]# kubectl get -n ghost-snap-clone pvc,pv
NAME                                     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
persistentvolumeclaim/pvc-from-snap   Bound    pvc-525c8fff-f48b-4f7a-b5c3-8aa6230ff72f   5Gi        RWX            storage-class-nas   121m

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS        REASON   AGE
persistentvolume/pvc-525c8fff-f48b-4f7a-b5c3-8aa6230ff72f   5Gi        RWX            Delete           Bound    ghost-snap-clone/pvc-from-snap   storage-class-nas            121m

[root@rhel3 ~]# tridentctl -n trident get snapshot
+------+--------+
| NAME | VOLUME |
+------+--------+
+------+--------+
[root@rhel3 ~]# tridentctl -n trident get volume
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   |   STORAGE CLASS   | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
| pvc-525c8fff-f48b-4f7a-b5c3-8aa6230ff72f | 5.0 GiB | storage-class-nas | file     | b24a8ae8-a8af-478c-816a-33145116f798 | online | true    |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
```

The snapshot & the first volume are now gone from both Kubernetes & Trident.  

We are left with the PVC we created from the snapshot.  

In this configuration, deleting the snapshot & the parent PVC triggered 2 operations:

- As the volume had no CSI Snapshots left, Trident launched the deletion of this volume
- Within ONTAP, a clone is also linked to its parent volume. Deleting the volume also meant performing a "split clone" operation on the second volume, which means transforming a clone into a volume of its own. This operation happens in the background, with no impact.  

Bottom line, deleting a PVC or a snapshot will no have any impact on the infrastructure!

## What's next

Once you have finished with this sub-task, head back to the main task to [finish off the other sub-tasks](README.md#Data Management-with-Snapshots).