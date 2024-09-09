#!/bin/bash

# Path to the configuration file
IP_CONFIG_FILE="/vagrant/ip_config.txt"

# Read the IP addresses from the configuration file
source $IP_CONFIG_FILE

# Extract the IP address from the kubelet configuration file
CONTROL_PLANE_IP=$(grep -oP '(?<=--node-ip=)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' /etc/default/kubelet)

# Check if the IP address was found
if [ -z "$CONTROL_PLANE_IP" ]; then
    echo "No IP address found in the kubelet configuration."
    exit 1
fi

sudo apt-get update -y

# Pull required images
sudo kubeadm config images pull

# Initialize the Kubernetes control plane with POD CIDR
sudo kubeadm init --pod-network-cidr="$POD_NETWORK_CIDR" --apiserver-advertise-address="$CONTROL_PLANE_IP" --node-name "$(hostname -s)" --ignore-preflight-errors=all

# Check if kubeadm init was successful
if [ $? -ne 0 ]; then
  echo "kubeadm init failed"
  exit 1
fi

# Continue with the rest of your script
echo "kubeadm init completed successfully"

# Set up kubeconfig for the vagrant user
mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

# Check for kubectl availability
echo "Checking kubectl availability..."
if ! kubectl version --client >/dev/null 2>&1; then
  echo "kubectl is not installed or not available in PATH"
  exit 1
fi

echo "kubectl is installed and available"

# Export PATH for kubectl
export PATH=/usr/local/bin:/usr/bin:/bin

# Ensure kubeconfig is correctly set for root
mkdir -p /root/.kube
cp /home/vagrant/.kube/config /root/.kube/config

# Wait for Kubernetes control plane to be ready
echo "Waiting for Kubernetes control plane to be ready..."
attempt_counter=0
max_attempts=10

until kubectl get nodes >/dev/null 2>&1; do
  if [ ${attempt_counter} -eq ${max_attempts} ]; then
    echo "Max attempts reached, exiting..."
    exit 1
  fi

  echo "Waiting for Kubernetes API server to be ready... (${attempt_counter}/${max_attempts})"
  attempt_counter=$((attempt_counter+1))
  sleep 10
done

echo "Kubernetes is ready"

# Install Weave Net for the network plugin
echo "Installing Weave Net network plugin..."
kubectl apply -f https://reweave.azurewebsites.net/k8s/v1.29/net.yaml > /tmp/kubectl_apply.log 2>&1

# Check if the installation was successful
if [ $? -ne 0 ]; then
  echo "Weave Net installation failed. Check /tmp/kubectl_apply.log for details."
  exit 1
fi

echo "Weave Net installation completed successfully"

# Save the kubeadm join command for worker nodes
echo "Saving kubeadm join command for worker nodes..."
sudo kubeadm token create --print-join-command > /vagrant/join.sh

echo "kubeadm SETUP completed successfully"