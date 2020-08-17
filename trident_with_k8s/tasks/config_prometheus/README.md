# Install Prometheus & integrate Trident's metrics

**Objective:**  
Trident 20.01.1 introduced metrics that can be integrated into Prometheus.  

Going through this task at this point will be interesting as you will actually see the metrics evolve with all the labs.  

You can either follow this task or go through the following link:  
<https://netapp.io/2020/02/20/a-primer-on-prometheus-trident/>

**Pre-requisites:**  
Later in the lab to be able to see the Trident endpoint status, Trident needs to have been installed as described in the [Installing Trident task](../trident_install).

**Note:** All below commands are to be run against the dev cluster. Unless specified differently, please connect using PuTTY to the dev k8s cluster's master node (**`rhel5`**) to proceed with the task.  

## A. Install Helm

Helm is a tool that streamlines installing and managing Kubernetes applications. Think of it like Apt/Yum/Homebrew for k8s.

Helm uses a packaging format called charts. A chart is a collection of files that describe a related set of Kubernetes resources. A single chart might be used to deploy something simple, like a memcached pod, or something complex, like a full web app stack with HTTP servers, databases, caches, and so on.  For this task you will use Helm to deploy Prometheus.

First off, let's download Helm and get it raedy for use:

```bash
[root@rhel5 trident-installer]# cd
[root@rhel5 ~]# wget https://get.helm.sh/helm-v3.0.3-linux-amd64.tar.gz
[root@rhel5 ~]# tar xzvf helm-v3.0.3-linux-amd64.tar.gz
[root@rhel5 ~]# cp linux-amd64/helm /usr/bin/
```

## B. Install Prometheus in its own namespace

Next you need to create a namespace for Poremetheus and then use Helm to download and install Prometheus into that name space.  For our example we are using the `monitoring` namespace and grabbing helm from the `googleapis` repo: 

```bash
[root@rhel5 ~]#kubectl create namespace monitoring
[root@rhel5 ~]#helm repo add stable https://kubernetes-charts.storage.googleapis.com
[root@rhel5 ~]#helm install prom-operator stable/prometheus-operator  --namespace monitoring
```

If you are interested in what other Helm charts may be available, you can browse them here: <https://hub.helm.sh> or you can search at the command line, for example: `helm search repo mysql`

You can check the installation with the following command:

```bash
[root@rhel5 ~]# helm list -n monitoring
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
prom-operator   monitoring      1               2020-04-30 12:43:12.515947662 +0000 UTC deployed        prometheus-operator-8.13.4      0.38.1
```

## C. Expose Prometheus

Prometheus got installed pretty easily.  But how can you access from your browser?

The way Prometheus is installed required it to be accessed from the host where it is installed (with a *port-forwarding* mechanism for instance).

We will modify the Prometheus service in order to access it from anywhere in the lab.  As the dev cluster has a MetalLB load-balancer alraedy configured, we can set up Premetheus to make use of it:

```bash
[root@rhel5 ~]# kubectl edit -n monitoring svc prom-operator-prometheus-o-prometheus
```

### BEFORE

Currently if you look at the bottom of the configuration you will see that Prometheus is currently using the **`ClusterIP`** type:

```bash
spec:
  clusterIP: 10.96.69.69
  ports:
  - name: web
    port: 9090
    protocol: TCP
    targetPort: 9090
  selector:
    app: prometheus
    prometheus: prom-operator-prometheus-o-prometheus
  sessionAffinity: None
  type: ClusterIP
```

### AFTER: (look at the ***nodePort*** & ***type*** lines)

You will need to edit this file to replace **`ClusterIP`**  with **`LoadBalancer`** and also delete the **`NodePort`** line and replace it with `port: 80`:

```bash
spec:
  clusterIP: 10.96.69.69
  ports:
  - name: web
    port: 80
    protocol: TCP
    targetPort: 9090
  selector:
    app: prometheus
    prometheus: prom-operator-prometheus-o-prometheus
  sessionAffinity: None
  type: LoadBalancer
```

To find the IP address the load-balancer assigned to Prometheus, use the following command:

```bash
[root@rhel5 ~]# kubectl get service/prom-operator-prometheus-o-prometheus -n monitoring
NAME                                    TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
prom-operator-prometheus-o-prometheus   LoadBalancer   10.99.220.109   192.168.0.151   80:31420/TCP   15m
```

In this instance, we have `192.168.0.151`, so we can use the Chrome browser to go to this IP and chcek that Prometheus is now accessible.

## D. Add Trident to Prometheus

Refer to the blog aforementioned to get the details about how this Service Monitor works.

The following link is also a good place to find information:
<https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md>

In substance, we will tell in this object to look at services that have the label *trident* & retrieve metrics from its endpoint.

The yaml file has been provided and is available in the config_prometheus sub-directory:

```bash
[root@rhel5 ~]# kubectl create -f /root/netapp-bootcamp/trident_with_k8s/tasks/config_prometheus/Trident_ServiceMonitor.yml
servicemonitor.monitoring.coreos.com/trident-sm created
```

## E. Check the configuration

Via the Chorome web browser, you can now connect to your Prometheus instance and check that the Trident endpoint is taken into account & in the right state.  To find this go to the menu STATUS => TARGETS and then scroll to the bottom of the page.  You should see something similar to the below:

![Trident Status in Prometheus](../../../images/trident_prometheus.png "Trident Status in Prometheus")

**Note:** If you don't see anything regarding Trident, please make sure you have also carried out the [Installing Trident task](../trident_install).

## F. Play around

Now that Trident is integrated into Prometheus, you can retrieve metrics or build graphs.

## G. What's next

Now that Trident is connected to Prometheus, you can move to the next task:  

- [Configure Grafana & add your first graphs](../config_grafana)

or jump ahead to...

- [Configure your first NAS backends & storage classes](../config_file)

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Dev Task List](/README.md#dev-k8s-cluster-tasks)
