# LabNetApp

## A. Trident with K8s (with CSI)

The section has been tested with the Lab-on-Demand Using "Trident with Kubernetes and ONTAP v3.1" which comes by default with Trident 19.07 already installed on Kubernetes 1.15.3. The configure.sh will modify the environment by 
- Installing and creating a MetalLB configuration
- Upgading k8s to 1.18
- Initialize and configure a 2nd k8s cluster
- Install and configure Prometheus and Grafana dashboards
- Install and configure Trident with an Operator

<<< Overview diagram by Horner>>>

:boom:  
Most labs will be done by connecting with Putty to the RHEL3 host (root/Netapp1!).  
I assume each scenario will be run in its own directory. Also, you will find a README file for each scenario.  

Last, there are plenty of commands to write or copy/paste.  
Most of them start with a '#', usually followed by the result you would get.  
:boom:  

Tasks
---------
[1.](Trident with K8s/Tasks/Task 1) Install/Upgrade Trident 
111.  Trident with K8s\Tasks\Task 1 Install/Upgrade Trident with Operator
[2.](Kubernetes_v2/Scenarios/Scenario02) Install Prometheus & incorporate Trident's metrics  
[3.](Kubernetes_v2/Scenarios/Scenario03) Configure Grafana & add your first graphs  
[4.](Kubernetes_v2/Scenarios/Scenario04) Configure your first NAS backends & storage classes  
[5.](Kubernetes_v2/Scenarios/Scenario05) Deploy your first app with File storage  
[6.](Kubernetes_v2/Scenarios/Scenario06) Configure your first iSCSI backends & storage classes  
[7.](Kubernetes_v2/Scenarios/Scenario07) Deploy your first app with Block storage  
[8.](Kubernetes_v2/Scenarios/Scenario08) Use the 'import' feature of Trident  
[9.](Kubernetes_v2/Scenarios/Scenario09) Consumption control  
[10.](Kubernetes_v2/Scenarios/Scenario10) Resize a NFS CSI PVC  
[11.](Kubernetes_v2/Scenarios/Scenario11) Using Virtual Storage Pools  
[12.](Kubernetes_v2/Scenarios/Scenario12) StatefulSets & Storage consumption  
[13.](Kubernetes_v2/Scenarios/Scenario13) Resize a iSCSI CSI PVC  
[14.](Kubernetes_v2/Scenarios/Scenario14) On-Demand Snapshots & Create PVC from Snapshot  
[15.](Kubernetes_v2/Scenarios/Scenario15) Dynamic export policy management  

Addendum
--------
[0.](Kubernetes_v2/Addendum/Addenda00) Useful commands    
[1.](Kubernetes_v2/Addendum/Addenda01) Add a node to the cluster  
[2.](Kubernetes_v2/Addendum/Addenda02) Specify a default storage class  
[3.](Kubernetes_v2/Addendum/Addenda03) Allow user PODs on the master node  
[4.](Kubernetes_v2/Addendum/Addenda04) Upgrade your Kubernetes cluster (1.15 => 1.16 => 1.17 => 1.18)  
[5.](Kubernetes_v2/Addendum/Addenda05) Prepare ONTAP for block storage  
[6.](Kubernetes_v2/Addendum/Addenda06) Install Ansible on RHEL3 (Kubernetes Master)