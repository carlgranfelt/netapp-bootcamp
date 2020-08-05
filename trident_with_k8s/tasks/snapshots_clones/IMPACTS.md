# Impacts of deleting Snapshots and PVs

PVC, Snapshots & Clones (ie PVC-from-snapshot) are 3 related, but independent, Kubernetes objects.  

However, at the infrastructure level, within ONTAP, these objects have a tight relationship.  

So, what happens if you delete a PVC or a snapshot, how does it affect other objects?  

Well, the good news is that there is no impact...  

## A. Cleaning up the environment

At this point, if you run the command: `kubectl get pv,pvc,volumesnapshot -n ghost-snap-clone` you should have:

- The original PVC: `blog-content`
- Your 1st cloned PVC for your upgraded application: `pvc-from-snap`
- Your 2nd clone for your recovered data: `recovery-clone`
- The Snapshot you originally created: `blog-snapshot`

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
NAME                                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/blog-content     Bound    pvc-766e1cbc-70b9-4e5b-9cb7-93aead07c643   5Gi        RWX            sc-file-rwx    16m
persistentvolumeclaim/pvc-from-snap    Bound    pvc-1934093c-07da-4dce-b0f3-8c35b50bbfc8   5Gi        RWX            sc-file-rwx    15m
persistentvolumeclaim/recovery-clone   Bound    pvc-f5e36092-4ecb-4f35-8184-b890ca8ba6f0   5Gi        RWX            sc-file-rwx    10m

NAME                                                   READYTOUSE   SOURCEPVC      SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS    SNAPSHOTCONTENT                                    CREATIONTIME   AGE
volumesnapshot.snapshot.storage.k8s.io/blog-snapshot   true         blog-content                           5Gi           csi-snap-class   snapcontent-8120f63d-ce41-44e0-b314-54e33c246b9a   15m            16m


[root@rhel3 ~]# tridentctl -n trident get volume
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   | STORAGE CLASS | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
| pvc-1934093c-07da-4dce-b0f3-8c35b50bbfc8 | 5.0 GiB | sc-file-rwx   | file     | 25174b4c-06f7-461d-892d-3a168ee14fab | online | true    |
| pvc-766e1cbc-70b9-4e5b-9cb7-93aead07c643 | 5.0 GiB | sc-file-rwx   | file     | 25174b4c-06f7-461d-892d-3a168ee14fab | online | true    |
| pvc-f5e36092-4ecb-4f35-8184-b890ca8ba6f0 | 5.0 GiB | sc-file-rwx   | file     | 25174b4c-06f7-461d-892d-3a168ee14fab | online | true    |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+


[root@rhel3 ~]# tridentctl -n trident get snapshot
+-----------------------------------------------+------------------------------------------+
|                     NAME                      |                  VOLUME                  |
+-----------------------------------------------+------------------------------------------+
| snapshot-8120f63d-ce41-44e0-b314-54e33c246b9a | pvc-766e1cbc-70b9-4e5b-9cb7-93aead07c643 |
+-----------------------------------------------+------------------------------------------+
```

## B. Deleting PVCs

Let's start by deleting the parent PVC.  

```bash
[root@rhel3 ~]# kubectl delete -n ghost-snap-clone pvc blog-content
persistentvolumeclaim "blog-content" deleted
```

This operation took no time, & here is what we have left within our namespace in Kubernetes:

```bash
[root@rhel3 ~]# kubectl get -n ghost-snap-clone pvc,pv
NAME                                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/pvc-from-snap    Bound    pvc-1934093c-07da-4dce-b0f3-8c35b50bbfc8   5Gi        RWX            sc-file-rwx    17m
persistentvolumeclaim/recovery-clone   Bound    pvc-f5e36092-4ecb-4f35-8184-b890ca8ba6f0   5Gi        RWX            sc-file-rwx    13m

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                             STORAGECLASS   REASON   AGE
persistentvolume/pvc-1934093c-07da-4dce-b0f3-8c35b50bbfc8   5Gi        RWX            Delete           Bound    ghost-snap-clone/pvc-from-snap    sc-file-rwx             17m
persistentvolume/pvc-f5e36092-4ecb-4f35-8184-b890ca8ba6f0   5Gi        RWX            Delete           Bound    ghost-snap-clone/recovery-clone   sc-file-rwx             13m
```

As expected, the *blog-content* PVC & its PV are gone from the configuration.  

However, what do we see from a Trident point of view:

```bash
[root@rhel3 ~]# tridentctl -n trident get volumes
+------------------------------------------+---------+---------------+----------+--------------------------------------+----------+---------+
|                   NAME                   |  SIZE   | STORAGE CLASS | PROTOCOL |             BACKEND UUID             |  STATE   | MANAGED |
+------------------------------------------+---------+---------------+----------+--------------------------------------+----------+---------+
| pvc-1934093c-07da-4dce-b0f3-8c35b50bbfc8 | 5.0 GiB | sc-file-rwx   | file     | 25174b4c-06f7-461d-892d-3a168ee14fab | online   | true    |
| pvc-766e1cbc-70b9-4e5b-9cb7-93aead07c643 | 5.0 GiB | sc-file-rwx   | file     | 25174b4c-06f7-461d-892d-3a168ee14fab | deleting | true    |
| pvc-f5e36092-4ecb-4f35-8184-b890ca8ba6f0 | 5.0 GiB | sc-file-rwx   | file     | 25174b4c-06f7-461d-892d-3a168ee14fab | online   | true    |
+------------------------------------------+---------+---------------+----------+--------------------------------------+----------+---------+


