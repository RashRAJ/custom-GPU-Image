#!/bin/bash
set -euo pipefail

# Remove existing datacenter-gpu-manager if installed
sudo dpkg --list datacenter-gpu-manager &> /dev/null && \
  sudo apt purge --yes datacenter-gpu-manager

sudo dpkg --list datacenter-gpu-manager-config &> /dev/null && \
  sudo apt purge --yes datacenter-gpu-manager-config

sudo apt-get update

# Detect CUDA version from installed driver
log "Detect CUDA version from installed driver"
CUDA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1 | cut -d'.' -f1)
sudo apt-get install --yes \
                       --install-recommends \
                       datacenter-gpu-manager-4-cuda${CUDA_VERSION}