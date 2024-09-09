# Define the number of worker nodes
NUM_WORKERS = 1

# Network parameters for NAT mode
NETWORK_IP = "192.168.56"
MASTER_IP_START = 11
NODE_IP_START = 20

# Allocate Master nodes resources
MASTER_MEM = "2048"
MASTER_CPU = 2

# Allocate Worker nodes resources
WORKER_MEM = "2048"
WORKER_CPU = 2

POD_NETWORK_CIDR= "192.168.0.0/16"

# Define a path for the IP configuration file
ip_config_file = "ip_config.txt"

#TODO - Explore BRIDGE option (Current build mode NAT)
#TODO HA controlplane
#TODO Selectable Kubernete Version

Vagrant.configure("2") do |config|
  scripts_path = "scripts/"

  # Common VM configuration
  config.vm.box = "ubuntu/jammy64"

  # Define the master and worker nodes
  master_ip = "#{NETWORK_IP}.#{MASTER_IP_START}"
  worker_ips = (1..NUM_WORKERS).map { |i| "#{NETWORK_IP}.#{NODE_IP_START + i}" }
  
  # Define /etc/hosts entries
  hosts_entries = [
    "#{master_ip} controlplane",
    *worker_ips.each_with_index.map { |ip, i| "#{ip} worker0#{i+1}" }
  ]

  # Create an IP configuration file for kubeadm-init script
  config.vm.provision "shell", inline: <<-SHELL
    # Initialize the file and write the first two variables
    echo "POD_NETWORK_CIDR=#{POD_NETWORK_CIDR}" > /vagrant/#{ip_config_file}
    echo "NETWORK_IP=#{NETWORK_IP}" >> /vagrant/#{ip_config_file}
    # add nodes IP to etc/hosts
    echo "#{hosts_entries.join("\n")}" >> /etc/hosts
  SHELL

  # Control Plane Node
  config.vm.define "controlplane" do |master|
    master.vm.hostname = "controlplane"
    master.vm.network "private_network",  ip: master_ip
    master.vm.network "forwarded_port", guest: 30000, host: 30000, protocol: "tcp"
    master.vm.network "forwarded_port", guest: 32000, host: 32000, protocol: "tcp"
    
    # Allocate resources
    master.vm.provider "virtualbox" do |vb|
      vb.memory = MASTER_MEM
      vb.cpus = MASTER_CPU
    end
    
    # Provisioning steps
    master.vm.provision "shell", path: "#{scripts_path}/install-container-runtime.sh"
    master.vm.provision "shell", path: "#{scripts_path}/install-kubernetes.sh"
    master.vm.provision "shell", path: "#{scripts_path}/kubeadm-init.sh"
    master.vm.provision "shell", path: "#{scripts_path}/install-tools.sh"
  end

  # Worker Nodes
  (1..NUM_WORKERS).each do |i|
    config.vm.define "worker0#{i}" do |node|
      node.vm.hostname = "worker0#{i}"
      node.vm.network "private_network", ip: worker_ips[i-1]
      
      # Allocate resources 
      node.vm.provider "virtualbox" do |vb|
        vb.memory = WORKER_MEM
        vb.cpus = WORKER_CPU
      end
      
      # Provisioning steps
      node.vm.provision "shell", path: "#{scripts_path}/install-container-runtime.sh"
      node.vm.provision "shell", path: "#{scripts_path}/install-kubernetes.sh"
      node.vm.provision "shell", path: "#{scripts_path}/join-node.sh"
    end
  end
end
