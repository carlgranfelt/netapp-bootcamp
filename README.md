<p align="center"><img src="images/k8s-header.png"></p>

# NetApp Trident Bootcamp

## Trident with k8s

This bootcamp requires the [NetApp Lab-on-Demand](https://labondemand.netapp.com/) "Trident with Kubernetes and ONTAP v3.1" lab which comes with Trident 19.07 already installed on Kubernetes 1.15.3. The provided [configure_bootcamp.sh](trident_with_k8s/deploy/configure_bootcamp.sh) within this repo will modify the environment to be ready for the tasks within this bootcamp to be carried out.

**The configure_bootcamp.sh script may be run by the NetApp Lab On Demand team ahead of you connecting to the lab environment, so please confirm this with the person running your particular bootcamp.**  If it has not been run, it can take ~15 minutes to complete, so please run it now by following the instructions [here](trident_with_k8s/tasks/configure_bootcamp) where you will also find details of the tasks carried out by the script.

### Bootcamp Environment Diagram

<p align="center"><img src="images/lab-diagram.png"></p>

To familiarise yourself with the environment and check that everything is raedy for you to begin, please follow the instructions in [Task 1](trident_with_k8s/tasks/validate_lab).  Once you are happy with your lab, you can choose to jump into any of the tasks listed below.  They do not need to be followed in any particular order, but if persistent storage is a new concept for you within k8s, it is recomended to folow them one-by-one.  If you do jumop ahead, any pre-requisite tasks will be called out for you.

### Vim 101 commands

We will be using Vim to edit configuration files as part of this bootcamp.  If you are unfamiliar with Vim, a [basic set of instructions](trident_with_k8s/tasks/vim) has been created for you to keep open in a separate browser tab for reference

### Prod k8s Cluster Tasks

---------

[1.](trident_with_k8s/tasks/verify_lab)Verify and navigate the lab environment
[2.](trident_with_k8s/tasks/file_app) Deploy your first app with File storage  
[3.](trident_with_k8s/tasks/block_app) Deploy your first app with Block storage  
[4.](trident_with_k8s/tasks/pv_import) Use the 'import' feature of Trident  
[5.](trident_with_k8s/tasks/quotas) Consumption control  
[6.](trident_with_k8s/tasks/file_resize) Resize a NFS CSI PVC  
[7.](trident_with_k8s/tasks/storage_pools) Using Virtual Storage Pools  
[8.](trident_with_k8s/tasks/statefulsets) StatefulSets & Storage consumption  
[9.](trident_with_k8s/tasks/resize_block) Resize a iSCSI CSI PVC  
[10.](trident_with_k8s/tasks/snapshots_clones) On-Demand Snapshots & Create PVC from Snapshot  
[11.](trident_with_k8s/tasks/dynamic_exports) Dynamic export policy management  

### Dev k8s Cluster Tasks
If you would like to carry out some of the tasks performed for you by the configure_bootcamp.sh script, below are the commands required.  These can be useful if you wish to become familar with tasks such as installing Trident or defining storage classes

---------
[0.](trident_with_k8s/tasks/useful_commands) Useful commands  
[1.](trident_with_k8s/tasks/install_trident) Install/Upgrade Trident with an Operator  
[2.](trident_with_k8s/tasks/config_prometheus) Install Prometheus & incorporate Trident's metrics  
[3.](trident_with_k8s/tasks/config_grafana) Configure Grafana & add your first graphs  
[4.](trident_with_k8s/tasks/config_file) Configure your first NAS backends & storage classes  
[5.](trident_with_k8s/tasks/config_block) Configure your first iSCSI backends & storage classes  
[6.](trident_with_k8s/tasks/default_sc) Specify a default storage class  
[7.](trident_with_k8s/tasks/ontap_block) Prepare ONTAP for block storage on dev cluster 

# Below should be moved to the lab varification section

```

### Kubernetes web-based UI

For more information about the kuberenetes dashboard, please see:  
<https://github.com/kubernetes/dashboard>.

Access the k8s dashboard from a web browser at:  
<https://192.168.0.142/>.  

Click on **Advanced** in the 'Your connecton is not private' window, follwed by 'Proceed to 192.168.0.142 (unsafe)'.

Getting a Bearer Token  
Now we need to find token we can use to log in. Execute following command in the original terminal window:  
`kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')`

It should display something similar to below:
![Admin user token](images/dashboard-token.jpg "Admin user token")

Copy the token and paste it into Enter token field on the login screen.
![Kubernetes Dashboard Sign in](images/dashboard-sign-in.jpg "Kubernetes Dashboard Sign in")

 ```
