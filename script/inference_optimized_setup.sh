#!/bin/bash
set -euo pipefail

log() { echo "[INFERENCE] $1"; }

###############################################
# vLLM
###############################################
log "Installing vLLM..."
uv pip install "vllm[cuda]"

###############################################
# TensorRT-LLM
###############################################
log "Installing TensorRT-LLM..."
uv pip install tensorrt_llm==0.12.0 --extra-index-url https://pypi.nvidia.com

###############################################
# Quantization + Tokenization
###############################################
log "Installing quantization libraries..."
uv pip install \
    bitsandbytes \
    autoawq \
    optimum \
    optimum-nvidia

log "Inference layer complete."
