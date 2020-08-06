#!/bin/bash
echo "#######################################################################################################"
echo "kubeadm join dev k8s worker node rhel6"
echo "#######################################################################################################"

systemctl daemon-reload && systemctl enable kubelet && systemctl restart kubelet
kubeadm reset -f
kubeadm join 192.168.0.66:6443 --token abcdef.0123456789abcdef --discovery-token-unsafe-skip-ca-verification

