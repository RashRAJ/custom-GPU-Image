#!/bin/bash
set -euo pipefail

log() { echo "[FRAMEWORK] $1"; }

###############################################
# Python + Build Tools
###############################################
log "Installing Python and build tools..."
sudo apt-get update -y
sudo apt-get install -y \
    python3 python3-pip python3-venv python3-dev \
    build-essential git curl

sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

###############################################
# Install uv
###############################################
log "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

###############################################
# Install PyTorch (CUDA 12.1)
###############################################
PYTORCH_VERSION="${PYTORCH_VERSION:-2.5.1}"
log "Installing PyTorch ${PYTORCH_VERSION}..."
uv pip install \
    torch==${PYTORCH_VERSION} \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu121

###############################################
# Install Core ML Libraries
###############################################
log "Installing ML libraries..."
uv pip install \
    transformers \
    accelerate \
    tokenizers \
    sentencepiece \
    hf_transfer \
    triton \
    xformers \
    flash-attn --no-build-isolation \
    cupy-cuda12x \
    cupynumeric \
    warp-lang

log "Framework layer complete."
