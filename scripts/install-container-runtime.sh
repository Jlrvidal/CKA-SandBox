#!/bin/bash

# Provides more accurate failure reporting for pipelines by making sure that the entire pipeline fails if any part of it fails.
set -euxo pipefail

# Disable swap
sudo swapoff -a

# Keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y



#containerd
# TODO Logic to select one container runtime or another

######  CRI-O  ######
/vagrant/scripts/container-runtime/install-CRI-O.sh