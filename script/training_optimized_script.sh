#!/bin/bash
set -euo pipefail

[ "${ENABLE_TRAINING:-false}" = "true" ] || { echo "[TRAINING] Disabled, skipping."; exit 0; }

log() { echo "[TRAINING] $1"; }

###############################################
# PyTorch
###############################################
# Update version and index for CUDA 13.1 compatibility
PYTORCH_VERSION="${PYTORCH_VERSION:-2.10.0}"
CUDA_INDEX="cu130" 

log "Installing PyTorch ${PYTORCH_VERSION} with CUDA ${CUDA_INDEX}..."

# Added --index-strategy to ensure uv resolves the CUDA wheel over the CPU-only PyPI version
sudo uv pip install --python /opt/ml/bin/python \
    torch==${PYTORCH_VERSION} \
    torchvision \
    torchaudio \
    --index-url "https://download.pytorch.org/whl/${CUDA_INDEX}" \
    --extra-index-url https://pypi.org \
    --index-strategy unsafe-best-match

###############################################
# Core ML Libraries
###############################################
log "Installing core ML libraries..."
sudo uv pip install --python /opt/ml/bin/python \
    transformers \
    accelerate \
    tokenizers \
    sentencepiece \
    hf_transfer

###############################################
# Distributed Training Libraries
###############################################
log "Installing DeepSpeed..."
sudo uv pip install --python /opt/ml/bin/python deepspeed

log "Installing Megatron-LM dependencies..."
sudo uv pip install --python /opt/ml/bin/python ninja einops

###############################################
# Data Pipeline Acceleration
###############################################
log "Installing DALI..."
sudo uv pip install --python /opt/ml/bin/python nvidia-dali-cuda120

sudo uv pip install --python /opt/ml/bin/python \
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
    libucx0 libucx-dev ucx-utils

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
