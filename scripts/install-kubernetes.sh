#!/bin/bash

# Kuernetes Variable Declaration
KUBERNETES_MAJOR_VERSION="1.30"
# Version to use can be found here https://github.com/kubernetes/kubernetes/releases

# Read the IP addresses from the configuration file
source /vagrant/ip_config.txt

# Install kubelet, kubectl and Kubeadm

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Replace the version in the URLs and file names with the extracted major.minor version
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_MAJOR_VERSION}/deb/Release.key" | sudo gpg --dearmor -o "/etc/apt/keyrings/kubernetes-${KUBERNETES_MAJOR_VERSION}-apt-keyring.gpg"
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-${KUBERNETES_MAJOR_VERSION}-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_MAJOR_VERSION}/deb/ /" | sudo tee "/etc/apt/sources.list.d/kubernetes-${KUBERNETES_MAJOR_VERSION}.list"

# Update the package list to include Kubernetes packages
sudo apt-get update -y

# Find the latest patch version for the specified major version using apt list
LATEST_PATCH_VERSION=$(apt list -a kubeadm 2>/dev/null | grep "$KUBERNETES_MAJOR_VERSION" | head -n 1 | awk '{print $2}')

echo "Using Kubernetes version: $LATEST_PATCH_VERSION"

sudo apt-get install -y kubelet="$LATEST_PATCH_VERSION" kubectl="$LATEST_PATCH_VERSION" kubeadm="$LATEST_PATCH_VERSION"
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



