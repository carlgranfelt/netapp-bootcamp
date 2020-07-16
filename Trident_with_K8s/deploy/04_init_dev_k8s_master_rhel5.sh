#!/bin/bash
echo "#######################################################################################################"
echo "kubeadm init rhel5 master on the dev k8s cluster"
echo "#######################################################################################################"

systemctl enable kubelet && systemctl start kubelet
kubeadm init --token abcdef.0123456789abcdef
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
