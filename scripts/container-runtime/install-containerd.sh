#!/bin/bash

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



