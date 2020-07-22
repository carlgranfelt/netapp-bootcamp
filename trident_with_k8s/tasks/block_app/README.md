# Create your first App with Block (RWO) storage

**GOAL:**  
We will deploy the same App as in file-base application task, but instead of using RWX storage, we will use RWO Block Storage.

For this task you will be deploying Ghost (a light weight web portal) utlilising RWO (Read Write Once) file-based persistent storage over iSCSI.  You will find a few .yaml files in the Ghost directory, so ensure that your putty terminal on the lab is set to the correct directory for this task:

```bash
[root@rhel3 ~]# cd /root/NetApp-LoD/trident_with_k8s/tasks/block_app/ghost
```
The .yaml files provided are for:

- A PVC to manage the persistent storage of this app
- A DEPLOYMENT that will define how to manage the app
- A SERVICE to expose the app

Feel free to familiarise yourself with the contents of these .yaml files if you wish.  You will see in the ```1_pvc.yaml``` file that it specifies ReadWriteOnce as the access mode, which will result in k8s and Trident providing an iSCSI based backend for the request.  A diagram is provided below to illustrate how the PVC, deployment, service and surrounding infrastructure all hang together:

<p align="center"><img src="Images/block_app.png" width="650px"></p>

## Create the App

It is assumed that the required backend & storage class have [already been created](../config_file) either by you or your bootcamp fascilitator.

We will create this app in its own namespace (which also makes clean-up easier):
```bash
[root@rhel3 ~]# kubectl create namespace ghostsan
namespace/ghostsan created
```
Next, we apply the .yaml configuration within the new namespace:
```bash
[root@rhel3 ~]# kubectl create -n ghostsan -f ../ghost/
persistentvolumeclaim/blog-content created
deployment.apps/blog created
service/blog created
```
Display all resources for the ghost namespace (your specific pod name of blog-XXXXXXXX-XXXX will be unique to your deployment and will need to be used again later in this task):
```bash
[root@rhel3 ~]# kubectl get all -n ghostsan
NAME                            READY   STATUS    RESTARTS   AGE
pod/blog-san-58979448dd-6k9ds   1/1     Running   0          21s

NAME               TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/blog-san   NodePort   10.99.208.171   <none>        80:30080/TCP   17s

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/blog-san   1/1     1            1           21s

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/blog-san-58979448dd   1         1         1       21s
```
Display the PV and PVC associated with your app:
```bash
[root@rhel3 ~]# kubectl get pvc,pv -n ghostsan
NAME                                     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
persistentvolumeclaim/blog-content-san   Bound    pvc-8ff8c1b3-48da-400e-893c-23bc9ec459ff   10Gi       RWO            sc-block-rwo   4m16s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                       STORAGECLASS        REASON   AGE
persistentvolume/pvc-8ff8c1b3-48da-400e-893c-23bc9ec459ff   10Gi       RWO            Delete           Bound    ghostsan/blog-content-san   sc-block-rwo            4m15s
```

## B. Access the app

It takes about 40 seconds for the POD to be in a *running* state
The Ghost service is configured with a NodePort type, which means you can access it from every node of the cluster on port 30080.
Give it a try !
=> <http://192.168.0.63:30090>

## C. Explore the app container

Let's see if the */var/lib/ghost/content* folder is indeed mounted to the SAN PVC that was created.
**You need to customize the following commands with the POD name you have in your environment.**

```
[root@rhel3 ~]# kubectl exec -n ghostsan blog-san-58979448dd-6k9ds -- df /var/lib/ghost/content
Filesystem           1K-blocks      Used Available Use% Mounted on
/dev/sdc              10190100     37368   9612060   0% /var/lib/ghost/content
```
List out the files found in the ghost/content directory within the PV (don't forget to use your specific blog-XXXXXXXX-XXXX details found in the earlier CLI output):
```bash
[root@rhel3 ~]# kubectl exec -n ghostsan blog-san-58979448dd-6k9ds -- ls /var/lib/ghost/content
apps
data
images
logs
lost+found
settings
themes
```

It is recommended that you also monitor your environment from the pre-created dashboard in Grafana: (<http://192.168.0.141>).  If you carried out the tasks in the [verifying your environment](../verify_lab) task, then you should already have your Grafana username and password which is ```admin:admin``` by default and you will be promted for a new password on 1st login.

## D. Cleanup

Instead of deleting each object one by one, you can directly delete the namespace which will then remove all of its objects.

```bash
[root@rhel3 ~]# kubectl delete ns ghostsan
namespace "ghostsan" deleted
```

## E. What's next

Now that you have tried working with SAN backends, you can try to resize a PVC:
- [Task_13](../Task_13): Resize a iSCSI CSI PVC  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md)