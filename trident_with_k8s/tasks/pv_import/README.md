# Importing Existing Volumes Using Trident

- Utilise file app from task 1
- Run Ansible script to create 2 new NFS volume on svm1 (manage and no manage)
- Populate volume with some dummy data via shell script
- Create managed PVC for existing volume
- Show that we can now access existing data in manage volume
- Create unmanaged PVC for existing volume
- Show that we can now access existing data in unmanaged volume

Trident allows you to import an existing volume sitting on a NetApp backend into Kubernetes.  This could be useful for applications that are being re-factored which previously had data from an NFS mount into a Virtual Machine and you now want that same data to be accessed by a container in k8s.

## A. Prepare the environment

This lab will make use of the Pod from the [File Storage Application task](../file_app), so make sure you have run that task first.

To give you some data to import, you'll need to run a quick Anible script that has been provided.  The command you need to run the play book is below along with a brief overview of the playbook's tasks.  Although this bootcamp is not focused on Ansible, feel free to have a look through [the script](existing-vols.yaml) to get an idea of how Ansible works with NetApp and linux hosts.

Ensure you are in the correct working directory by issuing the following command on your **`rhel3`** putty terminal in the lab:

```bash
[root@rhel3 ~]# cd /root/NetApp-LoD/trident_with_k8s/tasks/pv_import/
```

The ansible script performs the following tasks

- Creates 2 new volumes on the ONTAP array and mounts them in the namespace
- Mounts the 2 new volumes to the `rhel3` host temporarily
- Write a single file and single directory to each volume to act as our existing data
- Unmounts the volumes from `rhel3`

To run the script, execute the following command.  If you wish to do a dry-run of the command, you can add `--check` to the end of the line:

```bash
[root@rhel3 ~]# ansible-playbook existing_vols.yaml
```

Let's check to make sure your volumes were created:

```bash
[root@rhel3 pv_import]# ssh -l admin 192.168.0.101 vol show -vserver svm1 -volume existing\* -fields volume
Password:

Last login time: 8/7/2020 13:10:10
Unsuccessful login attempts since last login: 1
vserver volume
------- ------------------
svm1    existing_managed
svm1    existing_unmanaged
```

OK, the lab is all set and you now have a k8s Pod from the File Application task and a couple of existing volumes sat on the NetApp array.

## B. Importing existing volumes as Managed Volumes

Create a Trident managed PVC for the managed volume:

```bash
[root@rhel3 pv_import]# tridentctl import volume ontap-file-rwx existing_managed -f pvc_managed_import.yaml -n trident
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   | STORAGE CLASS | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
| pvc-27680a58-92eb-4010-b861-78285dd884b3 | 100 MiB | sc-file-rwx   | file     | 89910d72-193d-4a5c-bccc-ba6aa507c45f | online | true    |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
```

Patch our blog pod within the ghost namespace to mount our new PVC of `managed-volume`:

**This needs work.  I have created a deploy-managed.yaml file, but I don't seem to be able to restart the pod with the new dinfition that has 2 PVs.**

Grab the name of our Pod:

```bash
[root@rhel3 pv_import]# kubectl get -n ghost pod
NAME                    READY   STATUS    RESTARTS   AGE
blog-6bf7df48bb-l98p5   1/1     Running   0          21m
```

Using the Pod name we just grabbed (rather than the example below), check to see if the existing data that was created by the Ansible script earlier is now abvailable in our Pod:
```bash
[root@rhel3 ~]# kubectl exec -n ghost blog-57d7d4886-5bsml -- ls /var/lib/ghost/content
```


## C. Importing existing volumes as Un-managed Volumes

```bash
[root@rhel3 pv_import]# tridentctl import volume ontap-file-rwx existing_unmanaged -f pvc_unmanaged_import.yaml --no-manage -n trident
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   | STORAGE CLASS | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
| pvc-ec3161dd-d00e-42c8-8f45-fae8fe62a9b0 | 100 MiB | sc-file-rwx   | file     | 89910d72-193d-4a5c-bccc-ba6aa507c45f | online | false   |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
```


####################################################

**Objective:**  
Trident allows you to import an existing volume sitting on a NetApp backend into Kubernetes.  This could be useful for applications that are being re-factored which previously had data from an NFS mount into a Virtual Machine and you now want that same data to be accessed by a container in k8s.

We will first copy the volume we used in the [Scenario05](../Scenario05), import it, and create a new Ghost instance  

