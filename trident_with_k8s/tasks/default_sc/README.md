# Specify a default storage class

**Objective:**  

Most of the volume requests in this lab refer to a specific storage class.  

Setting a `default` storage class can be useful, especially when this one is used most times.  This also allows you not to set the storage class parameter in the Volume Claim anymore.

**Note:** All below commands are to be run against the dev cluster. Unless specified differently, please connect using PuTTY to the dev k8s cluster's master node (**`rhel5`**) to proceed with the task.  

## A. Set a default storage class

First off, make sure you at the correct path for this task:

```bash
[root@rhel5 config_block]# cd ~/netapp-bootcamp/trident_with_k8s/tasks/default_sc/
[root@rhel5 default_sc]#
```

Let's check what storageclasses are configured and patch one of them to be set as the default:

```bash
[root@rhel5 default_sc]# kubectl get sc
NAME                        PROVISIONER             AGE

sc-file-rwx                 csi.trident.netapp.io   3d18h
sc-file-rwx-eco             csi.trident.netapp.io   3d18h

[root@rhel5 default_sc]# kubectl patch storageclass sc-file-rwx -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
storageclass.storage.k8s.io/sc-file-rwx patched

[root@rhel5 default_sc]# kubectl get sc
NAME                          PROVISIONER             AGE
sc-file-rwx (default)         csi.trident.netapp.io   3d18h
sc-file-rwx-eco               csi.trident.netapp.io   3d18h
```

As you can see, `sc-file-rwx` is now referred as the default SC for this cluster.

## B. Try this new setup

There is a PVC file in this directory. If you look at it, you will see there is no SC set.  Try creating this PVC and see what happens:

```bash
[root@rhel5 default_sc]# kubectl create -f 1_pvc.yaml
persistentvolumeclaim/pvc-without-sc created

[root@rhel5 default_sc]# kubectl get pvc,pv
NAME                                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
persistentvolumeclaim/pvc-without-sc   Bound    pvc-517348e4-8201-4ac0-a9e1-4adfa5c38f1e   5Gi        RWX            sc-file-rwx         6s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS        REASON   AGE
persistentvolume/pvc-517348e4-8201-4ac0-a9e1-4adfa5c38f1e   5Gi        RWX            Delete           Bound    default/pvc-without-sc   sc-file-rwx                  5s
```

If you take a closer look at the `get pv` result, you will see that it shows the storage class against which it was created, which is also the default one.

Take another look in Grafana to see how it's changed.

Quick clean-up:

```bash
[root@rhel5 default_sc]# kubectl delete pvc pvc-without-sc
persistentvolumeclaim "pvc-without-sc" deleted
```

## C. What's next

- [Deploy your first app with File storage](../file_app)  

or jump ahead to...

- [Deploy your first app with Block storage](../block_app)  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
