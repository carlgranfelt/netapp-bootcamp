# Useful Commands

**Objective:**  
This section details some useful commands and handy tips.  

## A. BASH

When you get more & more familiar with Kubernetes, you start wondering how to be more efficient with typing the commands...
One option would to create a bunch of alias in the .bashrc file.

For example:

```bash
# cat <<EOT >> ~/.bashrc
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k

alias kc='kubectl create'
alias kg='kubectl get'
alias kdel='kubectl delete'
alias kdesc='kubectl describe'
alias kedit='kubectl edit'
EOT
```

Don't forget to type in _bash_ in order to take the modifications into account.

## B. Kubectl Autocomplete

Kubectl has support for auto-completion allowing you to discover the available options. This is applied to the terminal session using the source command:

```bash
source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
```

## C. Basic and troubleshooting commands

Below are a number of kubectl commands that might come handy in general, viewing additional resource information or assist in troubleshooting various scenarios:

### kubectl get

Prints a table of the most important information about the specified resources. You can filter the list using a label selector and the --selector flag. If the desired resource type is namespaced you will only see results in your current namespace unless you pass --all-namespaces (shorthand -A) or specify the namespace using --namespace *specific-namespace* (shorthand -n *specific-namespace*).  

```bash
Usage:
  kubectl get
[(-o|--output=)json|yaml|wide|custom-columns=...|custom-columns-file=...|go-template=...|go-template-file=...|jsonpath=...|jsonpath-file=...]
(TYPE[.VERSION][.GROUP] [NAME | -l label] | TYPE[.VERSION][.GROUP]/NAME ...) [flags] [options]

Example:
# List all objects in the default namespace
[root@rhel3 ~]# kubectl get all
```

### kubectl describe

Print a detailed description of the selected resources, including related resources such as events or controllers. You may select a single object by name, all objects of that type, provide a name prefix, or label selector.  

Use "kubectl api-resources" for a complete list of supported resources.  

```bash
Usage:
  kubectl describe (-f FILENAME | TYPE [NAME_PREFIX | -l label] | TYPE/NAME) [options]

Example:
# Describe a pod
[root@rhel3 ~]# kubectl describe pods trident-csi-788b4d865c-xdzn7 -n trident
```

### kubectl logs

Print the logs for a container in a pod or specified resource. If the pod has only one container, the container name is optional.

```bash
Usage:
  kubectl logs [-f] [-p] (POD | TYPE/NAME) [-c CONTAINER] [options]

Example:
# Return snapshot logs from container trident-main of a deployment named  deployment.apps/trident-csi
[root@rhel3 ~]# kubectl logs trident-csi-788b4d865c-xdzn7 -c trident-main -n trident
```

### kubectl events

Report of an event somewhere in the cluster.

```bash
Usage:
  kubectl get
[(-o|--output=)json|yaml|wide|custom-columns=...|custom-columns-file=...|go-template=...|go-template-file=...|jsonpath=...|jsonpath-file=...]
(TYPE[.VERSION][.GROUP] [NAME | -l label] | TYPE[.VERSION][.GROUP]/NAME ...) [flags] [options]

Example:
# Get events for namespace trident
[root@rhel3 ~]# kubectl get events -n trident
```

### kubectl run

Create and run a particular image in a pod.

```bash
Usage:
  kubectl run NAME --image=image [--env="key=value"] [--port=port] [--dry-run=server|client] [--overrides=inline-json]
[--command] -- [COMMAND] [args...] [options]

Example:
# Run a shell in an interactive pod - very useful for debugging
[root@rhel3 ~]# kubectl run -i --tty busybox --image=busybox --restart=Never -- sh
```

### kubectl exec

Execute a command in a container.

```bash
Usage:
  kubectl exec (POD | TYPE/NAME) [-c CONTAINER] [flags] -- COMMAND [args...] [options]

Example:
# Verify that the volume is mounted on /usr/share/nginx/html
[root@rhel3 ~]# kubectl exec -it nginx -- df -h /usr/share/nginx/html
```

### kubectl attach

Attach to a process that is already running inside an existing container.

```bash
Usage:
  kubectl attach (POD | TYPE/NAME) -c CONTAINER [options]

Example:
# Attach to a running pod called nginx
[root@rhel3 ~]# kubectl attach nginx -it
```

If you need any further assistance, feel free to ask your bootcamp host.

## D. How can I easily list all the containers in a POD

As there is no option to do so, you need to _extract_ this information from the POD definition.
Below is an example output with Trident Operator 20.04 and Kubernetes 1.18:

```bash
[root@rhel3 ~]# kubectl get pods -n trident -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |sort

trident-csi-788b4d865c-xdzn7:   netapp/trident:20.04, quay.io/k8scsi/csi-provisioner:v1.6.0, quay.io/k8scsi/csi-attacher:v2.2.0, quay.io/k8scsi/csi-resizer:v0.5.0, quay.io/k8scsi/csi-snapshotter:v2.1.0,
trident-csi-gn4cv:      netapp/trident:20.04, quay.io/k8scsi/csi-node-driver-registrar:v1.3.0,
trident-csi-q2w6c:      netapp/trident:20.04, quay.io/k8scsi/csi-node-driver-registrar:v1.3.0,
trident-csi-rdpjk:      netapp/trident:20.04, quay.io/k8scsi/csi-node-driver-registrar:v1.3.0,
trident-csi-x8ppp:      netapp/trident:20.04, quay.io/k8scsi/csi-node-driver-registrar:v1.3.0,
trident-operator-668bf8cdff-577p9:      netapp/trident-operator:20.04.0,
```

Below is an example output with Trident Operator 20.07 and Kubernetes 1.18:

```bash
[root@rhel3 ghost]# kubectl get pods -n trident -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |sort

trident-csi-7bb4bfb84-n2gnz:    netapp/trident:20.07.0, netapp/trident-autosupport:20.07.0, quay.io/k8scsi/csi-provisioner:v1.6.0, quay.io/k8scsi/csi-attacher:v2.2.0, quay.io/k8scsi/csi-resizer:v0.5.0, quay.io/k8scsi/csi-snapshotter:v2.1.1,
trident-csi-g2bq9:      netapp/trident:20.07.0, quay.io/k8scsi/csi-node-driver-registrar:v1.3.0,
trident-csi-nkmhj:      netapp/trident:20.07.0, quay.io/k8scsi/csi-node-driver-registrar:v1.3.0,
trident-csi-q6646:      netapp/trident:20.07.0, quay.io/k8scsi/csi-node-driver-registrar:v1.3.0,
trident-csi-zvrb2:      netapp/trident:20.07.0, quay.io/k8scsi/csi-node-driver-registrar:v1.3.0,
trident-operator-7f74ff5bb8-h88b6:      netapp/trident-operator:20.07.0,
```

The difference between Trident 20.04 and 20.07 is a new trident-autosupport sidecar container to periodically send [Trident usage and support telemetry](<https://netapp-trident.readthedocs.io/en/stable-v20.07/kubernetes/operations/tasks/monitoring.html?highlight=autosupport#trident-autosupport-telemetry>) data to NetApp and an update to the csi-snapshotter.  
What is also interesting to notice is that with newer releases of Kubernetes, new sidecars are added to CSI Trident:

- Kubernetes 1.16: Volume Expansion (CSI Resizer) was promoted to Beta status (<https://kubernetes-csi.github.io/docs/volume-expansion.html>)
- Kubernetes 1.17: Snapshot & Restore (CSI Snapshotter) was promoted to Beta status (<https://kubernetes-csi.github.io/docs/snapshot-restore-feature.html>)

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
