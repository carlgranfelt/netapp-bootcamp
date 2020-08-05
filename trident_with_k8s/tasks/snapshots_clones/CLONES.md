# PV Cloning with Trident

## A. Create a clone (ie a PVC from Snapshot)

Having a snapshot can be useful to create a new PVC, as you can take that point-in-time Read-Only copy of your PV and crate an instant copy of it as a Read-Write Clone.

If you take a look a the PVC file in the `Ghost_clone` directory, you can notice the reference to the snapshot:

```bash
  dataSource:
    name: blog-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
```

Let's see what that does:

```bash
[root@rhel3 ~]# kubectl create -n ghost-snap-clone -f Ghost_clone/1_pvc_from_snap.yaml
persistentvolumeclaim/pvc-from-snap created
```

This process will be quick no matter if the underlying volume is 10 megabytes or 10 terabytes.

```bash
[root@rhel3 ~]# kubectl get pvc,pv -n ghost-snap-clone
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
blog-content    Bound    pvc-b2113a4f-7359-4ab2-b771-a86272e3d11d   5Gi        RWX            sc-file-rwx         20h
pvc-from-snap   Bound    pvc-4d6e8738-a419-405e-96fc-9cf3a0840b56   5Gi        RWX            sc-file-rwx         6s

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS        REASON   AGE
pvc-4d6e8738-a419-405e-96fc-9cf3a0840b56   5Gi        RWX            Delete           Bound    ghost/pvc-from-snap   sc-file-rwx                  19s
pvc-b2113a4f-7359-4ab2-b771-a86272e3d11d   5Gi        RWX            Delete           Bound    ghost/blog-content    sc-file-rwx                  20h
```

Your clone has been created, but what does it translate to at the storage level?

With ONTAP, you will end up with a *FlexClone*, which is instantaneous & space efficient.

Said differently,  you can imagine it as a _ReadWrite_ snapshot...  

You can see this object by browsing through System Manager or connecting with Putty to the `cluster1` profile (admin/Netapp1!)

```bash
cluster1::> vol clone show
                      Parent  Parent        Parent
Vserver FlexClone     Vserver Volume        Snapshot             State     Type
------- ------------- ------- ------------- -------------------- --------- ----
svm1    nas1_pvc_4d6e8738_a419_405e_96fc_9cf3a0840b56
                      svm1    nas1_pvc_b2113a4f_7359_4ab2_b771_a86272e3d11d
                                            snapshot-21331427-59a4-4b4a-a71f-91ffe2fb39bc
                                                                 online    RW
```

## B. Upgrade an application with data-in-place

Now that we have a clone, what can we do with?

Well, we could maybe fire up a new Ghost environment with a new version while keeping the same content? This would a good way to test a new release, while not copying all the data for this specific environment. In other words, you would save time by doing so.  

The first deployment uses Ghost v2.6. Let's try with Ghost 3.13 ...

```bash
[root@rhel3 ~]# kubectl create -n ghost-snap-clone -f Ghost_clone/2_deploy.yaml
deployment.apps/blogclone created

[root@rhel3 ~]# kubectl create -n ghost-snap-clone -f Ghost_clone/3_service.yaml
service/blogclone created

[root@rhel3 ~]# kubectl get all -n ghost-snap-clone -l scenario=clone
NAME                TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/blogclone   NodePort   10.105.214.201   192.168.0.146        80:30071/TCP   12s

NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/blogclone   1/1     1            1           2m19s
```

Check to see if you can access the new clone of the app via your browser.  In this example case, the LoadBalancer IP for our app is `192.168.0.146`, though this may be different for you, so check your output from your last command on `rhel3`.  You should now have a deployment of Ghost v3.13 but with the back-end data coming from the Clone of your v2.6 deployment.

Using this type of mechanism in a CI/CD pipeline can definitely save time (that's for Devs) & storage (that's for Ops)!

Once you have finished with this sub-task, head back to the main task to [finish off the other sub-tasks](README.md#e-data-management-with-snapshots).
