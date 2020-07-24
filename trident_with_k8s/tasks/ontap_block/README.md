# Prepare your ONTAP Backend for Block Storage

**GOAL:**  
The ONTAP environment in the Lab on Demand has already been setup for block storage.
You can choose to use the SVM you are already using, or create your own.

In the latter scenario, you will need to create a new SVM with the following parameters:  

- iSCSI Data LIF: 192.168.0.xxx
- iSCSI iGroup: trident

If you feel confortable with ONTAP, you can create the environment by yourself.
Otherwise, it can be scripted for example using Ansible roles.

To make it simple, below commands to run via SSH.
Open PuTTY, connect to cDOT "cluster1" and finally enter athe below commands:

```bash
vserver create -vserver svm2 -allowed-protocols nfs,iscsi
lun igroup create -igroup trident -protocol iscsi -ostype linux -vserver svm2
net interface create -vserver svm1 -lif svm1_iscsi -data-protocol iscsi -home-node cluster1-01 -home-port e0d -address 192.168.0.xxx -netmask 255.255.255.0 -firewall-policy data
vserver iscsi create -target-alias svm2 -vserver svm2
```

## What's next

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)