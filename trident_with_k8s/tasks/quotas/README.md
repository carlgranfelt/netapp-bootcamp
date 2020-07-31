# Consumption Control with Quotas

**Objective:**  
As Trident dynamically manages persitent volumes & brings self-service to the application level, the first benefit is that end-users do not need to rely on a storage admin to provision volumes on the fly.

However, this freedom could quickly fill up the storage backends, especially if the users do not tidy up their environments...  

It is therefore good practice to put some controls in place to make sure the storage is well managed and you are going to review a few different methods to control the storage consumption in this task.

Ensure you are in the correct working diecrtory by issuing the following command on your rhel3 putty terminal in the lab:

```bash
[root@rhel3 ~]# cd /root/NetApp-LoD/trident_with_k8s/tasks/quotas/
```
Feel free to look inside the provided .yaml files in this task so that you can get a good idea of what each one is doing.

## A. Kubernetes Resource Quotas

In order to restrict the tests to a small environment & not affect other projects, we will create a specific namespace called `quota`  

We will then create two types of quotas:

1. Limit the number of PVCs a user can create
2. Limit the total capacity a user can create  

```bash
[root@rhel3 ~]# kubectl create namespace quota
namespace/quota created
[root@rhel3 ~]# kubectl create -n quota -f rq-pvc-count-limit.yaml
resourcequota/pvc-count-limit created
[root@rhel3 ~]# kubectl create -n quota -f rq-sc-resource-limit.yaml
resourcequota/sc-resource-limit created

[root@rhel3 ~]# kubectl get resourcequota -n quota
NAME                CREATED AT
pvc-count-limit     2020-04-01T08:48:38Z
sc-resource-limit   2020-04-01T08:48:44Z

[root@rhel3 ~]# kubectl describe quota pvc-count-limit -n quota
Name:                                                                 pvc-count-limit
Namespace:                                                            quota
Resource                                                              Used  Hard
--------                                                              ----  ----
persistentvolumeclaims                                                0     5
sc-file-rwx.storageclass.storage.k8s.io/persistentvolumeclaims        0     3
```

Now let's start creating some PVC against the storage class _quota_ & check the resource quota usage
![Quotas 1](../../../images/quotas1.jpg "Quotas 1")

```bash
[root@rhel3 ~]# kubectl create -n quota -f pvc-quotasc-1.yaml
persistentvolumeclaim/quotasc-1 created
[root@rhel3 ~]# kubectl create -n quota -f pvc-quotasc-2.yaml
persistentvolumeclaim/quotasc-2 created

[root@rhel3 ~]# kubectl describe quota pvc-count-limit -n quota
Name:                                                                 pvc-count-limit
Namespace:                                                            quota
Resource                                                              Used  Hard
--------                                                              ----  ----
persistentvolumeclaims                                                2     5
sc-file-rwx.storageclass.storage.k8s.io/persistentvolumeclaims        2     3

[root@rhel3 ~]# kubectl create -n quota -f pvc-quotasc-3.yaml
persistentvolumeclaim/quotasc-3 created

[root@rhel3 ~]# kubectl describe quota pvc-count-limit -n quota
Name:                                                                 pvc-count-limit
Namespace:                                                            quota
Resource                                                              Used  Hard
--------                                                              ----  ----
persistentvolumeclaims                                                3     5
sc-file-rwx.storageclass.storage.k8s.io/persistentvolumeclaims        3     3
```

Logically, you reached the maximum number of PVCs allowed for this storage class. Let's see what happens next...

```bash
[root@rhel3 ~]# kubectl create -n quota -f pvc-quotasc-4.yaml
Error from server (Forbidden): error when creating "quotasc-4.yaml": persistentvolumeclaims "quotasc-4" is forbidden: exceeded quota: pvc-count-limit, requested: sc-file-rwx.storageclass.storage.k8s.io/persistentvolumeclaims=1, used: sc-file-rwx.storageclass.storage.k8s.io/persistentvolumeclaims=3, limited: sc-file-rwx.storageclass.storage.k8s.io/persistentvolumeclaims=3
```

As expected, you cannot create a new PVC in this storage class...

Let's clean up the PVC

```bash
[root@rhel3 ~]# kubectl delete pvc -n quota --all
persistentvolumeclaim "quotasc-1" deleted
persistentvolumeclaim "quotasc-2" deleted
persistentvolumeclaim "quotasc-3" deleted
```

Next, we'll look at the capacity quotas:

![Quotas 2](../../../images/quotas2.jpg "Quotas 2")

