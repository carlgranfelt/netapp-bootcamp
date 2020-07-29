# Dynamic Export Policy Management

**GOAL:**  
The 20.04 release of CSI Trident provides the ability to dynamically manage export policies for ONTAP backends.  

Letting Trident manage the export policies allows you to reduce the amount of administrative tasks, especially when clusters scale up & down.  Further information on Dynamic Exports with Trident can be found in the [official documentation](https://netapp-trident.readthedocs.io/en/stable-v20.04/kubernetes/operations/tasks/backends/ontap.html#dynamic-export-policies-with-ontap-nas).

The configuration of this feature is done in the Trident Backend object. There 2 different json files in this directory that will help you discover how to use it.  

2 options can be used here:  

- `autoExportPolicy`: enables the feature
- `autoExportCIDRs`: defines the address blocks to use (optional parameter)

This lab is mainly aimed at storage administrators familiar with NetApp ONTAP, so will not be applicable to the day-to-day work on a developer, but is still useful information to be aware of.

## A. Create 2 new backends

Ensure you are in the correct working directory by issuing the following command on your rhel3 putty terminal in the lab:

```bash
[root@rhel3 ~]# cd /root/NetApp-LoD/trident_with_k8s/tasks/dynamic_exports/
```

The difference between both files lies in the *autoExportCIDRs* parameter, one has it while the other one does not.

```bash
[root@rhel3 ~]# tridentctl -n trident create backend -f backend-with-CIDR.json
+------------------+----------------+--------------------------------------+--------+---------+
|       NAME       | STORAGE DRIVER |                 UUID                 | STATE  | VOLUMES |
+------------------+----------------+--------------------------------------+--------+---------+
| Export_with_CIDR | ontap-nas      | ebf1efb0-e8c6-457e-8e1a-827b1725ed9e | online |       0 |
+------------------+----------------+--------------------------------------+--------+---------+

[root@rhel3 ~]# tridentctl -n trident create backend -f backend-without-CIDR.json
+---------------------+----------------+--------------------------------------+--------+---------+
|        NAME         | STORAGE DRIVER |                 UUID                 | STATE  | VOLUMES |
+---------------------+----------------+--------------------------------------+--------+---------+
| Export_without_CIDR | ontap-nas      | f9683c16-e35c-4fea-b185-2e0d7eea0eb3 | online |       0 |
+---------------------+----------------+--------------------------------------+--------+---------+
```

## B. Check the export policies

Now, retrieve the IP adresses of all nodes of the cluster:

```bash
[root@rhel3 ~]# kubectl get nodes -o=custom-columns=NODE:.metadata.name,IP:.status.addresses[0].address
NODE    IP
rhel1   192.168.0.61
rhel2   192.168.0.62
rhel3   192.168.0.63
rhel4   192.168.0.64
```

Let's see how that translate into ONTAP. Open a new Putty session on 'cluster1', using admin/Netapp1!  

What export policies do we see:

```bash
cluster1::> export-policy show
Vserver          Policy Name
---------------  -------------------
svm1             default
svm1             trident-ebf1efb0-e8c6-457e-8e1a-827b1725ed9e
svm1             trident-f9683c16-e35c-4fea-b185-2e0d7eea0eb3
3 entries were displayed.
```

The `default` policy is always present, while the 2 other ones were dynamically created by Trident.  

Notice that the name of the policy contains the UUID of the Trident Backend.  

Now, let's look at the rule set by Trident for the backend `Export_with_CIDR`:  

```bash
cluster1::> export-policy rule show -vserver svm1 -policyname trident-ebf1efb0-e8c6-457e-8e1a-827b1725ed9e
             Policy          Rule    Access   Client                RO
Vserver      Name            Index   Protocol Match                 Rule
------------ --------------- ------  -------- --------------------- ---------
svm1         trident-ebf1efb0-e8c6-457e-8e1a-827b1725ed9e
                             1       nfs      192.168.0.62          any
svm1         trident-ebf1efb0-e8c6-457e-8e1a-827b1725ed9e
                             2       nfs      192.168.0.61          any
svm1         trident-ebf1efb0-e8c6-457e-8e1a-827b1725ed9e
                             3       nfs      192.168.0.63          any
svm1         trident-ebf1efb0-e8c6-457e-8e1a-827b1725ed9e
                             4       nfs      192.168.0.64          any
4 entries were displayed.
```

You can see that there is a rule for every single node present in the cluster. No other host will be able to mount a resource present on this tenant, unless an admin manually adds more rules.  

Then, let's look at the rule set by Trident for the backend `Export_without_CIDR`:

```bash
cluster1::> export-policy rule show -vserver svm1 -policyname trident-f9683c16-e35c-4fea-b185-2e0d7eea0eb3
             Policy          Rule    Access   Client                RO
Vserver      Name            Index   Protocol Match                 Rule
------------ --------------- ------  -------- --------------------- ---------
svm1         trident-f9683c16-e35c-4fea-b185-2e0d7eea0eb3
                             1       nfs      10.44.0.0,172.17.0.1, any
                                              192.168.0.62
svm1         trident-f9683c16-e35c-4fea-b185-2e0d7eea0eb3
                             2       nfs      10.36.0.0,172.17.0.1, any
                                              192.168.0.61
svm1         trident-f9683c16-e35c-4fea-b185-2e0d7eea0eb3
                             3       nfs      10.32.0.1,172.17.0.1, any
                                              192.168.0.63
svm1         trident-f9683c16-e35c-4fea-b185-2e0d7eea0eb3
                             4       nfs      10.32.0.1,172.17.0.1, any
                                              192.168.0.64
4 entries were displayed.
```

Notice the difference?  

Before creating the rules, Trident looked at all the unicast IP addresses on each node & used them on the storage backend.  

Also, as stated in the documentation, you must ensure that the root junction in your SVM has a pre-created export policy with an export rule that permits the node CIDR block (such as the *default* export policy). All volumes created by Trident are mounted under the root junction.  

Let's look at what we have in the Lab On Demand:

```bash
cluster1::> export-policy rule show -vserver svm1 -policyname default
             Policy          Rule    Access   Client                RO
Vserver      Name            Index   Protocol Match                 Rule
------------ --------------- ------  -------- --------------------- ---------
svm1         default         1       nfs      0.0.0.0/0             any
```

There you go.  Now, all applications created with these backends are going to have access to storage, while adding an extra level of security.

If you were to add a new node to the Production k8s cluster, Trident will automatically add that node's IP to the export list.  Unfortunatley, as we have maxed out the resources available to us, we can't add another worker node to the cluster.

## D. Finally some optional cleanup

```bash
[root@rhel3 ~]# tridentctl -n trident delete backend Export_with_CIDR
[root@rhel3 ~]# tridentctl -n trident delete backend Export_without_CIDR
```

## E. What's next

You may have gone through all tasks.  

Why not try and set up the Dev cluster from scratch with a [new Trident install](../install_trident) and different [storage-classes](../config_file)?

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
