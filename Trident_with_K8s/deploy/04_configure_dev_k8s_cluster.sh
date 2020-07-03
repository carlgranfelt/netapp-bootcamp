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
kubectl apply -f /root/NetApp-LoD/Trident_with_K8s/deploy/k8s_files/metallb-configmap-k8s-dev.yaml

# echo "#######################################################################################################"
# echo "Installing Trident with an Operator"
# echo "#######################################################################################################"

# echo tridentctl -n trident version

# kubectl create ns trident
# tridentctl install -n trident

# echo "#######################################################################################################"
# echo "Create K8S backend y Storage class"
# echo "#######################################################################################################"

# tridentctl create backend --filename demo-trident/demo/k8s_files/backend-nas.json -n trident
# kubectl apply -f demo-trident/demo/k8s_files/sc-nas-silver.yaml



