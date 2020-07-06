# LabNetApp

## A. Trident with K8s (with CSI)

The section has been tested with the Lab-on-Demand Using "Trident with Kubernetes and ONTAP v3.1" which comes by default with Trident 19.07 already installed on Kubernetes 1.15.3. The configure_bootcamp.sh will modify the environment by:

- Installing and creating a MetalLB configuration
- Upgading k8s to 1.18
- Add rhel4 as a worker node to the production k8s cluster
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

### Configuring the bootcamp k8s environment

Open the PuTTY console and connect to the kubernetes master node as root@rhel3. Run the below commands to configure the kubernetes clusters for the bootcamp:  

```bash
git clone <https://github.com/carlgranfelt/NetApp-LoD.git>  
cd /NetApp-LoD/Trident_with_K8s/deploy/  
chmod 744 *.sh  
. ./configure_bootcamp.sh
```

### Vim 101 commands

Vim is a “modal” text editor based on the vi editor. In Vim, the mode that the editor is in determines whether the alphanumeric keys will input those characters or move the cursor through the document. Listed below are some basic commands to move, edit, search and replace, save and quit.

|Vim Command             | Description
|------------------------|--------------------------------------------------------------|
| i                      | Enter insert mode |
| Esc                    | Enter command mode |
| x or Del               | Delete a character |
| X                      | Delete character is backspace mode |
| u                      | Undo the last operation |
| Ctrl + r               | Redo the last undo |
| yy                     | Copy a line |
| d                      | Starts the delete operation |
| dw                     | Delete a word |
| d0                     | Delete to the beginning of a line |
| d$                     | Delete to the end of a line |
| dd                     | Delete a line |
| p                      | Paste the content of the buffer |
| /<search_term>         | Search for text and then cycle through matches with n and N |
| [[ or gg               | Move to the beginning of a file |
| ]] or G                | Move to the end of a file |
| :%s/foo/bar/gci        | Search and replace all occurrences with confirmation |
| Esc + :w               | Save changes |
| Esc + :wq or Esc + ZZ  | Save and quit Vim |
| Esc + :q!              | Force quit Vim discarding all changes |

### Kubernetes web-based UI

For more information about the kuberenetes dashboard, please see:  
<https://github.com/kubernetes/dashboard>.

To access the dashboard from your local workstation you must create a secure channel to your Kubernetes cluster. Open a new SSH terminal to rhel3 and run the following command:  
`kubectl proxy`

Access the k8s dashboard from a web browser at:  
<http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/>.

Getting a Bearer Token  
Now we need to find token we can use to log in. Execute following command in the original terminal window:  
`kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')`

It should display something similar to below:
![Admin user token](images/dashboard-token.jpg "Admin user token")

Copy the token and paste it into Enter token field on the login screen.
![Kubernetes Dashboard Sign in](images/dashboard-sign-in.jpg "Kubernetes Dashboard Sign in")

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
