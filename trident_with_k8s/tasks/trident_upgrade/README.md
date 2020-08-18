# Upgrading with the Trident Operator

**Objective:**  
Trident 20.04 introduced a new way to manage its lifecycle: Operators. For Trident 20.04 this installation method is only intended for greenfield environments. With the release of Trident 20.07 the installation method is now also available for brownfield environments.  

This task provides an easy upgrade path for users that seek to use the operator and greatly simplify Trident’s operation. Trident will upgraded to the latest release, from the previous release (n-1) that got installed in [Trident installation with an Operator](../trident_install)  

For the official documentation describing all pre-requisites on upgrading with the Trident Operator, please see:  
<https://netapp-trident.readthedocs.io/en/latest/kubernetes/upgrades/operator-upgrade.html>

**Note:** All below commands are to be run against the dev cluster. Unless specified differently, please connect using PuTTY to the dev k8s cluster's master node (rhel5) to proceed with the task.  

### Optional tasks to demonstrate behaviour during upgrade

If you wish to see how applications behave during a Trident upgrade and also how applications can still be deployed during the upgrade, below are some optional tasks that you can carry out via Putty on the **`rhel5`** host as you move from Trident 20.04 to 20.07:

So that you can deploy a basic file-based application and block-based application, you will need to skip ahead and define a set of backends and storageclasses ([file](../config_file/) and [block](../config_block/)).  Once done, you will then be able to deploy (to the dev cluster) the [file application using the guide from the production tasks](../file_app/).  You can then use this application to see how it behaves during the upgrade.  The block app you can deploy mid-upgrade to show how new applications can still be deployed during this process.

## A. Remove existing Trident Operator Deployment

Connect using PuTTY to the dev k8s cluster's master node, **rhel5**, and remove any existing Trident Operator deployments.  

```bash
[root@rhel5 ~]# cd ~/trident-installer
[root@rhel5 trident-installer]# kubectl delete -f deploy/bundle.yaml
serviceaccount "trident-operator" deleted
clusterrole.rbac.authorization.k8s.io "trident-operator" deleted
clusterrolebinding.rbac.authorization.k8s.io "trident-operator" deleted
deployment.apps "trident-operator" deleted
podsecuritypolicy.policy "tridentoperatorpods" deleted
```

Now that the Trident Operator has been removed, if you are also doing the optional application deployments during this task, go ahead and deploy the block application to the dev cluster using [the guide from the production tasks](../block_app/).

You will see that applications can still be deployed while Trident is being upgraded and your original file application is also still running.

## B. Download & setup the latest Trident Operator release

Following this, you can now install the latest release of the operator by fetching the latest installer bundle and then re-installing the operator.

**Note:** We have only deleted the Trident Operator but the Custom Resource Definitions (CRD) are still present as is the trident namespace and all of the Trident Provisioner (CSI) components. The downloaded Trident Installer contains manifests for re-creating the resources with the desired version (latest).  

```bash
[root@rhel5 ~]# cd
[root@rhel5 ~]# mv trident-installer/ trident-installer_20.04
[root@rhel5 ~]# wget https://github.com/NetApp/trident/releases/download/v20.07.0/trident-installer-20.07.0.tar.gz
[root@rhel5 ~]# tar -xf trident-installer-20.07.0.tar.gz
[root@rhel5 ~]# cd trident-installer
[root@rhel5 trident-installer]# kubectl create -f deploy/bundle.yaml
serviceaccount/trident-operator created
clusterrole.rbac.authorization.k8s.io/trident-operator created
clusterrolebinding.rbac.authorization.k8s.io/trident-operator created
deployment.apps/trident-operator created
podsecuritypolicy.policy/tridentoperatorpods created
```

If we are quick enough to view all of the objects in the trident namespace we can notice that the trident-operator has already a running status and that the old csi pods are being terminated and new pods are in the process of being created.  

