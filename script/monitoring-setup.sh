#!/bin/bash
set -euo pipefail

log() {
    echo "[monitoring] $1"
}

###############################################
# 1. Detect CUDA major version
###############################################
CUDA_MAJOR=$(/usr/local/cuda/bin/nvcc --version 2>/dev/null | grep -oP 'release \K\d+' || echo "")
if [[ -z "${CUDA_MAJOR}" ]]; then
    log "ERROR: Could not detect CUDA major version. base.sh must run before monitoring-setup.sh."
    exit 1
fi
log "Detected CUDA major version: ${CUDA_MAJOR}"

###############################################
# 2. Purge old DCGM packages
###############################################
log "Removing old DCGM packages (if any)..."
sudo dpkg --list datacenter-gpu-manager &> /dev/null && \
    sudo apt purge --yes datacenter-gpu-manager || true

sudo dpkg --list datacenter-gpu-manager-config &> /dev/null && \
    sudo apt purge --yes datacenter-gpu-manager-config || true

###############################################
# 3. Install DCGM 4 for the correct CUDA version
###############################################
log "Installing datacenter-gpu-manager-4-cuda${CUDA_MAJOR}..."
sudo apt-get update -y
sudo apt-get install --yes --install-recommends \
    "datacenter-gpu-manager-4-cuda${CUDA_MAJOR}"

# Verify installation
DCGM_VER=$(dpkg -s "datacenter-gpu-manager-4-cuda${CUDA_MAJOR}" 2>/dev/null | awk '/^Version:/{print $2}')
log "DCGM 4 installed: ${DCGM_VER}"

###############################################
# 4. Enable DCGM services
###############################################
if systemctl list-unit-files | grep -q nvidia-dcgm; then
    log "Enabling DCGM service..."
    sudo systemctl enable nvidia-dcgm || true
    sudo systemctl start nvidia-dcgm || true
fi

###############################################
# 5. Enable Fabric Manager if present
###############################################
if systemctl list-unit-files | grep -q nvidia-fabricmanager; then
    log "Enabling NVIDIA Fabric Manager..."
    sudo systemctl enable nvidia-fabricmanager || true
    sudo systemctl start nvidia-fabricmanager || true
fi

###############################################
# 6. DCGM Exporter for Prometheus
###############################################
if ! dpkg -l | grep -q dcgm-exporter; then
    log "Installing DCGM Exporter..."
    sudo apt-get install -y dcgm-exporter || true
fi

log "Monitoring setup complete."