```bash
[root@rhel3 ~]# kubectl describe quota sc-resource-limit -n quota
Name:                                                           sc-resource-limit
Namespace:                                                      quota
Resource                                                        Used  Hard
--------                                                        ----  ----
requests.storage                                                0     10Gi
sc-file-rwx.storageclass.storage.k8s.io/requests.storage        0     8Gi
```

Each PVC you are going to use is 5GB:

```bash 
[root@rhel3 ~]# kubectl create -n quota -f pvc-5Gi-1.yaml
persistentvolumeclaim/5gb-1 created

[root@rhel3 ~]# kubectl describe quota sc-resource-limit -n quota
Name:                                                           sc-resource-limit
Namespace:                                                      quota
Resource                                                        Used  Hard
--------                                                        ----  ----
requests.storage                                                5Gi   10Gi
sc-file-rwx.storageclass.storage.k8s.io/requests.storage        5Gi   8Gi
```

Due to the size of the second PVC file request, the creation should fail in this namespace:

```bash
[root@rhel3 ~]# kubectl create -n quota -f pvc-5Gi-2.yaml
Error from server (Forbidden): error when creating "pvc-5Gi-2.yaml": persistentvolumeclaims "5gb-2" is forbidden: exceeded quota: sc-resource-limit, requested: sc-file-rwx.storageclass.storage.k8s.io/requests.storage=5Gi, used: sc-file-rwx.storageclass.storage.k8s.io/requests.storage=5Gi, limited: sc-file-rwx.storageclass.storage.k8s.io/requests.storage=8Gi
```

Before starting the second part of this task, let's clean up:

```bash 
[root@rhel3 ~]# kubectl delete pvc -n quota 5gb-1
persistentvolumeclaim "5gb-1" deleted
[root@rhel3 ~]# kubectl delete resourcequota -n quota --all
resourcequota "pvc-count-limit" deleted
resourcequota "sc-resource-limit" deleted
```

## B. Trident parameters

One parameter stands out in the Trident configuration when it comes to control sizes: _limitVolumeSize_  
<https://netapp-trident.readthedocs.io/en/stable-v20.04/dag/kubernetes/storage_configuration_trident.html#limit-the-maximum-size-of-volumes-created-by-trident>  

Depending on the driver, this parameter will:

1. Control the PVC size (ex: driver ONTAP-NAS)
2. Control the size of the ONTAP volume hosting PVC (ex: drivers ONTAP-NAS-ECONOMY or ONTAP-SAN-ECONOMY)

![Quotas 3](../../../images/quotas3.jpg "Quotas 3")

Let's create a backend with this parameter setup (limitVolumeSize = 5g), followed by the storage class that points to it, using the storagePools parameter:

```bash
[root@rhel3 ~]# tridentctl -n trident create backend -f backend-nas-limitsize.json
+------------------+----------------+--------------------------------------+--------+---------+
|       NAME       | STORAGE DRIVER |                 UUID                 | STATE  | VOLUMES |
+------------------+----------------+--------------------------------------+--------+---------+
| NAS_LimitVolSize | ontap-nas      | 8b94769a-a759-4840-b936-985a360f2d87 | online |       0 |
+------------------+----------------+--------------------------------------+--------+---------+

[root@rhel3 ~]# kubectl create -f sc-backend-limit.yaml
storageclass.storage.k8s.io/sclimitvolumesize created
```

Let's see the behavior of the PVC creation, using the pvc-10Gi.yaml file:

```bash
[root@rhel3 ~]# kubectl create -f pvc-10Gi.yaml
persistentvolumeclaim/10g created

[root@rhel3 ~]# kubectl get pvc
NAME   STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
10g    Pending                                                                        sclimitvolumesize   10s
```

The PVC will remain in the `Pending` state. You need to look either in the PVC logs or Trident's:

```bash
[root@rhel3 ~]# kubectl describe pvc 10g
Name:          10g
Namespace:     default
StorageClass:  sclimitvolumesize
Status:        Pending
Volume:
Labels:        <none>
Annotations:   volume.beta.kubernetes.io/storage-provisioner: csi.trident.netapp.io
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Mounted By:    <none>
Events:
  Type     Reason                Age                    From                                                                                     Message
  ----     ------                ----                   ----                                                                                     -------
  Normal   Provisioning          2m32s (x9 over 6m47s)  csi.trident.netapp.io_trident-csi-6b778f79bb-scrzs_7d29b71e-2259-4287-9395-c0957eb6bd88  External provisioner is provisioning volume for claim "default/10g"
  Normal   ProvisioningFailed    2m32s (x9 over 6m47s)  csi.trident.netapp.io                                                                    encountered error(s) in creating the volume: [Failed to create volume pvc-19b8363f-23d6-43d1-b66f-e4539c474063 on storage pool aggr1 from backend NAS_LimitVolSize: requested size: 10737418240 > the size limit: 5368709120]
  Warning  ProvisioningFailed    2m32s (x9 over 6m47s)  csi.trident.netapp.io_trident-csi-6b778f79bb-scrzs_7d29b71e-2259-4287-9395-c0957eb6bd88  failed to provision volume with StorageClass "sclimitvolumesize": rpc error: code = Unknown desc = encountered error(s) in creating the volume: [Failed to create volume pvc-19b8363f-23d6-43d1-b66f-e4539c474063 on storage pool aggr1 from backend NAS_LimitVolSize: requested size: 10737418240 > the size limit: 5368709120]
  Normal   ExternalProvisioning  41s (x26 over 6m47s)   persistentvolume-controller                                                              waiting for a volume to be created, either by external provisioner "csi.trident.netapp.io" or manually created by system administrator
```

