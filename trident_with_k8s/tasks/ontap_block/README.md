# Prepare your ONTAP Backend for Block Storage

**GOAL:**  
The ONTAP environment in the Lab on Demand has already been setup for both block and file storage.
You can choose to use the storage you are already using, SVM1, or create your own.

In the latter task, you will need to create a new SVM with the following parameters:  

- iSCSI data LIF: 192.168.0.123
- iSCSI igroup: trident
- iSCSI target alias: svm2

If you feel confortable with ONTAP, you can create the environment yourself either using the CLI or GUI (ONTAP System Manager).
Alternatively, it can be scripted for example using Ansible.

## A. Using the ONTAP CLI to create a new SVM

Open the PuTTY console on the jumphost within the lab and connect to the cDOT cluster as admin@cluster1. The session is already set up for you in PuTTY. Finally run the below commands:  

```bash
cluster1::> vserver create -vserver svm2 -rootvolume svm2_root -aggregate aggr2  -data-services data-iscsi,data-nfs
[Job 582] Job succeeded:
Vserver creation completed.

cluster1::> vserver modify -vserver svm2 -disallowed-protocols cifs,fcp,ndmp -aggr-list aggr1,aggr2  
Warning: This command modifies the allowed-protocols list of Vserver "svm2" from "nfs cifs fcp iscsi
         ndmp" to "nfs, iscsi". The following protocols will be stopped, potentially causing data
         disruptions: cifs fcp ndmp. Note: a modify operation on these parameters is deprecated and
         may be removed in future releases of Data ONTAP. To add or remove protocols use the "vserver
         add-protocols" or "vserver remove-protocols" commands.
Do you want to continue? {y|n}: y

cluster1::> lun igroup create -igroup trident -protocol iscsi -ostype linux -vserver svm2  
cluster1::> net interface create -vserver svm2 -lif svm2_nfs_01 -data-protocol nfs -home-node cluster1-01 -home-port e0d -subnet-name Demo -firewall-policy data
  (network interface create)

cluster1::> net interface create -vserver svm2 -lif svm2_iscsi_01 -data-protocol iscsi -home-node cluster1-01 -home-port e0d -address 192.168.0.123 -netmask 255.255.255.0 -firewall-policy data
  (network interface create)

cluster1::> vserver iscsi create -target-alias svm2 -vserver svm2  
```

**Please note:** The above commands also create a network interface for the NFS protocol that can be used in subsequent tasks on the dev kubernetes cluster to request persistent file storage.  

## B. Using Ansible to create a new SVM

TBC.

## C. What's next

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
