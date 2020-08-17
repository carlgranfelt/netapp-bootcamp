# k8s Snapshots and Clones with Trident

**Objective:**  
Kubernetes 1.17 promoted [CSI Snapshots to Beta](https://kubernetes.io/blog/2019/12/09/kubernetes-1-17-feature-cis-volume-snapshot-beta/).  
This is fully supported by Trident 20.01.1 and above.

In this task you will create a read-only snapshot of your PV and then also create a space-efficienct read-write cloned PV from your snapshot.  This type of task would be useful for application test and development or in environments that make use of CI/CD pipelines that require multiple presistent data copies for large development teams.

![Snapshots & Clones](../../../images/snapshots_clones.jpg "Snapshots & Clones")

## A. Prepare the environment

Ensure you are in the correct working directory by issuing the following command on your rhel3 putty terminal in the lab:

```bash
[root@rhel3 ~]# cd /root/netapp-bootcamp/trident_with_k8s/tasks/snapshots_clones/
```

We will create an app in its own namespace (also very useful for cleaning up everything when you are done).  

```bash
[root@rhel3 ~]# kubectl create namespace ghost-snap-clone
namespace/ghost created

[root@rhel3 ~]# kubectl create -n ghost-snap-clone -f ghost.yaml
persistentvolumeclaim/blog-content created
deployment.apps/blog created
service/blog created

[root@rhel3 ~]# kubectl get all -n ghost-snap-clone
NAME                       READY   STATUS              RESTARTS   AGE
pod/blog-57d7d4886-5bsml   1/1     Running             0          50s

NAME           TYPE           CLUSTER-IP     EXTERNAL-IP          PORT(S)        AGE
service/blog   LoadBalancer   10.97.56.215   192.168.0.145        80:30070/TCP   50s

NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/blog   1/1     1            1           50s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/blog-57d7d4886   1         1         1       50s

[root@rhel3 ~]# kubectl get pvc,pv -n ghost-snap-clone
NAME                                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
persistentvolumeclaim/blog-content   Bound    pvc-ce8d812b-d976-43f9-8320-48a49792c972   5Gi        RWX            sc-file-rwx         4m3s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                  STORAGECLASS        REASON   AGE
persistentvolume/pvc-ce8d812b-d976-43f9-8320-48a49792c972   5Gi        RWX            Delete           Bound    ghost-snap-clone/blog-content          sc-file-rwx                  4m2s
```

Check to see if you can access the app via your browser.  In this example case, the LoadBalancer IP for our app is `192.168.0.145`, though this may be different for you, so check your output from `kubectl get all -n ghost-snap-clone`.

## B. Configure the snapshot feature

This [link](https://github.com/kubernetes-csi/external-snapshotter) is a good read if you want to know more details about installing the CSI Snapshotter.  

You first need to install 3 CRDs which you can find in the `Kubernetes/CRD` directory or in the CSI Snapshotter github repository.

```bash
[root@rhel3 ~]# kubectl create -f Kubernetes/CRD/
customresourcedefinition.apiextensions.k8s.io/volumesnapshotclasses.snapshot.storage.k8s.io created
customresourcedefinition.apiextensions.k8s.io/volumesnapshotcontents.snapshot.storage.k8s.io created
customresourcedefinition.apiextensions.k8s.io/volumesnapshots.snapshot.storage.k8s.io created
```

Then comes the Snapshot Controller, which is in the `Kubernetes/Controller` directory  or in the CSI Snapshotter github repository.

```bash
[root@rhel3 ~]# kubectl create -f Kubernetes/Controller/
serviceaccount/snapshot-controller created
clusterrole.rbac.authorization.k8s.io/snapshot-controller-runner created
clusterrolebinding.rbac.authorization.k8s.io/snapshot-controller-role created
role.rbac.authorization.k8s.io/snapshot-controller-leaderelection created
rolebinding.rbac.authorization.k8s.io/snapshot-controller-leaderelection created
statefulset.apps/snapshot-controller created
```

Finally, you need to create a `VolumeSnapshotClass` object that points to the Trident driver.

```bash
[root@rhel3 ~]# kubectl create -f sc-volumesnapshot.yaml
volumesnapshotclass.snapshot.storage.k8s.io/csi-snap-class created

[root@rhel3 ~]# kubectl get volumesnapshotclass
NAME             DRIVER                  DELETIONPOLICY   AGE
csi-snap-class   csi.trident.netapp.io   Delete           3s
```

The `volume snapshot` feature is now ready to be tested.  

## C. Create a snapshot

Before you create your snapshot, let's make sure that you have some important data in your PV that we want to protect.  Don't forget to use the blog-XXXXXXXX-XXXX pod name for your specific deployment.  You can get this with the `kubectl get -n ghost-snap-clone pod` command.

```bash
[root@rhel3 ~]# kubectl exec -n ghost-snap-clone blog-5c9c4cdfbf-q986f -- touch content/very-important-file.txt
```

...and let's make sure the file is now there:
```bash
[root@rhel3 ~]# kubectl exec -n ghost-snapclone blog-5c9c4cdfbf-q986f -- ls -l content/very-important-file.txt
-rw-r--r--    1 root     root             0 Jun 30 11:34 /data/content/very-important-file.txt
```

Now that you have your important data in your PV, let's take a snapshot to protect it in case somone accidentally (or on purpose) deletes it:

```bash
[root@rhel3 ~]# kubectl create -n ghost-snap-clone -f pvc-snapshot.yaml
volumesnapshot.snapshot.storage.k8s.io/blog-snapshot created
```

Take a look at your snapshot status via kubectl:

```bash
[root@rhel3 ~]# kubectl get volumesnapshot -n ghost-snap-clone
NAME            READYTOUSE   SOURCEPVC      SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS    SNAPSHOTCONTENT                                    CREATIONTIME   AGE
blog-snapshot   true         blog-content                           5Gi           csi-snap-class   snapcontent-21331427-59a4-4b4a-a71f-91ffe2fb39bc   12m            12m

[root@rhel3 ~]# tridentctl -n trident get volume
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   |   STORAGE CLASS   | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
| pvc-b2113a4f-7359-4ab2-b771-a86272e3d11d | 5.0 GiB | sc-file-rwx       | file     | bdc8ce93-2268-4820-9fc5-45a8d9dead2a | online | true    |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
```

Take a look at your snapshot status via tridentctl:

```bash
[root@rhel3 ~]# tridentctl -n trident get snapshot
+-----------------------------------------------+------------------------------------------+
|                     NAME                      |                  VOLUME                  |
+-----------------------------------------------+------------------------------------------+
| snapshot-21331427-59a4-4b4a-a71f-91ffe2fb39bc | pvc-b2113a4f-7359-4ab2-b771-a86272e3d11d |
+-----------------------------------------------+------------------------------------------+
```

Your snapshot has been created!  

## E. Data Management with Snapshots

Now that you have an application with a PV and a Snapshot of that PV, wha can you do with it?  Below are 3 tasks that help to demonstrate the power of these mechanisms:

1. [Create an instant Clone](CLONES.md) of your PV and perform a data-in-place application upgrade
2. [Recover data from a Snapshot](DATA-RECOVERY.md) if someone accidentally (or on purpose) deletes anything
3. [See the impact of deleting](IMPACTS.md) PVs, Snapshots or Clones when using these features

## F. Cleanup

Make sure you are done with the 3 additional tasks above before you cleanup, otherwise you'll need to start this task over.

```bash
[root@rhel3 ~]# kubectl delete ns ghost-snap-clone
namespace "ghost-snap-clone" deleted
```

## What's next

You can now move on to the last task on the production cluster:  

- [Dynamic export policy management](../dynamic_exports)  

or jump ahead to the Development cluster tasks...

- [Installing Trident](../trident_install)

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