![PV Import](../../../images/pv_import.jpg "PV Import")

## A. Identify & copy the volume on the NetApp backend

The full name of the volume is available in the PV metadata.  
You can retrieve it if with the 'kubectl describe' command, or use the following (note how to use the jsonpath feature!)

```bash
# kubectl get pv $( kubectl get pvc blog-content -n ghostnas -o=jsonpath='{.spec.volumeName}') -o=jsonpath='{.spec.csi.volumeAttributes.internalName}{"\n"}'
nas1_pvc_e24c99b7_b4e7_4de1_b952_a8d451e7e735
```

Now that you know the full name of the volume, you can copy it. This copy will be done in 2 stages (clone & split)
Open Putty, connect to "cluster1" and finally enter all the following:

```bash
# vol clone create -flexclone to_import -vserver svm1 -parent-volume nas1_pvc_e24c99b7_b4e7_4de1_b952_a8d451e7e735
# vol clone split start -flexclone to_import
```

In this example, the new volume's name is 'to_import'

## B. Import the volume

In the 'Ghost' directory, you will see some yaml files to build a new 'Ghost' app.
Open the PVC definition file, & notice the difference with the one used in the scenario5.

```bash
# tridentctl -n trident import volume NAS_Vol-default to_import -f Ghost/1_pvc.yaml
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   |   STORAGE CLASS   | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
| pvc-ac9ba4b2-7dce-4241-8c8e-a4ced9cf7dcf | 5.0 GiB | sc-file-rwx       | file     | dea226cf-7df7-4795-b1a1-3a4a3318a059 | online | true    |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+

# kubectl get pvc -n ghostnas
NAME                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
blog-content          Bound    pvc-e24c99b7-b4e7-4de1-b952-a8d451e7e735   5Gi        RWX            sc-file-rwx         19h
blog-content-import   Bound    pvc-ac9ba4b2-7dce-4241-8c8e-a4ced9cf7dcf   5Gi        RWX            sc-file-rwx         21m
```

Notice that the volume full name on the storage backend has changed to respect the CSI specifications:

```bash
# kubectl get pv $( kubectl get pvc blog-content-import -n ghostnas -o=jsonpath='{.spec.volumeName}') -o=jsonpath='{.spec.csi.volumeAttributes.internalName}{"\n"}'
nas1_pvc_ac9ba4b2_7dce_4241_8c8e_a4ced9cf7dcf
```

Even though the name of the original PV has changed, you can still see it if you look into its annotations.

```bash
# kubectl describe pvc blog-content-import -n ghostnas | grep importOriginalName
               trident.netapp.io/importOriginalName: to_import
```

## C. Create a new Ghost app

You can now create the deployment & expose it on a new port

```bash
# kubectl create -n ghostnas -f Ghost/2_deploy.yaml
deployment.apps/blogimport created
# kubectl create -n ghostnas -f Ghost/3_service.yaml
service/blogimport created

# kubectl all -n ghostnas
NAME                           READY   STATUS    RESTARTS   AGE
pod/blog-cd5894ddd-d2tqp       1/1     Running   0          20h
pod/blogimport-66945d9-bsw9b   1/1     Running   0          24m

NAME                 TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/blog         NodePort   10.111.248.112   <none>        80:30080/TCP   20h
service/blogimport   NodePort   10.104.52.17     <none>        80:30082/TCP   24m

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/blog         1/1     1            1           20h
deployment.apps/blogimport   1/1     1            1           24m

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/blog-cd5894ddd       1         1         1       20h
replicaset.apps/blogimport-66945d9   1         1         1       24m
```

## D. Access the app

The Ghost service is configured with a NodePort type, which means you can access it from every node of the cluster on port 30082.
Give it a try !  
=> <http://192.168.0.63:30082>  

If you have configured Grafana, you can go back to your dashboard, to check what is happening (<http://192.168.0.63:30001>).  

## E. Cleanup

Instead of deleting each object one by one, you can directly delete the namespace which will then remove all of its objects.

```bash
# kubectl delete ns ghostnas
namespace "ghostnas" deleted
```

## F. What's next

You can now move on to:  

- Next task: [Consumption control](../quotas)   

or jump ahead to...

- [Resize an NFS PVC](../resize_file)   
- [Using Virtual Storage Pools](../storage_pools)   
- [StatefulSets & Storage consumption ](../statefulsets)  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
