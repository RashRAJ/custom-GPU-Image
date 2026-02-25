#!/bin/bash
set -euo pipefail

[ "${ENABLE_INFERENCE:-false}" = "true" ] || { echo "[INFERENCE] Disabled, skipping."; exit 0; }

log() { echo "[INFERENCE] $1"; }

###############################################
# PyTorch
###############################################
PYTORCH_VERSION="${PYTORCH_VERSION:-2.5.1}"
log "Installing PyTorch ${PYTORCH_VERSION}..."
sudo uv pip install --python /opt/ml/bin/python \
    torch==${PYTORCH_VERSION} \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu121

###############################################
# Core ML Libraries
###############################################
log "Installing core ML libraries..."
sudo uv pip install --python /opt/ml/bin/python \
    transformers \
    accelerate \
    tokenizers \
    sentencepiece \
    hf_transfer \
    triton \
    xformers \
    cupy-cuda12x \
    cupynumeric \
    warp-lang

sudo uv pip install --python /opt/ml/bin/python \
    flash-attn --no-build-isolation

###############################################
# vLLM
###############################################
log "Installing vLLM..."
sudo uv pip install --python /opt/ml/bin/python "vllm[cuda]"

###############################################
# TensorRT-LLM
###############################################
log "Installing TensorRT-LLM..."
sudo uv pip install --python /opt/ml/bin/python \
    tensorrt_llm==0.12.0 --extra-index-url https://pypi.nvidia.com

###############################################
# Quantization + Tokenization
###############################################
log "Installing quantization libraries..."
sudo uv pip install --python /opt/ml/bin/python \
    bitsandbytes \
    autoawq \
    optimum \
    optimum-nvidia

log "Inference layer complete."
