#!/bin/bash
echo "#######################################################################################################"
echo "Prepare Dev kubernetes servers"
echo "#######################################################################################################"

echo "#######################################################################################################"
echo "Download the GitHub netapp-bootcamp repository"
echo "#######################################################################################################"

# MUST REMOVE COMMENT ONCE REPO IS PUBLIC!!!
# git clone <https://github.com/carlgranfelt/netapp-bootcamp.git>
scp -r -q -o "StrictHostKeyChecking no" root@rhel3:/root/netapp-bootcamp/ /root

echo "#######################################################################################################"
echo "Preparing the host - firewall and security"
echo "#######################################################################################################"

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo "#######################################################################################################"
echo "Disabling swap"
echo "#######################################################################################################"

swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

echo "#######################################################################################################"
echo "Enabling the Kubernetes repository"
echo "#######################################################################################################"

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

#echo "#######################################################################################################"
#echo "Setting the Trident path"
#echo "#######################################################################################################"

#cat <<EOF > ~/.bash_profile
# .bash_profile

# Get the aliases and functions
#if [ -f ~/.bashrc ]; then
#        . ~/.bashrc
#fi

# User specific environment and startup programs

#PATH=$PATH:$HOME/bin
#PATH="/root/trident-installer:$PATH"

#export PATH
#EOF

echo "#######################################################################################################"
echo "Installing kubelet, kubeadm and kubectl"
echo "#######################################################################################################"

yum -y install kubelet-1.18.0 kubeadm-1.18.0 kubectl-1.18.0 --nogpgcheck

