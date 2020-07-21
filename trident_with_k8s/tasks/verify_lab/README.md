# Verifying the Lab Environment

The objective for this first task is to familiarize yourself with the environment and verify all pre-installed kubernetes objects are present and ready.

## A. Production Kubernetes Cluster

The production k8s cluster contains a single master node (rhel3) and three worker nodes ( rhel1, rhel2 and rhel4).
To verify the nodes:  
`kubectl get nodes -o wide`

Your output should be similar to below, all nodes with a "Ready" status with kubernetes 1.18 installed.  

```bash
[root@rhel3 ~]# kubectl get nodes -o wide
NAME    STATUS   ROLES    AGE    VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                                      KERNEL-VERSION          CONTAINER-RUNTIME
rhel1   Ready    <none>   316d   v1.18.0   192.168.0.61   <none>        Red Hat Enterprise Linux Server 7.5 (Maipo)   3.10.0-862.el7.x86_64   docker://18.9.1
rhel2   Ready    <none>   316d   v1.18.0   192.168.0.62   <none>        Red Hat Enterprise Linux Server 7.5 (Maipo)   3.10.0-862.el7.x86_64   docker://18.9.1
rhel3   Ready    master   316d   v1.18.0   192.168.0.63   <none>        Red Hat Enterprise Linux Server 7.5 (Maipo)   3.10.0-862.el7.x86_64   docker://18.9.1
rhel4   Ready    <none>   179m   v1.18.0   192.168.0.64   <none>        Red Hat Enterprise Linux Server 7.5 (Maipo)   3.10.0-862.el7.x86_64   docker://18.9.1
[root@rhel3 ~]#
```

To verify your k8s cluster is ready for use:  
`kubectl cluster-info`  
`kubectl get componentstatus`

Your output should be similar to below, Kubernetes master running at <https://192.168.0.63:6443> and all components with a "Healthy" status.  

```bash
[root@rhel3 ~]# kubectl cluster-info
Kubernetes master is running at https://192.168.0.63:6443
KubeDNS is running at https://192.168.0.63:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
[root@rhel3 ~]# kubectl get componentstatus
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health":"true"}
[root@rhel3 ~]#
```

To list all namespaces:  
`kubectl get namespaces`

The default and kubernetes specific kube-* should be listed together with the additionally created namespaces for the kubernetes dashboard, metallb load-balancer, monitoring for Prometheus & Grafana and Trident.  

```bash
[root@rhel3 ~]# kubectl get namespaces
NAME                   STATUS   AGE
default                Active   316d
kube-node-lease        Active   316d
kube-public            Active   316d
kube-system            Active   316d
kubernetes-dashboard   Active   3h31m
metallb-system         Active   3h43m
monitoring             Active   3h33m
trident                Active   3h33m
[root@rhel3 ~]#
```

## B. Trident Operator

Trident 20.04 introduced a new way to manage its lifecycle: Operators.  
With Trident 20.04, there are new objects in the picture:

- Trident Operator, which will dynamically manage Trident's resources, automate setup, fix broken elements  
- Trident Provisioner, which is a Custom Resource, and is the object you will use to interact with the Trident Operator for specific tasks (upgrades, enable/disable Trident options, such as _debug_ mode, uninstall)  

You can visualize the *Operator* as being the *Control Tower*, and the *Provisioner* as being the *Mailbox* in which you post configuration requests.
Other operations, such as Backend management or viewing logs are currently still managed by Tridentctl.

:mag:  
*A* **resource** *is an endpoint in the Kubernetes API that stores a collection of API objects of a certain kind; for example, the built-in pods resource contains a collection of Pod objects.*  
*A* **custom resource** *is an extension of the Kubernetes API that is not necessarily available in a default Kubernetes installation. It represents a customization of a particular Kubernetes installation. However, many core Kubernetes functions are now built using custom resources, making Kubernetes more modular.*  
:mag_right:  

To verify that the Trident Custom Resource Definitions have been installed:

```bash
[root@rhel3 ~]# kubectl get crd
NAME                                      CREATED AT
...
tridentbackends.trident.netapp.io         2020-07-21T08:01:28Z
tridentnodes.trident.netapp.io            2020-07-21T08:01:30Z
tridentprovisioners.trident.netapp.io     2020-07-21T08:00:50Z
tridentsnapshots.trident.netapp.io        2020-07-21T08:01:31Z
tridentstorageclasses.trident.netapp.io   2020-07-21T08:01:29Z
tridenttransactions.trident.netapp.io     2020-07-21T08:01:31Z
tridentversions.trident.netapp.io         2020-07-21T08:01:28Z
tridentvolumes.trident.netapp.io          2020-07-21T08:01:29Z
...
```

Next observe the status of the TridentProvisioner. The status should be _installed_ for the provisioner CRD:

```bash
[root@rhel3 ~]# kubectl get tprov -n trident
NAME      AGE
trident   9h
[root@rhel3 ~]# kubectl describe tprov trident -n trident
Name:         trident
Namespace:    trident
Labels:       <none>
Annotations:  <none>
API Version:  trident.netapp.io/v1
Kind:         TridentProvisioner
Metadata:
  Creation Timestamp:  2020-07-21T08:01:22Z
  Generation:          1
  Managed Fields:
    API Version:  trident.netapp.io/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:spec:
        .:
        f:debug:
    Manager:      kubectl
    Operation:    Update
    Time:         2020-07-21T08:01:22Z
    API Version:  trident.netapp.io/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        .:
        f:message:
        f:status:
        f:version:
    Manager:         trident-operator
    Operation:       Update
    Time:            2020-07-21T08:02:03Z
  Resource Version:  514288
  Self Link:         /apis/trident.netapp.io/v1/namespaces/trident/tridentprovisioners/trident
  UID:               77d0eaa9-ac73-4990-b57a-58817948e414
Spec:
  Debug:  true
Status:
  Message:  Trident installed
  Status:   Installed
  Version:  v20.04
Events:
  Type    Reason     Age                   From                        Message
  ----    ------     ----                  ----                        -------
  Normal  Installed  3m34s (x117 over 9h)  trident-operator.netapp.io  Trident installed
```

You can also confirm if the Trident install completed by taking a look at the pods that have been created. Confirm that the Trident Operator, Provisioner and a CSI driver per node (part of the deamonset) are all up & running:

```bash
[root@rhel3 ~]# kubectl get all -n trident
NAME                                    READY   STATUS    RESTARTS   AGE
pod/trident-csi-788b4d865c-xdzn7        5/5     Running   0          8h
pod/trident-csi-gn4cv                   2/2     Running   0          8h
pod/trident-csi-q2w6c                   2/2     Running   0          8h
pod/trident-csi-rdpjk                   2/2     Running   0          8h
pod/trident-csi-x8ppp                   2/2     Running   0          8h
pod/trident-operator-668bf8cdff-577p9   1/1     Running   0          8h

NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)              AGE
service/trident-csi   ClusterIP   10.105.145.190   <none>        34571/TCP,9220/TCP   8h

NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                     AGE
daemonset.apps/trident-csi   4         4         4       4            4           kubernetes.io/arch=amd64,kubernetes.io/os=linux   8h

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/trident-csi        1/1     1            1           8h
deployment.apps/trident-operator   1/1     1            1           8h

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/trident-csi-788b4d865c        1         1         1       8h
replicaset.apps/trident-operator-668bf8cdff   1         1         1       8h
[root@rhel3 ~]#
```

You can also use tridentctl to check the version of Trident installed:

```bash
[root@rhel3 ~]# tridentctl -n trident version
+----------------+----------------+
| SERVER VERSION | CLIENT VERSION |
+----------------+----------------+
| 20.04.0        | 20.04.0        |
+----------------+----------------+
[root@rhel3 ~]#
```

Because of the CRD extension of the Kubernetes API we can also use kubectl to interact with Trident and for example check the version of Trident installed:

```bash
[root@rhel3 ~]# kubectl -n trident get tridentversions
NAME      VERSION
trident   20.04.0
[root@rhel3 ~]#
```

## C. Backends and StorageClasses

Trident needs to know where to create volumes. This information sits in objects called backends. It basically contains:  

- The driver type (there are currently 10 different drivers available)
- How to connect to the driver (IP, login, password ...)
- Some default parameters

For additional information, please refer to the official NetApp Trident documentation on Read the Docs:

- <https://netapp-trident.readthedocs.io/en/latest/kubernetes/tridentctl-install.html#create-and-verify-your-first-backend>
- <https://netapp-trident.readthedocs.io/en/latest/kubernetes/operations/tasks/backends/index.html>

Once you have configured backend, the end user will create Persistent Volume Claims (PVCs) against Storage Classes.  
A storage class contains the definition of what an app can expect in terms of storage, defined by some properties (access type, media, driver ...)

For additional information, please refer to:

- <https://netapp-trident.readthedocs.io/en/latest/kubernetes/concepts/objects.html#kubernetes-storageclass-objects>

Installing & configuring Trident as well as creating Kubernetes Storage Classes is what is expected to be done upfront by the Admin and as such has already been done in this lab for you.

Next let's verify what backends have been pre-created for us.  

**Note:** Again we can use both kubectl and tridentctl to get the information.  

```bash
[root@rhel3 ~]# kubectl -n trident get tridentbackends
NAME        BACKEND               BACKEND UUID
tbe-cgx2q   ontap-block-rwo-eco   db6293a4-476e-479b-90e4-ab78372dfd04
tbe-dljs6   ontap-block-rwo       6ca0fb82-7c42-4319-a039-6d15fbdf0f3d
tbe-sh9gm   ontap-file-rwx        7b275998-e94f-4b88-b64c-5ff53ebd270e
tbe-zkwtj   ontap-file-rwx-eco    e6abe7bd-82fa-433c-a8d9-422a0b9dd635
[root@rhel3 ~]# tridentctl -n trident get backends
+---------------------+-------------------+--------------------------------------+--------+---------+
|        NAME         |  STORAGE DRIVER   |                 UUID                 | STATE  | VOLUMES |
+---------------------+-------------------+--------------------------------------+--------+---------+
| ontap-file-rwx      | ontap-nas         | 7b275998-e94f-4b88-b64c-5ff53ebd270e | online |       0 |
| ontap-file-rwx-eco  | ontap-nas-economy | e6abe7bd-82fa-433c-a8d9-422a0b9dd635 | online |       0 |
| ontap-block-rwo     | ontap-san         | 6ca0fb82-7c42-4319-a039-6d15fbdf0f3d | online |       0 |
| ontap-block-rwo-eco | ontap-san-economy | db6293a4-476e-479b-90e4-ab78372dfd04 | online |       0 |
+---------------------+-------------------+--------------------------------------+--------+---------+
```

