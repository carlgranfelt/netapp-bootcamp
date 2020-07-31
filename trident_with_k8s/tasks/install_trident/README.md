# Trident installation with an Operator

**GOAL:**  
Trident 20.04 introduced a new way to manage its lifecycle: Operators.  
For now, this installation method is only intended for green field environments.  

For the official documentation on deploying with the Trident Operator, please see:  
<https://netapp-trident.readthedocs.io/en/latest/kubernetes/operator-install.html>

**Note:** All below commands are to be run against the dev cluster. Unless specified differently, please connect using PuTTY to the dev k8s cluster's master node (rhel5) to proceed with the task.  

## A. Download & setup the operator

Connect using PuTTY to the dev k8s cluster's master node, **rhel5**, and download the latest version of the Trident installer bundle and extract it:

```bash
[root@rhel5 ~]# cd
[root@rhel5 ~]# wget https://github.com/NetApp/trident/releases/download/v20.04.0/trident-installer-20.04.0.tar.gz
[root@rhel5 ~]# tar -xf trident-installer-20.04.0.tar.gz
[root@rhel5 ~]# cd trident-installer
```

With Trident 20.04, there are new objects in the picture:

- Trident Operator, which will dynamically manage Trident's resources, automate setup, fix broken elements  
- Trident Provisioner, which is a Custom Resource, and is the object you will use to interact with the Trident Operator for specific tasks (upgrades, enable/disable Trident options, such as _debug_ mode, uninstall)  

:mag:  
*A* **resource** *is an endpoint in the Kubernetes API that stores a collection of API objects of a certain kind; for example, the built-in pods resource contains a collection of Pod objects.*  
*A* **custom resource** *is an extension of the Kubernetes API that is not necessarily available in a default Kubernetes installation. It represents a customization of a particular Kubernetes installation. However, many core Kubernetes functions are now built using custom resources, making Kubernetes more modular.*  
:mag_right:  

You can visualize the *Operator* as being the *Control Tower*, and the *Provisioner* as being the *Mailbox* in which you post configuration requests.
Other operations, such as backend management or viewing logs are currently still managed by Trident's own `tridentctl`.

First let's confirm the version of Kubernetes you are using:

```bash
[root@rhel5 trident-installer]# kubectl get nodes
NAME    STATUS   ROLES    AGE    VERSION
rhel5   Ready    master   2d7h   v1.18.0
rhel6   Ready    <none>   2d7h   v1.18.0
```

The Custom Resource Definition (CRD) object was promoted to GA with Kubernetes 1.16. Provided with the Trident installer bundle is a CRD manifest used to create the TridentProvisioner Custom Resource Definition. You will then create a TridentProvisioner Custom Resource later on to instantiate a Trident install by the operator.

```bash
[root@rhel5 trident-installer]# kubectl create -f deploy/crds/trident.netapp.io_tridentprovisioners_crd_post1.16.yaml
customresourcedefinition.apiextensions.k8s.io/tridentprovisioners.trident.netapp.io created
```

You will end up with a brand new TridentProvisioner CRD:

```bash
 [root@rhel5 trident-installer]# kubectl get crd
NAME                                    CREATED AT
tridentprovisioners.trident.netapp.io   2020-07-23T15:41:53Z
```

Once the TridentProvisioner CRD is created, you will then have to create the resources required for the operator deployment, such as:  

- ServiceAccount for the operator
- ClusterRole and ClusterRoleBinding to the ServiceAccount
- Dedicated PodSecurityPolicy
- The Operator itself

The Trident Installer contains manifests for defining these resources.
  
**Note:** It is recommended to install Trident in its own namespace (by default called *trident*).

```bash
[root@rhel5 trident-installer]# kubectl create namespace trident
namespace/trident created

[root@rhel5 trident-installer]# kubectl create -f deploy/bundle.yaml
serviceaccount/trident-operator created
clusterrole.rbac.authorization.k8s.io/trident-operator created
clusterrolebinding.rbac.authorization.k8s.io/trident-operator created
deployment.apps/trident-operator created
podsecuritypolicy.policy/tridentoperatorpods created
```

You can check the status of the operator once you have deployed.

```bash
[root@rhel5 trident-installer]# kubectl get deployment -n trident
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
trident-operator   1/1     1            1           2m15s
[root@rhel5 trident-installer]# kubectl get pods -n trident
NAME                                READY   STATUS    RESTARTS   AGE
trident-operator-668bf8cdff-nnxrw   1/1     Running   0          2m24s
```

