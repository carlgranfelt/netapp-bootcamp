# NFS Volume Resizing

**Objective:**  
Trident supports the resizing of File (NFS/RWX) & Block (iSCSI/RWO) PVCs, depending on the Kubernetes version.  
NFS Resizing was introduced in k8s 1.11, while iSCSI resizing was introduced in k8s 1.16.  
Resizing a PVC is made available through the option *allowVolumeExpansion* set in the StorageClass.  

![Resize File](../../../images/resize_file.jpg "Resize File")

## A. Create a new storage class with the option allowVolumeExpansion

Ensure you are in the correct working directory by issuing the following command on your rhel3 putty terminal in the lab:

```bash
[root@rhel3 ~]# cd /root/NetApp-LoD/trident_with_k8s/tasks/resize_file/
```

```bash
[root@rhel3 ~]# kubectl create -f sc-csi-ontap-nas-resize.yaml
storageclass.storage.k8s.io/sc-nas-resize created
```

## B. Setup the environment

Now let's create a PVC & a Centos POD using this PVC, in their own namespace.

```bash
[root@rhel3 ~]# kubectl create namespace resize
namespace/resize created
[root@rhel3 ~]# kubectl create -n resize -f pvc.yaml
persistentvolumeclaim/pvc-to-resize created

[root@rhel3 ~]# kubectl -n resize get pvc,pv
NAME                                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    AGE
persistentvolumeclaim/pvc-to-resize   Bound    pvc-7eeea3f7-1bea-458b-9824-1dd442222d55   5Gi        RWX            sc-nas-resize   2s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS    REASON   AGE
persistentvolume/pvc-7eeea3f7-1bea-458b-9824-1dd442222d55   5Gi        RWX            Delete           Bound    resize/pvc-to-resize   sc-nas-resize            1s

[root@rhel3 ~]# kubectl create -n resize -f pod-centos-nas.yaml
pod/centos created

[root@rhel3 ~]# kubectl -n resize get pod
NAME     READY   STATUS              RESTARTS   AGE
centos   0/1     ContainerCreating   0          5s

[root@rhel3 ~]# kubectl -n resize get pod
NAME     READY   STATUS              RESTARTS   AGE
centos   1/1     Running             0          15s
```

Once your pod is running you can now check that the 5G volume is indeed mounted into the POD.

```bash
[root@rhel3 ~]# kubectl -n resize exec centos -- df -h /data
Filesystem                                                    Size  Used Avail Use% Mounted on
192.168.0.135:/trident_rwx_pvc_7eeea3f7_1bea_458b_9824_1dd442222d55  5.0G  256K  5.0G   1% /data
```

## C. Resize the PVC & check the result

Resizing a PVC can be done in different ways. We will here edit the definition of the PVC & manually modify it.  
Look for the *storage* parameter in the spec part of the definition & change the value (here for the example, we will use 15GB).  If you need any help with editor, we have a [short guide here](/trident_with_k8s/tasks/vim).

```bash
[root@rhel3 ~]# kubectl -n resize edit pvc pvc-to-resize
persistentvolumeclaim/pvc-to-resize edited

spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 15Gi
  storageClassName: sc-nas-resize
  volumeMode: Filesystem
  volumeName: pvc-7eeea3f7-1bea-458b-9824-1dd442222d55
```

Let's see the result.

```bash
[root@rhel3 ~]# kubectl -n resize get pvc
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    AGE
pvc-to-resize   Bound    pvc-7eeea3f7-1bea-458b-9824-1dd442222d55   15Gi       RWX            sc-nas-resize   144m

[root@rhel3 ~]# kubectl -n resize exec centos -- df -h /data
Filesystem                                                    Size  Used Avail Use% Mounted on
192.168.0.135:/trident_rwx_pvc_7eeea3f7_1bea_458b_9824_1dd442222d55   15G  256K   15G   1% /data
```

As you can see, the resizing was done totally dynamically without any interruption.  
If you have configured Grafana, you can go back to your dashboard, to check what is happening (<http://192.168.0.141>).  

This could also have been achieved by using the _kubectl patch_ command. Try the following command:

```bash
[root@rhel3 ~]# kubectl patch -n resize pvc pvc-to-resize -p '{"spec":{"resources":{"requests":{"storage":"18Gi"}}}}'
```

## D. Cleanup the environment

```bash
[root@rhel3 ~]# kubectl delete namespace resize
namespace "resize" deleted

[root@rhel3 ~]# kubectl delete sc sc-nas-resize
storageclass.storage.k8s.io "sc-nas-resize" deleted
```

## E. What's next

You can now move on to:  

- Next task: [Using Virtual Storage Pools](../storage_pools)  

or jump ahead to...  

- [StatefulSets & Storage consumption](../statefulsets)  
- [Resize a iSCSI PVC](../resize_block)  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
