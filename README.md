# LabNetApp

## A. Trident with K8s (with CSI)

The section has been tested with the Lab-on-Demand Using "Trident with Kubernetes and ONTAP v3.1" which comes by default with Trident 19.07 already installed on Kubernetes 1.15.3. The configure.sh will modify the environment by:

- Installing and creating a MetalLB configuration
- Upgading k8s to 1.18
- Modify add rhel4 node to the production cluster
- Initialize and configure a 2nd k8s cluster (nodes rhel5 and rhel6)
- Install and configure Prometheus and Grafana dashboards
- Install and configure Trident with an Operator

<<< Overview diagram by Horner>>>

:boom:  
Most labs will be done by connecting with Putty to the RHEL3 host (root/Netapp1!).  
I assume each scenario will be run in its own directory. Also, you will find a README file for each scenario.  

Last, there are plenty of commands to write or copy/paste.  
Most of them start with a '#', usually followed by the result you would get.  
:boom:  

<<< Common vi commands to be included>>>

### Tasks

---------
[1.](Trident_with_K8s/Tasks/Task_1) Install/Upgrade Trident with an Operator  
[2.](Trident_with_K8s/Tasks/Task_2) Install Prometheus & incorporate Trident's metrics  
[3.](Trident_with_K8s/Tasks/Task_3) Configure Grafana & add your first graphs  
[4.](Trident_with_K8s/Tasks/Task_4) Configure your first NAS backends & storage classes  
[5.](Trident_with_K8s/Tasks/Task_5) Deploy your first app with File storage  
[6.](Trident_with_K8s/Tasks/Task_6) Configure your first iSCSI backends & storage classes  
[7.](Trident_with_K8s/Tasks/Task_7) Deploy your first app with Block storage  
[8.](Trident_with_K8s/Tasks/Task_8) Use the 'import' feature of Trident  
[9.](Trident_with_K8s/Tasks/Task_9) Consumption control  
[10.](Trident_with_K8s/Tasks/Task_10) Resize a NFS CSI PVC  
[11.](Trident_with_K8s/Tasks/Task_11) Using Virtual Storage Pools  
[12.](Trident_with_K8s/Tasks/Task_12) StatefulSets & Storage consumption  
[13.](Trident_with_K8s/Tasks/Task_13) Resize a iSCSI CSI PVC  
[14.](Trident_with_K8s/Tasks/Task_14) On-Demand Snapshots & Create PVC from Snapshot  
[15.](Trident_with_K8s/Tasks/Task_15) Dynamic export policy management  

### Addendum

---------
[0.](Trident_with_K8s/Addendum/Addenda00) Useful commands  
[1.](Trident_with_K8s/Addendum/Addenda01) Add a node to the cluster  
[2.](Trident_with_K8s/Addendum/Addenda02) Specify a default storage class  
[3.](Trident_with_K8s/Addendum/Addenda03) Allow user PODs on the master node  
[4.](Trident_with_K8s/Addendum/Addenda04) Upgrade your Kubernetes cluster (1.15 => 1.16 => 1.17 => 1.18)  
[5.](Trident_with_K8s/Addendum/Addenda05) Prepare ONTAP for block storage  
[6.](Trident_with_K8s/Addendum/Addenda06) Install Ansible on RHEL3 (Kubernetes Master)
