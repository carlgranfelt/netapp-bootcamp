# Create your first SAN backends

**Objective:**  
You understood how to create backends and what they are for.  You probably also created a few ones with NFS drivers.  

It is now time to add more backends that can be used for block storage.  

The ONTAP environment in the lab has already been setup for block storage. You can choose to use the SVM you are already using, or create your own. In the latter scenario, please refer to  task [Prepare ONTAP for block storage on dev cluster](../../tasks/ontap_block).  

![Configure Block](../../../images/config-block.png "Configure Block")

**Note:** All below commands are to be run against the dev cluster. Unless specified differently, please connect using PuTTY to the dev k8s cluster's master node (rhel5) to proceed with the task.  

## A. Create your first SAN backends

You will find in this directory a few backends files:

- backend-san-default.json        ONTAP-SAN
- backend-san-eco-default.json    ONTAP-SAN-ECONOMY  

You can decide to use all of them, only a subset of them or modify them as you wish

:boom: **Here is an important statement if you are planning on using these drivers in your environment.** :boom:  
The **default** is to use **all data LIF** IPs from the SVM and to use **iSCSI multipath**.  
Specifying an IP address for the **dataLIF** for the ontap-san* drivers forces the driver to **disable** multipath and use only the specified address.  

If you take a closer look to both json files, you will see that the parameter dataLIF has not been set, therefore enabling multipathing.  

First off, make sure you are in the correct path for this task:

```bash
[root@rhel5 config_file]# cd ~/netapp-bootcamp/trident_with_k8s/tasks/config_block/
[root@rhel5 config_block]#
```

```bash
[root@rhel5 config_block]# tridentctl -n trident create backend -f backend-san-default.json
+---------------------+-------------------+--------------------------------------+--------+---------+
|        NAME         |  STORAGE DRIVER   |                 UUID                 | STATE  | VOLUMES |
+---------------------+-------------------+--------------------------------------+--------+---------+
| ontap-block-rwo     | ontap-san         | 6ca0fb82-7c42-4319-a039-6d15fbdf0f3d | online |       0 |
+---------------------+-------------------+--------------------------------------+--------+---------+

[root@rhel5 config_block]# tridentctl -n trident create backend -f backend-san-eco-default.json
+---------------------+-------------------+--------------------------------------+--------+---------+
|        NAME         |  STORAGE DRIVER   |                 UUID                 | STATE  | VOLUMES |
+---------------------+-------------------+--------------------------------------+--------+---------+
| ontap-block-rwo-eco | ontap-san         | db6293a4-476e-479b-90e4-ab78372dfd04 | online |       0 |
+---------------------+-------------------+--------------------------------------+--------+---------+

[root@rhel5 config_block]# kubectl get -n trident tridentbackends
NAME        BACKEND               BACKEND UUID
tbe-cgx2q   ontap-block-rwo-eco   db6293a4-476e-479b-90e4-ab78372dfd04
tbe-dljs6   ontap-block-rwo       6ca0fb82-7c42-4319-a039-6d15fbdf0f3d
```

## B. Create storage classes pointing to each new backend

You will also find in this directory a few storage class files.

You can decide to use all of them, only a subset of them or modify them as you wish

```bash
[root@rhel5 config_block]# kubectl create -f sc-csi-ontap-san.yaml
storageclass.storage.k8s.io/sc-block-rwo created

[root@rhel5 config_block]# kubectl create -f sc-csi-ontap-san-eco.yaml
storageclass.storage.k8s.io/sc-block-rwo-eco created
```

Feel free to see how your Grafana dashborad has updated since you added the backends and storageclasses.

## C. What's next

Now, you have some SAN Backends & some storage classes configured. You can proceed to the creation of a stateful application:  
- [Deploy your first app with Block storage](../block_app)  

or stay in the dev cluster to:

- [Specify a default storage class](../default_sc)  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#dev-k8s-cluster-tasks)