We also need storage classes pointing to each backend:

```bash
[root@rhel3 ~]# kubectl get sc
NAME                    PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
sc-block-rwo            csi.trident.netapp.io   Delete          Immediate           false                  9h
sc-block-rwo-eco        csi.trident.netapp.io   Delete          Immediate           false                  9h
sc-file-rwx (default)   csi.trident.netapp.io   Delete          Immediate           true                   9h
sc-file-rwx-eco         csi.trident.netapp.io   Delete          Immediate           true                   9h
[root@rhel3 ~]# tridentctl -n trident get storageclasses
+------------------+
|       NAME       |
+------------------+
| sc-block-rwo-eco |
| sc-file-rwx      |
| sc-file-rwx-eco  |
| sc-block-rwo     |
+------------------+
```

At this point we can confirm that end-users are all set to create applications with persistent storage requirements in our lab environment :thumbsup:

## D. Prometheus & Grafana

Trident includes  metrics that can be integrated into Prometheus for an open-source monitoring solution. Grafana again is an open-source visualization software, allowing us to create a graph with many different metrics.  

Prometheus has been installed using the Helm prometheus-operator chart and exposed using the MetalLB load-balancer. For Prometheus to retrieve the metrics that Trident exposes, a ServiceMonitor has been created to watch the trident-csi service. Grafana in turn was setup by the Prometheus-operator, configured to use Prometheus as a data source and again exposed using the MetalLB load-balancer. Finally we have imported a custom dashboard for Trident into Grafana.  

To get the IP address for the Grafana service:  
`kubectl -n monitoring svc prom-operator-grafana`

```bash
[root@rhel3 ~]# kubectl -n monitoring get svc prom-operator-grafana
NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
prom-operator-grafana   LoadBalancer   10.108.152.56   192.168.0.141   80:30707/TCP   7h21m
[root@rhel3 ~]#
```

You can now access the Grafana GUI from a browser on the jumhost at <http://192.168.0.141>

### Accessing Grafana

The first time to enter Grafana, you are requested to login with a username & a password... But how does one find out what they are?  
Let's find the grafana pod and have a look at the pod definition, maybe there is a hint for us...

```bash
[root@rhel3 ~]# kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana
NAME                                     READY   STATUS    RESTARTS   AGE
prom-operator-grafana-5dd648d5bc-2g6dn   3/3     Running   0          7h40m

[root@rhel3 ~]# kubectl describe pod prom-operator-grafana-5dd648d5bc-2g6dn -n monitoring
...
 Environment:
      GF_SECURITY_ADMIN_USER:      <set to the key 'admin-user' in secret 'prom-operator-grafana'>      Optional: false
      GF_SECURITY_ADMIN_PASSWORD:  <set to the key 'admin-password' in secret 'prom-operator-grafana'>  Optional: false
...
```

Let's see what grafana secrets there are in this cluster:

```bash
[root@rhel3 ~]# kubectl get secrets -n monitoring -l app.kubernetes.io/name=grafana
NAME                    TYPE     DATA   AGE
prom-operator-grafana   Opaque   3      7h50m

[root@rhel3 ~]# kubectl describe secrets -n monitoring prom-operator-grafana
Name:         prom-operator-grafana
...
Data
====
admin-user:      5 bytes
admin-password:  5 bytes
...
```

OK, so the data is there, but its encrypted... However, the admin can retrieve this information:

```bash
[root@rhel3 ~]# kubectl get secret -n monitoring prom-operator-grafana -o jsonpath="{.data.admin-user}" | base64 --decode ; echo
admin
[root@rhel3 ~]# kubectl get secret -n monitoring prom-operator-grafana -o jsonpath="{.data.admin-user}" | base64 --decode ; echo
prom-operator
[root@rhel3 ~]#
```

Now we have the necessary clear text credentials to login to the Grafana UI at <http://192.168.0.141>.

## E. Kubernetes web-based UI

The kubernetes dashboard has been pre-installed and configured. Please use below steps to gain access to the UI.

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

For more information about the kuberenetes dashboard itself, please see:  
<https://github.com/kubernetes/dashboard>.

## F. What's next

Hopefully you are now more familiar with the lab environment and the Trident setup. You can move on to:  

- [Next task](../file_app): Deploy your first application using persistent file storage  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
