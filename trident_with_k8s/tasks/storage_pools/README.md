# Working with Virtual Storage Pools

**GOAL:**  

When creating a backend, you can generally specify a set of parameters. It was previously impossible for the administrator to create another backend with the same storage credentials and with a different set of parameters, but with the introduction of Virtual Storage Pools, this issue has been alleviated.  

Virtual Storage Pools is a level of abstraction introduced between the backend and the Kubernetes Storage Class so that the administrator can define parameters along with labels which can be referenced through Kubernetes Storage Classes as a selector, in a backend-agnostic way.  

The following parameters can be used in the Virtual Pools:

- spaceAllocation
- spaceReserve
- snapshotPolicy
- snapshotReserve
- encryption
- unixPermissions
- snapshotDir
- exportPolicy
- securityStyle
- tieringPolicy

In this lab, instead of creating a few backends pointing to the same NetApp SVM, we are going to use Virtual Storage Pools

![Storage Pools](../../../images/storage_pools.jpg "Storage Pools)

## A. Create the new backend

Ensure you are in the correct working directory by issuing the following command on your rhel3 putty terminal in the lab:

```bash
[root@rhel3 ~]# cd /root/NetApp-LoD/trident_with_k8s/tasks/storage_pools/
```

If you take a look at the backend definition, you will see that there are 3 Virtual Storage Pools.
Each one with a different set of parameters.  The below command will show yuu the contents of the backend defintion file:

```bash
[root@rhel3 storage_pools]# cat backend-nas-vsp.json
```

Now apply the backend defintion with tridentctl:

```bash
[root@rhel3 ~]# tridentctl -n trident create backend -f backend-nas-vsp.json
+---------+----------------+--------------------------------------+--------+---------+
|  NAME   | STORAGE DRIVER |                 UUID                 | STATE  | VOLUMES |
+---------+----------------+--------------------------------------+--------+---------+
| NAS_VSP | ontap-nas      | 6cb114a6-1b48-45ee-9ea4-f4267e0e4498 | online |       0 |
+---------+----------------+--------------------------------------+--------+---------+
```

## B. Create new storage classes

We are going to create 3 storage classes, one per Virtual Storage Pool.

```bash
[root@rhel3 ~]# kubectl create -f sc-vsp1.yaml
storageclass.storage.k8s.io/sc-vsp1 created
[root@rhel3 ~]# kubectl create -f sc-vsp2.yaml
storageclass.storage.k8s.io/sc-vsp2 created
[root@rhel3 ~]# kubectl create -f sc-vsp3.yaml
storageclass.storage.k8s.io/sc-vsp3 created

[root@rhel3 ~]# kubectl get sc -l scenario=vsp
NAME                        PROVISIONER             AGE
sc-vsp1                     csi.trident.netapp.io   18s
sc-vsp2                     csi.trident.netapp.io   12s
sc-vsp3                     csi.trident.netapp.io   7s
```

## C. Create a few PVC & a POD in their own namespace

Each of the 3 PVCs will point to a different Storage Class.  Feel free to inspect the .yaml files ahead of running the commands:

```bash
[root@rhel3 ~]# kubectl create namespace vsp
namespace/vsp created
[root@rhel3 ~]# kubectl create -n vsp -f pvc1.yaml
persistentvolumeclaim/pvc-vsp-1 created
[root@rhel3 ~]# kubectl create -n vsp  -f pvc2.yaml
persistentvolumeclaim/pvc-vsp-2 created
[root@rhel3 ~]# kubectl create -n vsp  -f pvc3.yaml
persistentvolumeclaim/pvc-vsp-3 created

[root@rhel3 ~]# kubectl get -n vsp pvc,pv
NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/pvc-vsp-1   Bound    pvc-45169dd9-c9b3-47bf-815a-319bc8d42c69   1Gi        RWX            sc-vsp1        46h
persistentvolumeclaim/pvc-vsp-2   Bound    pvc-3020f487-414d-4396-a0a2-aedd982896c5   1Gi        RWX            sc-vsp2        46h
persistentvolumeclaim/pvc-vsp-3   Bound    pvc-0111127b-e1be-45fb-992d-b97108f55284   1Gi        RWX            sc-vsp3        46h

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS   REASON   AGE
persistentvolume/pvc-0111127b-e1be-45fb-992d-b97108f55284   1Gi        RWX            Delete           Bound    vsp/pvc-vsp-3       sc-vsp3                 46h
persistentvolume/pvc-3020f487-414d-4396-a0a2-aedd982896c5   1Gi        RWX            Delete           Bound    vsp/pvc-vsp-2       sc-vsp2                 46h
persistentvolume/pvc-45169dd9-c9b3-47bf-815a-319bc8d42c69   1Gi        RWX            Delete           Bound    vsp/pvc-vsp-1       sc-vsp1                 46h
```

The POD we are going to use will mount all 3 PVC. We will then check the differences.
Pay attention to the rights set in the Virtual Storage Pools json file.

```bash
[root@rhel3 ~]# kubectl create -n vsp -f pod-centos-nas.yaml
pod/centos created
[root@rhel3 ~]# kubectl -n vsp get pod
NAME     READY   STATUS    RESTARTS   AGE
centos   1/1     Running   0          13s
```

Let's check!

```bash
[root@rhel3 ~]# kubectl -n vsp exec centos -- ls -hl /data
total 12K
drwxr--r-- 2 root root 4.0K Apr  3 16:26 pvc1
drwxrwxrwx 2 root root 4.0K Apr  3 16:34 pvc2
drwxr-xr-x 2 root root 4.0K Apr  3 16:34 pvc3
```

As planned, you can see here the correct permissions:

- PVC1: **744** (parameter for the VSP _myapp1_)
- PVC2: **777** (parameter for the VSP _myapp2_)
- PVC3: **755** (default parameter for the backend)  

Also, some PVC have the snapshot directory visible, some don't.

```bash
[root@rhel3 ~]# kubectl -n vsp exec centos -- ls -hla /data/pvc2
total 8.0K
drwxrwxrwx 2 root root 4.0K Apr  3 16:34 .
drwxr-xr-x 5 root root   42 Apr  5 14:45 ..
drwxrwxrwx 2 root root 4.0K Apr  3 16:34 .snapshot

[root@rhel3 ~]# kubectl -n vsp exec centos -- ls -hla /data/pvc3
total 4.0K
drwxr-xr-x 2 root root 4.0K Apr  3 16:34 .
drwxr-xr-x 5 root root   42 Apr  5 14:45 ..
```

**Conclusion:**  
This could have all be done through 3 different backend files, which is also perfectly fine.

However, the more backends you manage, the more complexity you add. Introducing Virtual Storage Polls allows you to simplify this management.

## D. Cleanup the environment

```bash
[root@rhel3 ~]# kubectl delete namespace vsp
namespace "resize" deleted

[root@rhel3 ~]# kubectl delete sc -l scenario=vsp
storageclass.storage.k8s.io "sc-vsp1" deleted
storageclass.storage.k8s.io "sc-vsp2" deleted
storageclass.storage.k8s.io "sc-vsp3" deleted

[root@rhel3 ~]# tridentctl -n trident delete backend NAS_VSP
```

## E. What's next

You can now move on to:  

- [StatefulSets & Storage consumption](../statefulsets)  
or jump ahead to...  
- [Resize a iSCSI CSI PVC](../resize_block)  
- [On-Demand Snapshots & Create PVC from Snapshot](../snapshots_clones)  
- [Dynamic export policy management](../dynamic_exports)  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
