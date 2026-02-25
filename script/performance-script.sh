#!/bin/bash
set -euo pipefail

echo "[*] Applying GPU + OS performance optimizations..."

###############################################
# 1. NVIDIA GPU persistence + fabric manager
###############################################

sudo nvidia-smi -pm 1 || true
sudo systemctl enable nvidia-persistenced || true
sudo systemctl start nvidia-persistenced || true

if systemctl list-unit-files | grep -q nvidia-fabricmanager; then
    sudo systemctl enable nvidia-fabricmanager || true
    sudo systemctl start nvidia-fabricmanager || true
fi

###############################################
# 2. Disable swap + set swappiness
###############################################

sudo swapoff -a || true
sudo sed -i '/vm.swappiness/d' /etc/sysctl.conf
echo "vm.swappiness=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

###############################################
# 3. Hugepages for CPU-side throughput
###############################################

echo "vm.nr_hugepages=2048" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

###############################################
# 4. NUMA + topology tools
###############################################

sudo apt-get install -y \
    numactl libnuma1 libnuma-dev \
    hwloc cpuset \
    linux-tools-common linux-tools-$(uname -r)

###############################################
# 5. Disable irqbalance
###############################################

if systemctl list-unit-files | grep -q irqbalance; then
    sudo systemctl disable irqbalance || true
    sudo systemctl stop irqbalance || true
fi

echo "[*] Performance optimizations complete."
