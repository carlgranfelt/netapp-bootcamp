#!/bin/bash
echo "#######################################################################################################"
echo "kubeadm join rhel4 worker node to prod k8s cluster"
echo "#######################################################################################################"

systemctl enable kubelet && systemctl start kubelet
kubeadm reset -f

# Get new bootstrap token due to kubernetes issue #89882
scp -r -q -o "StrictHostKeyChecking no" root@rhel3:/root/kubeadm_token.txt /root
token=($(cat kubeadm_token.txt))
kubeadm join 192.168.0.63:6443 --token $token --discovery-token-ca-cert-hash sha256:8469a0fe236e02b5c4834196a3d85ce1b5352598a824010dced8cb5e0f43f4c5
