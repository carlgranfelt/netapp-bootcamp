#!/bin/bash


echo "#######################################################################################################"
echo "Include CentOS repository"
echo "#######################################################################################################"

cat <<EOF >> /etc/yum.repos.d/centos1.repo
[centos]
name=CentOS-7
baseurl=http://ftp.heanet.ie/pub/centos/7/os/x86_64/
enabled=1
gpgcheck=1
gpgkey=http://ftp.heanet.ie/pub/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
EOF
yum repolist

echo "#######################################################################################################"
echo "Installing Ansible & NetApp library"
echo "#######################################################################################################"

yum -y install ansible
yum -y install python-pip 
pip install --upgrade pip
pip install netapp-lib --user

cat <<EOF >> /etc/ansible/hosts
rhel6
[k8sservers]
rhel1
rhel2
EOF

export ANSIBLE_HOST_KEY_CHECKING=False

echo "#######################################################################################################"
echo "Configuring NetApp volumes for examples using Ansible playbooks"
echo "#######################################################################################################"

ansible-playbook ./ansible_files/legacy-website.yaml
ansible-playbook ./ansible_files/datalake.yaml

echo "#######################################################################################################"
echo "Run web server within docker for one example"
echo "#######################################################################################################"

mkdir /mnt/web_content
mount -t nfs 192.168.0.132:/web_content /mnt/web_content
cp -r netapp_website/v1/* /mnt/web_content
docker -H ssh://root@rhel6 run --name docker-nginx -p 80:80 -d -v /mnt/web_content:/usr/share/nginx/html nginx

echo "#######################################################################################################"
echo "Delete the configured K8S Storage Classes, Trident backends, and uninstall Trident"
echo "#######################################################################################################"

# kubectl delete sc storage-class-nas
# kubectl delete sc storage-class-ssd
# kubectl delete sc storage-class-storagepool
# kubectl delete sc sf-gold
# kubectl delete sc sf-silver
# tridentctl delete backend BackendForNAS -n trident
# tridentctl delete backend BackendForSolidFire -n trident
# tridentctl uninstall -n trident

# Echo existing version
echo ""
echo "[root@rhel3 ~]# tridentctl -n trident version"
tridentctl -n trident version

# Cleanup up Trident backends and kubernetes storage classes
kubectl delete sc --all
tridentctl -n trident delete backend --all

# Delete existing CRD deployed and used by Trident
tridentctl -n trident obliviate crd --yesireallymeanit

# Uninstall Trident 
tridentctl -n trident uninstall

# Delete trident namespace
kubectl delete ns trident

# Download Trident 20.04
cd
mv trident-installer/ trident-installer_19.07
wget -nv https://github.com/NetApp/trident/releases/download/v20.04.0/trident-installer-20.04.0.tar.gz
tar -xf trident-installer-20.04.0.tar.gz

#
# Do I need to cd to the directory?
# Do i need to specify the namespace?
#

# Run twice the obliviate alpha-snapshot-crd command due to a known issue
tridentctl -n trident obliviate alpha-snapshot-crd
tridentctl -n trident obliviate alpha-snapshot-crd

echo "#######################################################################################################"
echo "Install and create a metallb configuration"
echo "#######################################################################################################"

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.9.3/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f k8s_files/metailb-configmap-k8s-prod.yaml

echo "#######################################################################################################"
echo "Upgrading to K8s 1.16"
echo "#######################################################################################################"

yum install -y kubeadm-1.16.7-0 --disableexcludes=kubernetes
kubeadm upgrade apply v1.16.7 -y
yum install -y kubelet-1.16.7-0 kubectl-1.16.7-0 --disableexcludes=kubernetes
systemctl restart kubelet
systemctl daemon-reload
sleep 30s

ssh -o "StrictHostKeyChecking no" root@rhel1 yum install -y kubeadm-1.16.7-0 --disableexcludes=kubernetesclear
ssh -o "StrictHostKeyChecking no" root@rhel1 kubeadm upgrade node 
ssh -o "StrictHostKeyChecking no" root@rhel1 yum install -y kubelet-1.16.7-0 kubectl-1.16.7-0 --disableexcludes=kubernetes
ssh -o "StrictHostKeyChecking no" root@rhel1 systemctl restart kubelet
ssh -o "StrictHostKeyChecking no" root@rhel1 systemctl daemon-reload
sleep 30s

ssh -o "StrictHostKeyChecking no" root@rhel2 yum install -y kubeadm-1.16.7-0 --disableexcludes=kubernetesclear
ssh -o "StrictHostKeyChecking no" root@rhel2 kubeadm upgrade node 
ssh -o "StrictHostKeyChecking no" root@rhel2 yum install -y kubelet-1.16.7-0 kubectl-1.16.7-0 --disableexcludes=kubernetes
ssh -o "StrictHostKeyChecking no" root@rhel2 systemctl restart kubelet
ssh -o "StrictHostKeyChecking no" root@rhel2 systemctl daemon-reload
sleep 30s

echo "#######################################################################################################"
echo "Upgrading to K8s 1.17"
echo "#######################################################################################################"

yum install -y kubeadm-1.17.3-0 --disableexcludes=kubernetes
kubeadm upgrade apply v1.17.3 -y
yum install -y kubelet-1.17.3-0 kubectl-1.17.3-0 --disableexcludes=kubernetes
systemctl restart kubelet
systemctl daemon-reload
sleep 30s

ssh -o "StrictHostKeyChecking no" root@rhel1 yum install -y kubeadm-1.17.3-0 --disableexcludes=kubernetesclear
ssh -o "StrictHostKeyChecking no" root@rhel1 kubeadm upgrade node 
ssh -o "StrictHostKeyChecking no" root@rhel1 yum install -y kubelet-1.17.3-0 kubectl-1.17.3-0 --disableexcludes=kubernetes
ssh -o "StrictHostKeyChecking no" root@rhel1 systemctl restart kubelet
ssh -o "StrictHostKeyChecking no" root@rhel1 systemctl daemon-reload
sleep 30s

ssh -o "StrictHostKeyChecking no" root@rhel2 yum install -y kubeadm-1.17.3-0 --disableexcludes=kubernetesclear
ssh -o "StrictHostKeyChecking no" root@rhel2 kubeadm upgrade node 
ssh -o "StrictHostKeyChecking no" root@rhel2 yum install -y kubelet-1.17.3-0 kubectl-1.17.3-0 --disableexcludes=kubernetes
ssh -o "StrictHostKeyChecking no" root@rhel2 systemctl restart kubelet
ssh -o "StrictHostKeyChecking no" root@rhel2 systemctl daemon-reload
sleep 30s
e
echo "#######################################################################################################"
echo "Upgrading to K8s 1.18"
echo "#######################################################################################################"

yum install -y kubeadm-1.18.0-0 --disableexcludes=kubernetes
kubeadm upgrade apply v1.18.0 -y
yum install -y kubelet-1.18.0-0 kubectl-1.18.0-0 --disableexcludes=kubernetes
systemctl restart kubelet
systemctl daemon-reload
sleep 30s

ssh -o "StrictHostKeyChecking no" root@rhel1 yum install -y kubeadm-1.18.0-0 --disableexcludes=kubernetesclear
ssh -o "StrictHostKeyChecking no" root@rhel1 kubeadm upgrade node 
ssh -o "StrictHostKeyChecking no" root@rhel1 yum install -y kubelet-1.18.0-0 kubectl-1.18.0-0--disableexcludes=kubernetes
ssh -o "StrictHostKeyChecking no" root@rhel1 systemctl restart kubelet
ssh -o "StrictHostKeyChecking no" root@rhel1 systemctl daemon-reload
sleep 30s

ssh -o "StrictHostKeyChecking no" root@rhel2 yum install -y kubeadm-1.18.0-0 --disableexcludes=kubernetesclear
ssh -o "StrictHostKeyChecking no" root@rhel2 kubeadm upgrade node 
ssh -o "StrictHostKeyChecking no" root@rhel2 yum install -y kubelet-1.18.0-0 kubectl-1.18.0-0 --disableexcludes=kubernetes
ssh -o "StrictHostKeyChecking no" root@rhel2 systemctl restart kubelet
ssh -o "StrictHostKeyChecking no" root@rhel2 systemctl daemon-reload
sleep 30s

echo "#######################################################################################################"
echo "Initialize and configure rhel4 to join prod kubernetes cluster"
echo "#######################################################################################################"

ssh -o "StrictHostKeyChecking no" root@rhel4 < ./01_prepare_k8s_servers.sh
ssh -o "StrictHostKeyChecking no" root@rhel4 < ./03_join_prod_k8s_workers.sh

echo "#######################################################################################################"
echo "Initialize and configure the dev kubernetes cluster"
echo "#######################################################################################################"

ssh -o "StrictHostKeyChecking no" root@rhel5 < ./01_prepare_k8s_servers.sh
ssh -o "StrictHostKeyChecking no" root@rhel6 < ./01_prepare_k8s_servers.sh

ssh -o "StrictHostKeyChecking no" root@rhel5 < ./02_init_dev_k8s_master.sh

ssh -o "StrictHostKeyChecking no" root@rhel6 < ./03_join_dev_k8s_workers.sh

ssh -o "StrictHostKeyChecking no" root@rhel5 < ./04_configure_dev_k8s_cluster.sh

# chmod 744 * ../demo/*.sh
# chmod 744 * ../demo/k8s_backup/*.sh

echo "#######################################################################################################"
echo "Install and configure Prometheus and Grafana dashboards"
echo "#######################################################################################################"

# Install Helm

wget https://get.helm.sh/helm-v3.0.3-linux-amd64.tar.gz
tar xzvf helm-v3.0.3-linux-amd64.tar.gz
cp linux-amd64/helm /usr/bin/

# Install Prometheus and Grafana using the Prometheus operator

kubectl create namespace monitoring
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
helm install prom-operator stable/prometheus-operator --namespace monitoring

# Recreate the Prometheus service using a LoadBalancer type

kubectl delete -n monitoring svc prom-operator-prometheus-o-prometheus
kubectl apply -f /root/demo-trident/making/monitoring/prometheus/service-prom-operator-prometheus.yaml

# Create a Service Monitor for Trident

kubectl apply -f /root/demo-trident/making/monitoring/prometheus/servicemonitor.yaml

# Recreate the Grafana service using a LoadBalancer type

kubectl delete -n monitoring svc prom-operator-grafana
kubectl apply -f /root/demo-trident/making/monitoring/grafana/service-prom-operator-grafana.yaml

# Create configmap resources with the Grafana datasource and dashboards

kubectl apply -f /root/demo-trident/making/monitoring/grafana/cm-grafana-datasources.yaml
kubectl create configmap cm-grafana-dashboard -n monitoring --from-file=/root/demo-trident/making/monitoring/grafana/dashboards/

# Recreate the Grafana deployment using the previuos configmap resources to avoid manual configuration

kubectl delete deployment prom-operator-grafana -n monitoring
kubectl apply -f /root/demo-trident/making/monitoring/grafana/deployment-prom-operator-grafana.yaml

# Modify the Grafana GUI password setting 'admin'

kubectl patch secret -n monitoring prom-operator-grafana -p='{"data":{"admin-password": "YWRtaW4="}}' -v=1


echo "#######################################################################################################"
echo "Changing Trident path"
echo "#######################################################################################################"

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/trident-installer:/root/bin
export PATH

cat <<EOF > ~/.bash_profile
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# add path for tridentctl
PATH=$PATH:/root/trident-installer

# User specific environment and startup programs
PATH=$PATH:$HOME/bin

export PATH

export KUBECONFIG=$HOME/.kube/config

EOF

echo "#######################################################################################################"
echo "Installing Trident with an Operator"
echo "#######################################################################################################"

# Install Trident Provisioner, which is a Custom Resource Definition
kubectl create -f trident-installer/deploy/crds/trident.netapp.io_tridentprovisioners_crd_post1.16.yaml

# Display CRDs 
echo ""
echo "[root@rhel3 ~]# kubectl get crd"
kubectl get crd

# Create trident namespace
kubectl create namespace trident

# Install Trident Operator
kubectl create -f trident-installer/deploy/bundle.yaml

# Verify Trident Operator
echo ""
echo "[root@rhel3 ~]# kubectl get all -n trident"
kubectl get all -n trident

# Installing Trident Provisioner
kubectl create -f trident-installer/deploy/crds/tridentprovisioner_cr.yaml

# Verify new Trident version
echo ""
echo "[root@rhel3 ~]# kubectl -n trident get tridentversions"
kubectl -n trident get tridentversions
#echo ""
#read -p "Press any key to continue... " -n1 -s
#clear

# Check Trident components 
echo ""
echo "[root@rhel3 ~]# kubectl get all -n trident"
kubectl get all -n trident
#echo ""
#read -p "Press any key to continue... " -n1 -s
#clear

# Verify Trident Provisioner status
echo ""
echo "[root@rhel3 ~]# kubectl describe tprov trident -n trident | grep Message: -A 3"
kubectl describe tprov trident -n trident | grep Message: -A 3

echo "#######################################################################################################"
echo "Create Trident backend & k8s storage classes"
echo "#######################################################################################################"

# Create Trident backends
echo ""
echo "[root@rhel3 ~]# tridentctl -n trident create backend -f ./k8s_files/backend-nas-default.json"
tridentctl -n trident create backend -f ./k8s_files/backend-nas-default.json
echo ""
echo "[root@rhel3 ~]# tridentctl -n trident create backend -f ./k8s_files/backend-nas-eco-default.json"
tridentctl -n trident create backend -f ./k8s_files/backend-nas-eco-default.json

echo ""
echo "[root@rhel3 ~]# kubectl get -n trident tridentbackends"
kubectl get -n trident tridentbackends

# Create kubernetes storage class objects pointing at the backends
echo ""
echo "[root@rhel3 ~]# kubectl create -f sc-csi-ontap-nas.yaml"
kubectl create -f sc-csi-ontap-nas.yaml

echo ""
echo "[root@rhel3 ~]# kubectl create -f sc-csi-ontap-nas-eco.yaml"
kubectl create -f sc-csi-ontap-nas-eco.yaml

echo ""
echo "[root@rhel3 ~]# kubectl get sc"
kubectl get sc

echo "#######################################################################################################"
echo "Install Kubernetes Dashboard"
echo "#######################################################################################################"

# Deploy Dashboard
echo ""
echo "[root@rhel3 ~]# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.3/aio/deploy/recommended.yaml"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.3/aio/deploy/recommended.yaml

# Create An Authentication Token (RBAC)
# Create a Service Account
echo ""
echo "[root@rhel3 ~]# kubectl create -f dashboard-service-account.yaml"
kubectl create -f dashboard-service-account.yaml

echo ""
echo "[root@rhel3 ~]# kubectl create -f dashboard-clusterrolebinding.yaml"
kubectl create -f dashboard-clusterrolebinding.yaml