[root@rhel3 ~]# tridentctl -n trident get snapshot
+-----------------------------------------------+------------------------------------------+
|                     NAME                      |                  VOLUME                  |
+-----------------------------------------------+------------------------------------------+
| snapshot-8120f63d-ce41-44e0-b314-54e33c246b9a | pvc-766e1cbc-70b9-4e5b-9cb7-93aead07c643 |
+-----------------------------------------------+------------------------------------------+
```

We still have 3 volumes configured!  

Notice that the volume we just removed is in a *deleting* state.  

Trident is actually going to physically remove the volume only once every CSI Snapshots are deleted!

## C. Deleting Snapshots

Let's delete the CSI Snapshot we created earlier.

```bash
[root@rhel3 ~]# kubectl get -n ghost-snap-clone volumesnapshot
NAME            READYTOUSE   SOURCEPVC      SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS    SNAPSHOTCONTENT                                    CREATIONTIME   AGE
blog-snapshot   true         blog-content                           5Gi           csi-snap-class   snapcontent-8120f63d-ce41-44e0-b314-54e33c246b9a   21m            21m

[root@rhel3 ~]# kubectl delete -n ghost-snap-clone volumesnapshot blog-snapshot
volumesnapshot.snapshot.storage.k8s.io "blog-snapshot" deleted
```

This operation takes a little bit more time than the PVC deletion.  

Let's look at what we have left:

```bash
[root@rhel3 ~]# kubectl get -n ghost-snap-clone pvc,pv
NAME                                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/pvc-from-snap    Bound    pvc-1934093c-07da-4dce-b0f3-8c35b50bbfc8   5Gi        RWX            sc-file-rwx    24m
persistentvolumeclaim/recovery-clone   Bound    pvc-f5e36092-4ecb-4f35-8184-b890ca8ba6f0   5Gi        RWX            sc-file-rwx    19m

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                             STORAGECLASS   REASON   AGE
persistentvolume/pvc-1934093c-07da-4dce-b0f3-8c35b50bbfc8   5Gi        RWX            Delete           Bound    ghost-snap-clone/pvc-from-snap    sc-file-rwx             24m
persistentvolume/pvc-f5e36092-4ecb-4f35-8184-b890ca8ba6f0   5Gi        RWX            Delete           Bound    ghost-snap-clone/recovery-clone   sc-file-rwx             19m


[root@rhel3 ~]# tridentctl -n trident get snapshot
+------+--------+
| NAME | VOLUME |
+------+--------+
+------+--------+
[root@rhel3 ~]# tridentctl -n trident get volume
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   | STORAGE CLASS | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
| pvc-1934093c-07da-4dce-b0f3-8c35b50bbfc8 | 5.0 GiB | sc-file-rwx   | file     | 25174b4c-06f7-461d-892d-3a168ee14fab | online | true    |
| pvc-f5e36092-4ecb-4f35-8184-b890ca8ba6f0 | 5.0 GiB | sc-file-rwx   | file     | 25174b4c-06f7-461d-892d-3a168ee14fab | online | true    |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
```

The snapshot & the first volume are now gone from both Kubernetes & Trident.  

We are left with the PVC clones we created from the snapshot.  

In this configuration, deleting the snapshot & the parent PVC triggered 2 operations:

- As the volume had no CSI Snapshots left, Trident launched the deletion of this volume
- Within ONTAP, a clone is also linked to its parent volume. Deleting the volume also meant performing a "split clone" operation on the second volume, which means transforming a clone into a volume of its own. This operation happens in the background, with no impact.  

Bottom line, deleting a PVC or a snapshot will not have any impact on the infrastructure.

## What's next

Once you have finished with this sub-task, head back to the main task to [clean up](README.md#f-cleanup).