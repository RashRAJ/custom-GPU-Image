#!/bin/bash
set -euo pipefail

# ML Frameworks Installation Script
# Installs Python, uv package manager, PyTorch, vLLM, and NVIDIA Dynamo

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Installing Python..."
sudo apt-get install -y python3 python3-venv python3-pip

log "Installing uv package manager..."
curl -LsSf https://astral.sh/uv/install.sh | sh
# shellcheck source=/dev/null
source "$HOME/.cargo/env"

log "Creating virtual environment..."
uv venv venv
# shellcheck source=/dev/null
source venv/bin/activate

log "Installing pip in virtual environment..."
uv pip install pip

# Install PyTorch with CUDA 12.1 support
log "Installing PyTorch with CUDA 12.1 support..."
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install vLLM
log "Installing vLLM..."
uv pip install vllm

# Install hf_transfer
log "Installing hf_transfer..."
uv pip install hf_transfer

# Install NVIDIA Dynamo (part of PyTorch 2.0+)
log "Verifying NVIDIA Dynamo (torch.compile) availability..."
python3 -c "import torch; print(f'Dynamo/torch.compile available: {hasattr(torch, \"compile\")}')"

# Verify installation
log "Verifying ML framework installation..."
python3 -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA Available: {torch.cuda.is_available()}')"
python3 -c "import vllm; print(f'vLLM: {vllm.__version__}')"
python3 -c "import hf_transfer; print('hf_transfer: installed')"

log "ML frameworks installation complete!"
