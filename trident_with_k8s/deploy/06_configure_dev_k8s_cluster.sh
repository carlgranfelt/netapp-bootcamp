#!/bin/bash
echo "#######################################################################################################"
echo "Installing weave for the kubernetes network"
echo "#######################################################################################################"

export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"

echo "#######################################################################################################"
echo "Waiting 30 seconds to allow the weave pods start properly"
echo "#######################################################################################################"

sleep 30s

echo "#######################################################################################################"
echo "Install and create a metallb configuration"
echo "#######################################################################################################"

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.9.3/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f /root/NetApp-LoD/trident_with_k8s/deploy/k8s_files/metallb-configmap-k8s-dev.yaml

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
kubectl create -f /root/NetApp-LoD/trident_with_k8s/deploy/k8s_files/dashboard-service-account.yaml

echo ""
echo "[root@rhel3 ~]# kubectl create -f dashboard-clusterrolebinding.yaml"
kubectl create -f /root/NetApp-LoD/trident_with_k8s/deploy/k8s_files/dashboard-clusterrolebinding.yaml

echo ""
echo "[root@rhel3 ~]# kubectl -n kubernetes-dashboard patch service/kubernetes-dashboard -p '{"spec":{"type":"LoadBalancer"}}'"
kubectl -n kubernetes-dashboard patch service/kubernetes-dashboard -p '{"spec":{"type":"LoadBalancer"}}'

echo "#######################################################################################################"
echo "Install Kubernetes Metrics Server for kubectl top and pod autoscaler"
echo "#######################################################################################################"

cd

# Clone kodekloudhub/kubernetes-metrics-server repository
echo ""
echo "[root@rhel3 ~]# git clone https://github.com/kodekloudhub/kubernetes-metrics-server.git"
git clone https://github.com/kodekloudhub/kubernetes-metrics-server.git

# Create Kubernetes Metrics Server
echo ""
echo "[root@rhel3 ~]# kubectl create -f kubernetes-metrics-server/"
kubectl create -f kubernetes-metrics-server/

sleep 30

kubectl top no
kubectl top po --all-namespaces
