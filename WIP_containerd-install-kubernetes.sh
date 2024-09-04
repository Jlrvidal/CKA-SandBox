#!/bin/bash

# Kuernetes Variable Declaration
KUBERNETES_VERSION="1.29.0-1.1"

# Path to the configuration file
IP_CONFIG_FILE="/vagrant/ip_config.txt"

# Read the IP addresses from the configuration file
source $IP_CONFIG_FILE

#Provides more accurate failure reporting for pipelines by making sure that the entire pipeline fails if any part of it fails.
set -euxo pipefail

#Followed steps in https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/ 

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply the sysctl parameters without rebooting
sudo sysctl --system

# Disable swap (Note: From 1.28 kubeadm has beta support for using swap with kubeadm clusters. Read https://kubernetes.io/blog/2023/08/24/swap-linux-beta/ to understand more.)
swapoff -a
sed -i '/swap/d' /etc/fstab

# Update system and install dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker apt repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker and containerd
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Configure containerd
mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Define the content you want to write to the file
new_content='[plugins."io.containerd.grpc.v1.cri"]
  [plugins."io.containerd.grpc.v1.cri".containerd]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        SystemdCgroup = true

  [plugins."io.containerd.grpc.v1.cri".registry]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.k8s.io"]
        endpoint = ["https://registry.k8s.io"]

  [plugins."io.containerd.grpc.v1.cri".sandbox_image]
    image = "registry.k8s.io/pause:3.10"'

# Write the new content to the /etc/containerd/config.toml file
echo "$new_content" | sudo tee /etc/containerd/config.toml > /dev/null

# Verify that the content has been written correctly
echo "The new content of /etc/containerd/config.toml is:"
cat /etc/containerd/config.toml

# Restart containerd with the new configuration
sudo systemctl restart containerd

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



