#!/bin/bash

# Kuernetes Variable Declaration
KUBERNETES_VERSION="1.29.0-1.1"
# Version to use can be found here https://github.com/kubernetes/kubernetes/releases

# Read the IP addresses from the configuration file
source /vagrant/ip_config.txt

# Provides more accurate failure reporting for pipelines by making sure that the entire pipeline fails if any part of it fails.
set -euxo pipefail

# Disable swap
sudo swapoff -a

# Keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y

# Install the container runtime selected (default CRI-O)
/vagrant/scripts/install-container-runtime.sh

# Install kubelet, kubectl and Kubeadm

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Extract the major and minor version
MAJOR_MINOR_VERSION=$(echo "$KUBERNETES_VERSION" | awk -F'[.-]' '{print $1"."$2}')

# Check if MAJOR_MINOR_VERSION is correctly extracted
if [ -z "$MAJOR_MINOR_VERSION" ]; then
    echo "Unable to extract major and minor version from KUBERNETES_VERSION."
    exit 1
fi

echo "Using Kubernetes version: $KUBERNETES_VERSION"
echo "Major.Minor version: $MAJOR_MINOR_VERSION"

# Replace the version in the URLs and file names with the extracted major.minor version
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${MAJOR_MINOR_VERSION}/deb/Release.key" | sudo gpg --dearmor -o "/etc/apt/keyrings/kubernetes-${MAJOR_MINOR_VERSION}-apt-keyring.gpg"
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-${MAJOR_MINOR_VERSION}-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${MAJOR_MINOR_VERSION}/deb/ /" | sudo tee "/etc/apt/sources.list.d/kubernetes-${MAJOR_MINOR_VERSION}.list"

sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
sudo apt-get update -y
sudo apt-mark hold kubelet kubeadm kubectl

# Installing a command-line JSON processing tool, necessary for next steps
sudo apt-get install -y jq

# Function to find the IP matching the 192.168.56.x subnet
get_matching_ip() {
    ip --json addr show | jq -r '.[] | .addr_info[] | select(.family == "inet") | .local' | grep "^${NETWORK_IP}\." | head -n 1
}

# Get the IP address that matches the subnet
local_ip=$(get_matching_ip)

# Check if a matching IP was found
if [ -z "$local_ip" ]; then
    echo "No matching IP found in the 192.168.56.x subnet."
    exit 1
fi

# Write the KUBELET_EXTRA_ARGS with the found IP
sudo bash -c "cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF"

echo "Kubelet configured with IP: $local_ip"



