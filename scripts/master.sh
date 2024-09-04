#!/bin/bash
#
# Setup for Control Plane (Master) servers

set -euxo pipefail

# If you need public access to API server using the servers Public IP adress, change PUBLIC_IP_ACCESS to true.

PUBLIC_IP_ACCESS="false"
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"

# Pull required images

sudo kubeadm config images pull

# Initialize kubeadm 
if [[ "$PUBLIC_IP_ACCESS" == "false" ]]; then
    
    # Extract the IP address from the kubelet configuration file
    MASTER_PRIVATE_IP=$(grep -oP '(?<=--node-ip=)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' /etc/default/kubelet)

    # Check if the IP address was found
    if [ -z "$MASTER_PRIVATE_IP" ]; then
        echo "No IP address found in the kubelet configuration."
        exit 1
    fi
    sudo kubeadm init --apiserver-advertise-address="$MASTER_PRIVATE_IP" --apiserver-cert-extra-sans="$MASTER_PRIVATE_IP" --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap

elif [[ "$PUBLIC_IP_ACCESS" == "true" ]]; then

    MASTER_PUBLIC_IP=$(curl ifconfig.me && echo "")
    sudo kubeadm init --control-plane-endpoint="$MASTER_PUBLIC_IP" --apiserver-cert-extra-sans="$MASTER_PUBLIC_IP" --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap

else
    echo "Error: MASTER_PUBLIC_IP has an invalid value: $PUBLIC_IP_ACCESS"
    exit 1
fi

# Configure kubeconfig

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Install Claico Network Plugin Network 

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
