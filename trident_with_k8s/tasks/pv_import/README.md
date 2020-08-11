# Importing Existing Volumes Using Trident

Trident allows you to import an existing volume sitting on a NetApp backend into Kubernetes.  This could be useful for applications that are being re-factored which previously had data from an NFS or iSCSI mount into a Virtual Machine and you now want that same data to be accessed by a container in k8s.

![PV Import](../../../images/pv_import.jpg "PV Import")

## A. Prepare the environment

To give you some data to import, you'll need to run a quick Anible script that has been provided.  The command you need to run the play book is below along with a brief overview of the playbook's tasks.  Although this bootcamp is not focused on Ansible, feel free to have a look through [the script](prepare-import-task.yaml) to get an idea of how Ansible works with NetApp and linux hosts.

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
[root@rhel3 ~]# ansible-playbook prepare-import-task.yaml
```

Let's check to make sure your volumes were created:

```bash
[root@rhel3 pv_import]# curl -X GET -u admin:Netapp1! -k "https://cluster1.demo.netapp.com/api/storage/volumes?name=existing*&return_records=true&return_timeout=15&" -H "accept: application/json"
{
  "records": [
    {
      "uuid": "7fb04961-db0a-11ea-bc68-0050569d4f6b",
      "name": "existing_managed"
    },
    {
      "uuid": "80fa17e4-db0a-11ea-bc68-0050569d4f6b",
      "name": "existing_unmanaged"
    }
  ],
  "num_records": 2
```

As you can see, you have created 2 volumes with the Ansible playbook: 1 for **managed** access and 1 for **unmanaged** access.  

When importing existing volumes (NFS or iSCSI) there are two ways you can do this:

**Managed import**  
Trident will take over management of the volume and handle all future operations on the volume such as snapshots/expansion.  The backend volume will also be renamed to match Trident's volume naming convention.

**Unmanaged Import**  
When a volume is imported with the `--no-manage` argument, Trident will not perform any additional operations on the PVC or PV for the lifecycle of the objects. Since Trident ignores PV and PVC events for --no-manage objects the storage volume is not deleted when the PV is deleted. Other operations such as volume clone and volume resize are also ignored. This option is provided for those that want to use Kubernetes for containerized workloads but otherwise want to manage the lifecycle of the storage volume outside of Kubernetes.

An annotation is added to the PVC and PV that serves a dual purpose of indicating that the volume was imported and if the PVC and PV are managed. This annotation should not be modified or removed.

## B. Importing existing volumes as Managed Volumes

First let's set up your namespace that you can import your volumes into:

```bash
[root@rhel3 pv_import]# kubectl create ns import
namespace/import created
```

To import an existing volume, specify the name of the Trident backend containing the volume, as well as the name that uniquely identifies the volume on the storage (i.e. ONTAP FlexVol, Element Volume, CVS Volume path').  

Next import your managed volume as a PVC:

```bash
[root@rhel3 pv_import]# tridentctl import volume ontap-file-rwx existing_managed -f pvc_managed_import.yaml -n trident
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   | STORAGE CLASS | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
| pvc-27680a58-92eb-4010-b861-78285dd884b3 | 100 MiB | sc-file-rwx   | file     | 89910d72-193d-4a5c-bccc-ba6aa507c45f | online | true    |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
```

...and your unmanaged volume as a PVC using the `--no-manage` argument:

```bash
[root@rhel3 pv_import]# tridentctl import volume ontap-file-rwx existing_unmanaged -f pvc_unmanaged_import.yaml --no-manage -n trident
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   | STORAGE CLASS | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
| pvc-ec3161dd-d00e-42c8-8f45-fae8fe62a9b0 | 100 MiB | sc-file-rwx   | file     | 89910d72-193d-4a5c-bccc-ba6aa507c45f | online | false   |
+------------------------------------------+---------+---------------+----------+--------------------------------------+--------+---------+
```

Feel free to explore further the ```tridentctl import volume <backendName> <volumeName> [flags]``` command to get an idea of how importing an existing volume to Trident works.  

Now you have the existing volumes in Trident, deploy your application:

```bash
[root@rhel3 pv_import]# kubectl create -n import -f ghost/
persistentvolumeclaim/blog-content created
deployment.apps/blog-import created
service/blog-import created
```

**Note:** Whilst the Ghost application is the same as in the [Deploy your first application using persistent file storage](../file_app) task, the container specification section of the ghost/2_deploy.yaml file has been updated for this task to include the two additional volumes and mount paths.  

Grab the name of our Pod so that you can run some `ls` commands against it:

```bash
[root@rhel3 pv_import]# kubectl get -n import pod
NAME                           READY   STATUS     RESTARTS   AGE
blog-import-57ddb8c85d-phhr6   1/1     Running    0          1m
```

Using the Pod name we just grabbed (rather than the example below), check to see if the existing data that was created by the Ansible script earlier is now abvailable in our Pod:

```bash
[root@rhel3 pv_import]# kubectl exec -n import blog-import-57ddb8c85d-phhr6 -- ls /var/lib/ghost/managed-import
your-existing-data1.txt
your_existing_folder1
```

...and the same for the unmanaged volume:

```bash
[root@rhel3 pv_import]# kubectl exec -n import blog-import-57ddb8c85d-phhr6 -- ls /var/lib/ghost/unmanaged-import
your-existing-data2.txt
your_existing_folder2
```

Excellent!  You now have 2 volumes imported into your Pod with existing data in place ready to use.

## C. Managed and Unmanaged Volume Behaviour

### Trident Imported Volume Renaming

When Trident imports a volume as a managed volume, it will rename it using the standard Trident naming scheme and any volume prefix set as part of the storage Backend configuration.  If you check again to see all volumes starting with the name "existing", you will see that you only have 1 volume now instead of 2.  

```bash
[root@rhel3 pv_import]# curl -X GET -u admin:Netapp1! -k "https://cluster1.demo.netapp.com/api/storage/volumes?name=existing*&return_records=true&return_timeout=15&" -H "accept: application/json"
{
  "records": [
    {
      "uuid": "c49e4991-daf9-11ea-bc68-0050569d4f6b",
      "name": "existing_unmanaged"
    }
  ],
  "num_records": 1
```

You can find your `managed-import` volume's new name by using the kubectl describe command, or use the following (note how to use the jsonpath feature):

```bash
[root@rhel3 pv_import]# kubectl get pv $( kubectl get pvc managed-import -n import -o=jsonpath='{.spec.volumeName}') -o=jsonpath='{.spec.csi.volumeAttributes.internalName}{"\n"}'
trident_rwx_pvc_55085cf9_b477_4514_a9bd_58480686846f
```

In this example's case, it is `trident_rwx_pvc_55085cf9_b477_4514_a9bd_58480686846f` and you can see on the ONTAP system via an API call that the volume has been renamed by Trident to match.  Copy the below API curl command and replace the volume name with your own from the previous output:

```bash
[root@rhel3 pv_import]# curl -X GET -u admin:Netapp1! -k "https://cluster1.demo.netapp.com/api/storage/volumes?name=trident_rwx_pvc_55085cf9_b477_4514_a9bd_58480686846f&return_records=true&return_timeout=15&" -H "accept: application/json"
{
  "records": [
    {
      "uuid": "c402db14-daf9-11ea-bc68-0050569d4f6b",
      "name": "trident_rwx_pvc_55085cf9_b477_4514_a9bd_58480686846f"
    }
  ],
  "num_records": 1
```

Even though the name of the original PV volume has changed, you can still see it if you look into its annotations along with the annotation regarding the volume being managed or not:

```bash
[root@rhel3 pv_import]# kubectl describe pvc -n import | grep 'Name:\|notManaged\|importOriginalName'
Name:          blog-content
Name:          managed-import
               trident.netapp.io/importOriginalName: existing_managed
               trident.netapp.io/notManaged: false
Name:          unmanaged-import
               trident.netapp.io/importOriginalName: existing_unmanaged
               trident.netapp.io/notManaged: true
```

### Trident Imported Volume Deletion

To clean-up, you will delete the `import` namespace and observe how Trident handles the managed and unmanaged volumes following this deletion.

```bash
[root@rhel3 pv_import]# kubectl delete ns import
namespace "import" deleted
```

Now you will see that the namespace deletion has removed all the PVs and PVCs related to your `import` namespace:

```bash
[root@rhel3 pv_import]# kubectl get pv,pvc --all-namespaces
No resources found
```

But what has happened on the backend storage:

```bash
[root@rhel3 pv_import]# curl -X GET -u admin:Netapp1! -k "https://cluster1.demo.netapp.com/api/storage/volumes?return_records=true&return_timeout=15&" -H "accept: application/json"
```

You will see that your `existing_unmanaged` volume is still there, but the PV that was renamed by Trident for your `exising_managed` volume has been completely deleted, as per the deletion policy set by the Trident administrator.

## F. What's next

You can now move on to:  

- Next task: [Consumption control](../quotas)  

or jump ahead to...

- [Resize an NFS PVC](../resize_file)  
- [Using Virtual Storage Pools](../storage_pools)  
- [StatefulSets & Storage consumption](../statefulsets)  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