The operator deployment successfully creates a pod running on one of the worker nodes in your cluster.

**Note:** There must only be one instance of the operator in a Kubernetes cluster. Do not create multiple deployments of the Trident operator.

## B. Creating a TridentProvisioner CR and installing Trident

You are now ready to install Trident using the operator! This will require creating a TridentProvisioner CR. The Trident installer comes with example defintions for creating a TridentProvisioner CR.

```bash
[root@rhel5 trident-installer]# kubectl create -f deploy/crds/tridentprovisioner_cr.yaml
tridentprovisioner.trident.netapp.io/trident created

[root@rhel5 trident-installer]# kubectl get tprov -n trident
NAME      AGE
trident   40s

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
  Message:  Trident installed
  Status:   Installed
  Version:  v20.04
Events:
  Type    Reason      Age                From                        Message
  ----    ------      ----               ----                        -------
  Normal  Installing  76s                trident-operator.netapp.io  Installing Trident
  Normal  Installed   12s (x3 over 49s)  trident-operator.netapp.io  Trident installed
```

After a few seconds, you should the status `installed` in the provisioner CRD.

You can also confirm if the Trident install completed by taking a look at the pods that have been created:

```bash
[root@rhel5 trident-installer]# kubectl get pod -n trident
NAME                                READY   STATUS    RESTARTS   AGE
trident-csi-788b4d865c-jhxqn        5/5     Running   0          4m
trident-csi-qvw2b                   2/2     Running   0          4m
trident-csi-xmxft                   2/2     Running   0          4m
trident-operator-668bf8cdff-nnxrw   1/1     Running   0          6h1m
```

You can use tridentctl or kubectl to check the version of Trident installed.

```bash
[root@rhel5 trident-installer]# ./tridentctl -n trident version
+----------------+----------------+
| SERVER VERSION | CLIENT VERSION |
+----------------+----------------+
| 20.04.0        | 20.04.0        |
+----------------+----------------+

[root@rhel5 trident-installer]# kubectl -n trident get tridentversions
NAME      VERSION
trident   20.04.0
```

The interesting part of this CRD is that you have access to the current status of Trident. This is also where you are going to interact with Trident's deployment.  
If you want to know more about the different status, please have a look at the following link:  
<https://netapp-trident.readthedocs.io/en/stable-v20.04/kubernetes/operator-install.html#observing-the-status-of-the-operator>

## C. Add path for tridentctl

By default tridentctl is not in the path:  

```bash
[root@rhel5 ~]# tridentctl
-bash: tridentctl: command not found
```

But we can easily fix that by running the below commands:

```bash
[root@rhel5 ~]# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/trident-installer:/root/bin
[root@rhel5 ~]# export PATH
[root@rhel5 ~]# cat <<EOF > ~/.bash_profile
> # .bash_profile
> # Get the aliases and functions
> if [ -f ~/.bashrc ]; then
>         . ~/.bashrc
> fi
> # add path for tridentctl
> PATH=$PATH:/root/trident-installer
> # User specific environment and startup programs
> PATH=$PATH:$HOME/bin
> export PATH
> export KUBECONFIG=$HOME/.kube/config
> EOF
```

And to verify our work:

```bash
[root@rhel5 ~]# tridentctl
A CLI tool for managing the NetApp Trident external storage provisioner for Kubernetes

Usage:
  tridentctl [command]

Available Commands:
  create      Add a resource to Trident
  delete      Remove one or more resources from Trident
  get         Get one or more resources from Trident
  help        Help about any command
  import      Import an existing resource to Trident
  install     Install Trident
  logs        Print the logs from Trident
  uninstall   Uninstall Trident
  update      Modify a resource in Trident
  upgrade     Upgrade a resource in Trident
  version     Print the version of Trident

Flags:
  -d, --debug              Debug output
  -h, --help               help for tridentctl
  -n, --namespace string   Namespace of Trident deployment
  -o, --output string      Output format. One of json|yaml|name|wide|ps (default)
  -s, --server string      Address/port of Trident REST interface

Use "tridentctl [command] --help" for more information about a command.  
```

## D. What's next

Now that Trident is installed, you can proceed to:  

- Next task: [Installing Prometheus & incorporate Trident's metrics](../config_prometheus)

or jump ahead to...  

- [Configure your first NAS backends & storage classes](../config_file)  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#dev-k8s-cluster-tasks)
