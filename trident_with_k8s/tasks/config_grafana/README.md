# Configure Grafana & make your first graph

**Objective:**  
Prometheus does not allow you to create a graph with different metrics, you need to use Grafana for that.  

The good news is that the Helm chart you used in the previous task also installed and configured Grafana for you.  

In this task you will learn how to access Grafana, and configure a graph.

**Note:** All below commands are to be run against the dev cluster. Unless specified differently, please connect using PuTTY to the dev k8s cluster's master node (**`rhel5`**) to proceed with the task.  

## A. Expose Grafana

With Grafana, we are facing the same access issue than with Prometheus in the previous task.

You will need to modify its service in order to access it from anywhere in the lab via the load-balancer:

```bash
[root@rhel5 ~]# kubectl edit -n monitoring svc prom-operator-grafana
```

### BEFORE

Currently if you look at the bottom of the configuration you will see that Prometheus is currently using the **`ClusterIP`** type:

```bash
spec:
  clusterIP: 10.97.208.231
  ports:
  - name: service
    port: 80
    protocol: TCP
    targetPort: 3000
  selector:
    app.kubernetes.io/instance: prom-operator
    app.kubernetes.io/name: grafana
  sessionAffinity: None
  type: ClusterIP
```

### AFTER (look at the ***nodePort*** & ***type*** lines)

You will need to edit this file to replace **`ClusterIP`**  with **`LoadBalancer`**:

```bash
spec:
  clusterIP: 10.97.208.231
  ports:
  - name: service
    port: 80
    protocol: TCP
    targetPort: 3000
  selector:
    app.kubernetes.io/instance: prom-operator
    app.kubernetes.io/name: grafana
  sessionAffinity: None
  type: LoadBalancer
```

To find the IP address the load-balancer assigned to Grafana, use the following command:

```bash
[root@rhel5 ~]# kubectl get service/prom-operator-grafana -n monitoring
NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
prom-operator-grafana   LoadBalancer   10.109.152.89   192.168.0.152   80:32348/TCP   43m
```

In this instance, we have `192.168.0.152`, so we can use the Chrome browser to go to this IP and chcek that Prometheus is now accessible.

## B. Accessing Grafana

The first time to enter Grafana, you are requested to login with a username & a password... But how does one find out what they are?  If you have the time, below is a really useful task to grab the username and password from the pod, but if you are tight on time, you can [skip ahead and we will give the username and password to you](config_grafana#c-configure-grafana).

Let's find the grafana pod and have a look at the pod definition, maybe there is a hint for us.  Make sure to replace the pod name in this example with your own pod name from the console:

```bash
[root@rhel5 ~]# kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana
NAME                                     READY   STATUS    RESTARTS   AGE
prom-operator-grafana-5dd648d5bc-2g6dn   2/2     Running   0          7h40m

[root@rhel5 ~]# kubectl describe pod prom-operator-grafana-5dd648d5bc-2g6dn -n monitoring
...
 Environment:
      GF_SECURITY_ADMIN_USER:      <set to the key 'admin-user' in secret 'prom-operator-grafana'>      Optional: false
      GF_SECURITY_ADMIN_PASSWORD:  <set to the key 'admin-password' in secret 'prom-operator-grafana'>  Optional: false
...
```

Let's see what grafana secrets there are in this cluster:

```bash
[root@rhel5 ~]# kubectl get secrets -n monitoring -l app.kubernetes.io/name=grafana
NAME                    TYPE     DATA   AGE
prom-operator-grafana   Opaque   3      7h50m

[root@rhel5 ~]# kubectl describe secrets -n monitoring prom-operator-grafana
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
[root@rhel5 ~]# kubectl get secret -n monitoring prom-operator-grafana -o jsonpath="{.data.admin-user}" | base64 --decode ; echo
admin
[root@rhel5 ~]# kubectl get secret -n monitoring prom-operator-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
prom-operator
```

## C. Configure Grafana

Now we have the necessary clear text credentials of username: `admin` and password `prom-operator` to login to the Grafana UI at your assigned load-balancer IP.

The first step is to tell Grafana where to get data (ie Data Sources) via the web GUI.

On the first page after logging into the Grafana GUI, click on "Add your first data source", select "Prometheus" and set the URL to the Prometheus's IP you obtained in the previous task.  In this example case it was 192.168.0.151 (make sure to use http and not https).  Set the Name of the datasource to `Prometheus-1`

Also, tick the box at the top that sets this datasource to be the Default.

Click on 'Save & Test' and you should get a green box in response.

## D. Create your own graph

Hover on the '+' on left side of the screen, then "Dashboard", "Add new panel".

Next, you can need to configure a new graph by adding metrics. By typing 'trident' in the 'Metrics' box towards the bottom of the page, you will see all metrics available.  Feel free to have a play around and see what you can build from scratch.  In the next step, we will provide an already created dashboard for you to import.

## E. Import a graph

There are several ways to bring dashboards into Grafana.  Click on the back arrow at the top left of the GUI to get back to your dashboard.

**Manual Import**  
Hover on the '+' on left side of the screen and select "Import".  Feel free to save or discard you current dashboard if you were working on one.

Copy & paste the content of the [Trident_Dashboard_Std.json](Trident_Dashboard_Std.json) file in this GitHub directory.  **Ensure that the `datasource` is set to what you configured for Prometheus earlier (it should be "Prometheus-1") **

The issue with this method is that if the Grafana POD restarts, the dashboard will be lost...  

**Persistent Dashboard**  
The idea here would be to create a ConfigMap pointing to the Trident dashboard json file.

:mag:  
*A* **ConfigMap** *is an API object used to store non-confidential data in key-value pairs. Pods can consume ConfigMaps as environment variables, command-line arguments, or as configuration files in a volume. A ConfigMap allows you to decouple environment-specific configuration from your container images, so that your applications are easily portable.*  
:mag_right:  

**Ensure that the `datasource` in your rhel5 local copy of the `Trident_Dashboard_Std.json` file is set to what you configured for Prometheus earlier (most likely "Prometheus-1") **

```bash
[root@rhel5 ~]# cd ~/netapp-bootcamp/trident_with_k8s/tasks/config_grafana/
[root@rhel5 ~]# kubectl create configmap -n monitoring tridentdashboard --from-file=Trident_Dashboard_Std.json
configmap/tridentdashboard created

[root@rhel5 ~]# kubectl label configmap -n monitoring tridentdashboard grafana_dashboard=1
configmap/tridentdashboard labeled
```

When Grafana starts, it will automatically load every configmap that has the label `grafana_dashboard`.  

In the Grafana UI, you will find the dashboard in its own *Trident* folder.  

Now, where can you find this dashboard:  

- Hover on the 'Dashboard' icon on the left side bar (it looks like 4 small squares)  
- Click on the 'Manage' button  
- You then access a list of dashboards. You can either research 'Trident' or find the link be at the bottom of the page.  

Don't worry if your dashboard doesn't look too much like the example below, as you haven't yet configured any storage backends or persistent volumes, so there isn't much to report on yet.

![Trident Dashboard](../../../images/trident_dashboard.jpg "Trident Dashboard")

## F. What's next

OK, you have everything to monitor Trident, let's continue with the creation of some backends:  

- [Configure your first NAS backends & storage classes](../config_file)  

or jump ahead to...

- [Configure your first iSCSI backends & storage classes](../config_block)  

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Dev Task List](/README.md#dev-k8s-cluster-tasks)
