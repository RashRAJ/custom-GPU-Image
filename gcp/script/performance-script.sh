#!/bin/bash
set -euo pipefail

# Enable NVIDIA persistence mode for better performance
sudo nvidia-smi -pm 1

# Enable NVIDIA persistence daemon on startup
sudo systemctl enable nvidia-persistenced