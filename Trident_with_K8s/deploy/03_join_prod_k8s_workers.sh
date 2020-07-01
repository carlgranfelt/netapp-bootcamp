#!/bin/bash
echo "#######################################################################################################"
echo "kubeadm join in the k8s worker node"
echo "#######################################################################################################"

systemctl daemon-reload && systemctl enable kubelet && systemctl start kubelet
kubeadm reset -f
kubeadm join 192.168.0.63:6443 --token 1fpzhb.diqla6g7x83b4iah --discovery-token-ca-cert-hash sha256:8469a0fe236e02b5c4834196a3d85ce1b5352598a824010dced8cb5e0f43f4c5