```bash
[root@rhel5 trident-installer]# kubectl get all -n trident
NAME                                    READY   STATUS        RESTARTS   AGE
pod/trident-csi-7bb4bfb84-xkznn         6/6     Running       0          26s
pod/trident-csi-dst64                   2/2     Running       0          26s
pod/trident-csi-jdjg2                   2/2     Terminating   0          13m
pod/trident-csi-kszxx                   2/2     Running       0          26s
pod/trident-csi-v2s7z                   2/2     Terminating   0          13m
pod/trident-operator-7f74ff5bb8-nggc4   1/1     Running       0          31s

NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)              AGE
service/trident-csi   ClusterIP   10.100.106.186   <none>        34571/TCP,9220/TCP   26s

NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                     AGE
daemonset.apps/trident-csi   2         2         2       2            2           kubernetes.io/arch=amd64,kubernetes.io/os=linux   26s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/trident-csi        1/1     1            1           26s
deployment.apps/trident-operator   1/1     1            1           31s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/trident-csi-7bb4bfb84         1         1         1       26s
replicaset.apps/trident-operator-7f74ff5bb8   1         1         1       31s

[root@rhel5 trident-installer]# kubectl get deployment -n trident
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
trident-csi        1/1     1            1           80s
trident-operator   1/1     1            1           85s

[root@rhel5 trident-installer]# kubectl get pods -n trident
NAME                                READY   STATUS    RESTARTS   AGE
trident-csi-7bb4bfb84-xkznn         6/6     Running   0          91s
trident-csi-dst64                   2/2     Running   0          91s
trident-csi-kszxx                   2/2     Running   0          91s
trident-operator-7f74ff5bb8-nggc4   1/1     Running   0          96s

[root@rhel5 trident-installer]# kubectl get all -n trident
NAME                                    READY   STATUS    RESTARTS   AGE
pod/trident-csi-7bb4bfb84-xkznn         6/6     Running   0          97s
pod/trident-csi-dst64                   2/2     Running   0          97s
pod/trident-csi-kszxx                   2/2     Running   0          97s
pod/trident-operator-7f74ff5bb8-nggc4   1/1     Running   0          102s

NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)              AGE
service/trident-csi   ClusterIP   10.100.106.186   <none>        34571/TCP,9220/TCP   97s

NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                     AGE
daemonset.apps/trident-csi   2         2         2       2            2           kubernetes.io/arch=amd64,kubernetes.io/os=linux   97s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/trident-csi        1/1     1            1           97s
deployment.apps/trident-operator   1/1     1            1           102s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/trident-csi-7bb4bfb84         1         1         1       97s
replicaset.apps/trident-operator-7f74ff5bb8   1         1         1       102s
```

You can use tridentctl or kubectl to verify the new version of Trident.

```bash
[root@rhel5 trident-installer]# ./tridentctl -n trident version
+----------------+----------------+
| SERVER VERSION | CLIENT VERSION |
+----------------+----------------+
| 20.07.0        | 20.07.0        |
+----------------+----------------+

[root@rhel5 trident-installer]# kubectl describe tprov trident -n trident
Name:         trident
Namespace:    trident
Labels:       <none>
Annotations:  <none>
API Version:  trident.netapp.io/v1
Kind:         TridentProvisioner
...
Spec:
  Debug:  true
Status:
  Current Installation Params:
    IPv6:               false
    Autosupport Image:  netapp/trident-autosupport:20.07.0
    Autosupport Proxy:
    Debug:              true
    Image Pull Secrets:
    Image Registry:       quay.io
    k8sTimeout:           30
    Kubelet Dir:          /var/lib/kubelet
    Log Format:           text
    Silence Autosupport:  false
    Trident Image:        netapp/trident:20.07.0
  Message:                Trident installed
  Status:                 Installed
  Version:                v20.07.0
Events:
  Type    Reason      Age                  From                        Message
  ----    ------      ----                 ----                        -------
  Normal  Installing  19m                  trident-operator.netapp.io  Installing Trident
  Normal  Installed   15m (x5 over 18m)    trident-operator.netapp.io  Trident installed
  Normal  Installed   81s (x5 over 6m14s)  trident-operator.netapp.io  Trident installed

[root@rhel5 trident-installer]# kubectl -n trident get tridentversions
NAME      VERSION
trident   20.07.0
```

## C. What's next

Now that Trident is installed, you can proceed to:  

- Next task: [Installing Prometheus & incorporate Trident's metrics](../config_prometheus)

or jump ahead to...  

- [Configure your first NAS backends & storage classes](../config_file)  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#dev-k8s-cluster-tasks)
