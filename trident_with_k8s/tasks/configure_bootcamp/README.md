# Configuring the Bootcamp Lab

If you wish to jump straight into the bootcamp and start deploying stateful applications on block and file storage, then you will need to run the configure_bootcamp.sh script first.  

**The person running your particular bootcamp may have already had this script run on your lab, so please check with them ahead of executing it.**

Open the PuTTY console within the lab and connect to the kubernetes master node (RHEL3) as ```root@rhel3```.  The connection should be all set up for you in Putty. 

Once connected to the k8s master, run the below commands to configure the kubernetes clusters for the bootcamp:  

Download the contents of the bootcamp GitHub repo to the k8s master:

```bash
git clone https://github.com/carlgranfelt/NetApp-LoD.git
```

Change directory to the deploy directory:
```bash
cd /root/NetApp-LoD/trident_with_k8s/deploy/
```

Change the permissions of the shell script to allow execution:

```bash
chmod 744 *.sh
```

Run the configuration script

```bash
time . ./configure_bootcamp.sh &>> configure_bootcamp.log
```

Once running, the script will take ~15 minutes to complete.  Tasks the script carries out are:

* Prod and Dev Clusters
  * Installing and creating a MetalLB configuration
  * Initialize and configure a dev k8s cluster (nodes rhel5 and rhel6)
  * Upgading k8s to 1.18
  * Install Ansible
* Prod Cluster Only
  * Add rhel4 as a worker node to the production k8s cluster
  * Install and configure Prometheus and Grafana dashboards
  * Install and configure lastest Trident with an Operator
  * Create and configure storage backends and storage classes
  * Install k8s dashboard
  * Install k8s metrics server

The Dev cluster has purposely been only configured with an upgraded k8s cluster and MetalLB.  This leaves you with a separate cluster if you wish to carry out tasks such as [installing Trident](/trident_with_k8s/tasks/install_trident) and [configuring storage backends](/trident_with_k8s/tasks/config_file).

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md)