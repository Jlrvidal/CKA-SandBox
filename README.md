
# Kubernetes-CKA-Cluster

This repository provides a complete setup to create a Kubernetes cluster for practicing for the Certified Kubernetes Administrator (CKA) exam. The setup is automated using Vagrant and a series of shell scripts to quickly deploy a Kubernetes cluster on virtual machines.

## Project Structure

- **Vagrantfile**: Defines the virtual machines (VMs) for the Kubernetes cluster.
- **scripts/**: Contains various shell scripts to automate the setup and configuration of the Kubernetes cluster.
  - `install-kubernetes.sh`: Installs Kubernetes components on the VMs. By default we will be using CRI-O as the container runtime.
  - `kubeadm-init.sh`: Initializes kubeadm and install Weave Net for the network plugin. Used in controlplane provision only.
  - `install-tools.sh`: WIP - Installs essential and optional tools related with Kubernetes.
  - `join-node.sh`: Script to add worker nodes to the cluster. Used on workers node provision only.
- **ip_config.txt**: Contains the IP configuration details for the VMs. It is generated in the Vagrant file.
- **join.sh**: Script to join nodes to the Kubernetes cluster. The content is generated with the output of kubeadm init
- **WIP_containerd-install-kubernetes.sh**: A work-in-progress script for setting up Kubernetes with containerd as the container runtime.

## Prerequisites

- [Vagrant](https://www.vagrantup.com/) installed on your local machine.
- [VirtualBox](https://www.virtualbox.org/) or another Vagrant-supported provider installed.

## Setup Instructions

1. **Clone the repository**:
   ```sh
   git clone https://github.com/yourusername/Kubernetes-CKA-Cluster.git
   cd Kubernetes-CKA-Cluster
   ```

2. **Check cluster status**:
    ```sh
   vagrant status
   ```

3. **Bring up the Vagrant environment**:
   ```sh
   vagrant up
   ```

4. **Access to Controlplane node**:
   - SSH into the control plane node:
     ```sh
     vagrant ssh controlplane
     ```
5. **Verify the Cluster**:
   - Use `kubectl` to ensure that the nodes are up and running:
     ```sh
     kubectl get nodes
     kubectl get pods -A
     ```

## Contributing

Contributions are welcome! Please fork the repository, make your changes, and submit a pull request.
