#!/bin/bash
set -e

# Download and install driver repo (conrifm your machine type and change accordingly)
curl -O https://us.download.nvidia.com/tesla/590.48.01/nvidia-driver-local-repo-debian12-590.48.01_1.0-1_amd64.deb
sudo dpkg -i nvidia-driver-local-repo-debian12-590.48.01_1.0-1_amd64.deb

# Copy the GPG key
sudo cp /var/nvidia-driver-local-repo-debian12-590.48.01/nvidia-driver-local-*.gpg /usr/share/keyrings/

# Update apt and install driver
sudo apt update
sudo apt install -y cuda-drivers-590

# Install CUDA Toolkit 13.1
wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-13-1

# Install cuDNN
sudo apt-get install -y libcudnn9-cuda-13 libcudnn9-dev-cuda-13

# Configure library path
echo /usr/local/cuda/lib64 | sudo tee /etc/ld.so.conf.d/cuda.conf
sudo ldconfig

# Set environment variables
echo 'export PATH=/usr/local/cuda/bin:$PATH' | sudo tee /etc/profile.d/cuda.sh
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' | sudo tee -a /etc/profile.d/cuda.sh

# Cleanup
rm -f nvidia-driver-local-repo-debian12-590.48.01_1.0-1_amd64.deb
rm -f cuda-keyring_1.1-1_all.deb

# Verify installation
nvidia-smi
nvcc --version