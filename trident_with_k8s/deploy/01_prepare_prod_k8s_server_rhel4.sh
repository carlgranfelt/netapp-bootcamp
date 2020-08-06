#!/bin/bash

echo "#######################################################################################################"
echo "Prepare production kubernetes server rhel4"
echo "#######################################################################################################"

echo "#######################################################################################################"
echo "Download the GitHub NetApp-LoD repository"
echo "#######################################################################################################"

# MUST REMOVE COMMENT ONCE REPO IS PUBLIC!!!
# git clone <https://github.com/carlgranfelt/NetApp-LoD.git>
scp -r -q -o "StrictHostKeyChecking no" root@rhel3:/root/NetApp-LoD/ /root

echo "#######################################################################################################"
echo "Preparing the host - firewall and security"
echo "#######################################################################################################"

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

setenforce 0

echo "#######################################################################################################"
echo "Disabling swap"
echo "#######################################################################################################"

swapoff -a
cat <<EOF > /etc/fstab
#
# /etc/fstab
# Created by anaconda on Tue Jun 16 18:54:04 2015
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/rhel-root   /                       xfs     defaults        0 0
UUID=69278624-810b-4c7a-97e4-9d236b939b2a /boot                   xfs     defaults        0 0
#/dev/mapper/rhel-swap   swap                    swap    defaults        0 0
/dev/sdb1    /var/lib/docker                    xfs     defaults        0 0
192.168.0.132:/registry /mnt/registry           nfs     defaults        0 0
EOF

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