The error is now identified... 

You would then need to decide to review the size of the PVC, or you could ask the admin to update the backend definition in order to go on.

Let's clean up before moving to the last chapter of this task.

```bash
[root@rhel3 ~]# kubectl delete pvc 10g
persistentvolumeclaim "10g" deleted
[root@rhel3 ~]# kubectl delete sc sclimitvolumesize
storageclass.storage.k8s.io "sclimitvolumesize" deleted
[root@rhel3 ~]# tridentctl -n trident delete backend NAS_LimitVolSize
```

## C. ONTAP parameters

The amount of ONTAP volumes (Flexvols) you can have on a ONTAP cluster depends on several parameters:

- Version
- Size of the ONTAP cluster (in terms of controllers)  

If the storage platform is also used by other workloads (Databases, Files Services ...), you may want to limit the number of PVCs you build in your storage Tenant (ie SVM)
This can be achieved by setting a parameter on this SVM.  
<https://netapp-trident.readthedocs.io/en/stable-v20.04/dag/kubernetes/storage_configuration_trident.html#limit-the-maximum-volume-count>

![Quotas 4](../../../images/quotas4.jpg "Quotas 4")

Before setting a limit in the SVM _svm1_, you first need to look for the current number of volumes you have.
You can either login to System Manager via the Chrome browser & count, or run the following command (password Netapp1!)

```bash
[root@rhel3 ~]# ssh -l admin 192.168.0.101 vol show -vserver svm1 | grep svm1 | wc -l
Password:
8
```

In my case, in have 8 volumes, I will then set the maximum to 10 for this exercise.

```bash
[root@rhel3 ~]# ssh -l admin 192.168.0.101 vserver modify -vserver svm1 -max-volumes 10
```
We will then try to create a few new PVC.

```bash
[root@rhel3 ~]# kubectl create -f pvc-quotasc-1.yaml
persistentvolumeclaim/quotasc-1 created
[root@rhel3 ~]# kubectl create -f pvc-quotasc-2.yaml
persistentvolumeclaim/quotasc-2 created
[root@rhel3 ~]# kubectl create -f pvc-quotasc-3.yaml
persistentvolumeclaim/quotasc-3 created

[root@rhel3 ~]# kubectl get pvc  -l scenario=quotas
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
quotasc-1   Bound     pvc-a74622aa-bb26-4796-a624-bf6d72955de8   1Gi        RWX            sc-file-rwx        92s
quotasc-2   Bound     pvc-f2bd901a-35e8-45a1-8294-2135b56abe19   1Gi        RWX            sc-file-rwx        22s
quotasc-3   Pending                                                                        sc-file-rwx        4s
```

The PVC will remain in the `Pending` state. You need to look either in the PVC logs or Trident's

```bash
[root@rhel3 ~]# kubectl describe pvc quotasc-3
...
 Warning  ProvisioningFailed    15s                
 API status: failed, Reason: Cannot create volume. Reason: Maximum volume count for Vserver svm1 reached.  Maximum volume count is 12. , Code: 13001
...
```
There you go, point demonstrated!

Time to clean up

```bash
[root@rhel3 ~]# kubectl delete pvc -l scenario=quotas
persistentvolumeclaim "quotasc-1" deleted
persistentvolumeclaim "quotasc-2" deleted
persistentvolumeclaim "quotasc-3" deleted
[root@rhel3 ~]# ssh -l admin 192.168.0.101 vserver modify -vserver svm1 -max-volumes 100
```

## D. What's next

You can now move on to:  

- [Resize an NFS PVC](../resize_file)  

or jump ahead to...  

- [Using Virtual Storage Pools](../storage_pools)  
- [StatefulSets & Storage consumption](../statefulsets)  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)