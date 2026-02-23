#!/bin/bash
set -euo pipefail

log() {
    echo "[monitoring] $1"
}

log "Removing any existing DCGM packages..."
if dpkg -l | grep -q datacenter-gpu-manager; then
    sudo apt purge -y datacenter-gpu-manager datacenter-gpu-manager-config || true
fi

log "Updating apt..."
sudo apt-get update -y

###############################################
# 1. Detect CUDA major version correctly
###############################################
# nvidia-smi reports CUDA version directly; use that instead of driver version
CUDA_VERSION=$(nvidia-smi --query-gpu=cuda_version --format=csv,noheader | head -n 1 | cut -d'.' -f1)

if [[ -z "$CUDA_VERSION" ]]; then
    log "ERROR: Could not detect CUDA version from nvidia-smi."
    exit 1
fi

log "Detected CUDA major version: $CUDA_VERSION"

###############################################
# 2. Install DCGM matching CUDA version
###############################################
# Package naming pattern: datacenter-gpu-manager-<major>-cuda<major>
# Example: datacenter-gpu-manager-4-cuda12
PKG="datacenter-gpu-manager-4-cuda${CUDA_VERSION}"

log "Attempting to install $PKG..."
sudo apt-get install -y --install-recommends "$PKG" || {
    log "Package $PKG not found. Falling back to generic datacenter-gpu-manager."
    sudo apt-get install -y datacenter-gpu-manager
}

###############################################
# 3. Enable DCGM services
###############################################
if systemctl list-unit-files | grep -q nvidia-dcgm; then
    log "Enabling DCGM service..."
    sudo systemctl enable nvidia-dcgm || true
    sudo systemctl start nvidia-dcgm || true
fi

###############################################
# 4. Enable Fabric Manager if present
###############################################
if systemctl list-unit-files | grep -q nvidia-fabricmanager; then
    log "Enabling NVIDIA Fabric Manager..."
    sudo systemctl enable nvidia-fabricmanager || true
    sudo systemctl start nvidia-fabricmanager || true
fi

###############################################
# 5. Optional: Install DCGM Exporter for Prometheus
###############################################
if ! dpkg -l | grep -q dcgm-exporter; then
    log "Installing DCGM Exporter..."
    sudo apt-get install -y dcgm-exporter || true
fi

log "Monitoring setup complete."
