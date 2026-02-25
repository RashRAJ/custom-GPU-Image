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
# Install uv (available system-wide for users)
###############################################
log "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
sudo cp "$HOME/.local/bin/uv" /usr/local/bin/uv
sudo cp "$HOME/.local/bin/uvx" /usr/local/bin/uvx

###############################################
# Shared ML virtual environment at /opt/ml
###############################################
log "Creating shared ML venv at /opt/ml..."
sudo python3 -m venv /opt/ml
sudo /opt/ml/bin/pip install --upgrade pip

# Expose /opt/ml to all users on login
echo 'export PATH=/opt/ml/bin:$PATH' | sudo tee /etc/profile.d/ml-venv.sh

log "Framework layer complete."
