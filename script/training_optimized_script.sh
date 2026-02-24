#!/bin/bash
set -euo pipefail

[ "${ENABLE_TRAINING:-false}" = "true" ] || { echo "[TRAINING] Disabled, skipping."; exit 0; }

log() { echo "[TRAINING] $1"; }

###############################################
# Distributed Training Libraries
###############################################
log "Installing DeepSpeed..."
uv pip install deepspeed

log "Installing Megatron-LM dependencies..."
uv pip install ninja einops

###############################################
# Data Pipeline Acceleration
###############################################
log "Installing DALI..."
pip install nvidia-dali-cuda120

uv pip install \
    opencv-python-headless \
    pyarrow \
    fsspec s3fs gcsfs \
    aiofiles uvloop

###############################################
# UCX + RDMA + NCCL Tuning
###############################################
log "Installing UCX + RDMA..."
sudo apt-get install -y \
    rdma-core \
    infiniband-diags \
    ibverbs-providers \
    libibverbs1 \
    libmlx5-1 \
    ucx ucx-tools \
    nccl-rdma-sharp-plugins

###############################################
# Network sysctl tuning
###############################################
log "Applying network tuning..."
sudo tee /etc/sysctl.d/99-training-network.conf >/dev/null <<EOF
net.core.rmem_max=268435456
net.core.wmem_max=268435456
net.core.netdev_max_backlog=250000
net.core.somaxconn=65535
net.ipv4.tcp_rmem=4096 87380 268435456
net.ipv4.tcp_wmem=4096 65536 268435456
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_mtu_probing=1
EOF

sudo sysctl --system

log "Training layer complete."
