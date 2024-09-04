#!/bin/bash

# Install net-tools
sudo apt-get install net-tools

# Install etcdctl for managing etcd
# ETCD_VERSION=v3.4.13
# ETCD_ARCH=etcd-${ETCD_VERSION}-linux-amd64
# curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/${ETCD_ARCH}.tar.gz -o /tmp/etcd.tar.gz
# tar xzvf /tmp/etcd.tar.gz -C /usr/local/bin --strip-components=1 ${ETCD_ARCH}/etcdctl

# Install Helm for package management
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Kubernetes Dashboard 
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
