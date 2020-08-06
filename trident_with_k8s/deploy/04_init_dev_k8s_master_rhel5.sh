#!/bin/bash
echo "#######################################################################################################"
echo "kubeadm init in the k8s master node rhel5"
echo "#######################################################################################################"

systemctl daemon-reload && systemctl enable kubelet && systemctl restart kubelet 
kubeadm reset -f
kubeadm init --token abcdef.0123456789abcdef --v=5
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
