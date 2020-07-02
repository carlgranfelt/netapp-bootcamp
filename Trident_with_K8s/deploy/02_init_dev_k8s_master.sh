#!/bin/bash
echo "#######################################################################################################"
echo "kubeadm init the dev k8s master node"
echo "#######################################################################################################"

systemctl daemon-reload && systemctl enable kubelet && systemctl start kubelet
kubeadm init --token abcdef.0123456789abcdef
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
