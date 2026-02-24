#!/bin/bash
set -euo pipefail

log() { echo "[BASE] $1"; }

log "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

###############################################
# NVIDIA CUDA Repository
###############################################
log "Adding NVIDIA CUDA apt repository..."
curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb
sudo dpkg -i /tmp/cuda-keyring.deb
rm /tmp/cuda-keyring.deb
sudo apt-get update -y

###############################################
# NVIDIA Driver + CUDA Toolkit
###############################################
CUDA_VERSION="${CUDA_VERSION:-12-4}"
log "Installing NVIDIA driver and CUDA toolkit ${CUDA_VERSION}..."
sudo apt-get install -y \
    nvidia-driver-550 \
    cuda-toolkit-${CUDA_VERSION}

###############################################
# NVIDIA Container Runtime
###############################################
log "Installing NVIDIA container runtime..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

###############################################
# DCGM + Fabric Manager
###############################################
log "Installing DCGM..."
sudo apt-get install -y datacenter-gpu-manager

if systemctl list-unit-files | grep -q nvidia-fabricmanager; then
    sudo systemctl enable nvidia-fabricmanager
    sudo systemctl start nvidia-fabricmanager
fi

###############################################
# System Tuning
###############################################
log "Applying system tuning..."

# Disable swap
sudo swapoff -a
echo "vm.swappiness=0" | sudo tee /etc/sysctl.d/99-swappiness.conf

# Hugepages
echo "vm.nr_hugepages=2048" | sudo tee /etc/sysctl.d/99-hugepages.conf

# CPU governor
sudo apt-get install -y linux-tools-common linux-tools-$(uname -r)
sudo cpupower frequency-set -g performance || true

# NUMA tools
sudo apt-get install -y numactl libnuma-dev hwloc cpuset

# Disable irqbalance
sudo systemctl disable irqbalance || true
sudo systemctl stop irqbalance || true

sudo sysctl --system

log "Base layer complete."
