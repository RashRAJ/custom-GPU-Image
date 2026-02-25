#!/bin/bash
set -euo pipefail

log()   { echo "[BASE] $1"; }
error() { echo "[BASE][ERROR] $1" >&2; exit 1; }

###############################################################
# Required environment variables (set in Packer var-file)
#   DRIVER_VERSION  e.g. 590.48.01
#   CUDA_VERSION    e.g. 13-1
#
# Packer HCL example:
#   variable "driver_version" { default = "590.48.01" }
#   variable "cuda_version"   { default = "13-1" }
#
#   provisioner "shell" {
#     environment_vars = [
#       "DRIVER_VERSION=${var.driver_version}",
#       "CUDA_VERSION=${var.cuda_version}",
#     ]
#     script = "./scripts/base.sh"
#   }
###############################################################
[[ -z "${DRIVER_VERSION:-}" ]] && error "DRIVER_VERSION is not set."
[[ -z "${CUDA_VERSION:-}"   ]] && error "CUDA_VERSION is not set."

log "DRIVER_VERSION : ${DRIVER_VERSION}"
log "CUDA_VERSION   : ${CUDA_VERSION}"

DISTRO=$(. /etc/os-release && echo "${ID}${VERSION_ID}" | tr -d '.')
ARCH="x86_64"

export DEBIAN_FRONTEND=noninteractive

###############################################################
# 1. System update
###############################################################
log "Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -qq -y

###############################################################
# 2. Pre-installation — kernel headers
#    Source: https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/ubuntu.html
###############################################################
log "Installing kernel headers and build tools..."
sudo apt-get install -qq -y \
  "linux-headers-$(uname -r)" \
  build-essential \
  dkms \
  curl \
  wget

###############################################################
# 3. NVIDIA CUDA Network Repository
#    Source: NVIDIA Driver Installation Guide — Network Repository Enablement (amd64)
###############################################################
log "Adding NVIDIA CUDA apt repository (${DISTRO})..."
wget -q "https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${ARCH}/cuda-keyring_1.1-1_all.deb" \
  -O /tmp/cuda-keyring.deb
sudo dpkg -i /tmp/cuda-keyring.deb
rm /tmp/cuda-keyring.deb
sudo apt-get update -qq

###############################################################
# 4. Pin driver version BEFORE installation (590+ requirement)
#    Source: NVIDIA Driver Installation Guide — Version locking
#    "For the best experience when locking a branch, we suggest
#     installing the pinning package prior to installing the driver."
###############################################################
log "Pinning driver to version ${DRIVER_VERSION}..."
sudo apt-get install -qq -y "nvidia-driver-pinning-${DRIVER_VERSION}"

###############################################################
# 5. Compute-only (headless) driver — Open Kernel Modules
#    Source: NVIDIA Driver Installation Guide — Compute-only System (Open Kernel Modules)
#
#    libnvidia-compute  = compute libraries only (no GL/Vulkan/display)
#    nvidia-dkms-open   = open-source kernel module built via DKMS
#
#    Open kernel modules are the NVIDIA-recommended choice for
#    Ampere, Hopper, and Blackwell data centre GPUs (A100, H100, etc.)
###############################################################
log "Installing NVIDIA compute-only driver (open kernel modules)..."
sudo apt-get -V install -y \
  libnvidia-compute \
  nvidia-dkms-open

###############################################################
# 6. CUDA Toolkit
###############################################################
log "Installing CUDA Toolkit ${CUDA_VERSION}..."
sudo apt-get install -qq -y "cuda-toolkit-${CUDA_VERSION}"

# Persist CUDA paths for all users and sessions
cat <<'EOF' | sudo tee /etc/profile.d/cuda.sh
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}
EOF
echo "/usr/local/cuda/lib64" | sudo tee /etc/ld.so.conf.d/cuda.conf
sudo ldconfig

###############################################################
# 7. NVIDIA Container Toolkit
#    Required for GPU workloads in Docker / containerd / Kubernetes
###############################################################
log "Installing NVIDIA Container Toolkit..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update -qq
sudo apt-get install -qq -y nvidia-container-toolkit

# Configure for containerd (primary Kubernetes runtime)
sudo nvidia-ctk runtime configure --runtime=containerd

# Configure for Docker if present on this image
if systemctl list-unit-files | grep -q "^docker.service"; then
  sudo nvidia-ctk runtime configure --runtime=docker
fi

###############################################################
# 8. DCGM — DataCenter GPU Manager
#    Driver 590+ requires DCGM 4.3.x minimum
###############################################################
log "Installing DCGM..."
sudo apt-get install -qq -y datacenter-gpu-manager

# Validate version meets the 4.3 minimum required by driver 590+
DCGM_VER=$(dpkg -s datacenter-gpu-manager 2>/dev/null | awk '/^Version:/{print $2}')
DCGM_MAJOR=$(echo "${DCGM_VER}" | cut -d. -f1)
DCGM_MINOR=$(echo "${DCGM_VER}" | cut -d. -f2)
if [[ "${DCGM_MAJOR}" -lt 4 ]] || { [[ "${DCGM_MAJOR}" -eq 4 ]] && [[ "${DCGM_MINOR}" -lt 3 ]]; }; then
  error "DCGM ${DCGM_VER} is below the 4.3 minimum required for driver 590+. Check your CUDA repo."
fi
log "DCGM installed: ${DCGM_VER}"

sudo systemctl enable nvidia-dcgm
sudo systemctl start  nvidia-dcgm

# Fabric Manager — only needed for NVLink/NVSwitch GPUs (A100/H100 multi-GPU nodes)
if systemctl list-unit-files | grep -q "^nvidia-fabricmanager.service"; then
  log "Enabling nvidia-fabricmanager for NVLink GPUs..."
  sudo systemctl enable nvidia-fabricmanager
  sudo systemctl start  nvidia-fabricmanager
fi

###############################################################
# 9. NVIDIA Persistence Daemon
#    Keeps the driver loaded between jobs — reduces cold-start
#    latency on the first CUDA call in each new workload
#    Source: NVIDIA Post-installation Actions — Persistence Daemon
###############################################################
log "Enabling nvidia-persistenced..."
sudo systemctl enable nvidia-persistenced
sudo systemctl start  nvidia-persistenced

###############################################################
# 10. System tuning for GPU compute workloads
###############################################################
log "Applying system tuning..."

# Disable swap (critical for Kubernetes scheduler and ML stability)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
echo "vm.swappiness=0"     | sudo tee /etc/sysctl.d/99-gpu-swappiness.conf

# Hugepages — reduces TLB pressure for large memory allocations
echo "vm.nr_hugepages=2048" | sudo tee /etc/sysctl.d/99-gpu-hugepages.conf

# CPU performance governor
sudo apt-get install -qq -y linux-tools-common "linux-tools-$(uname -r)" || true
sudo cpupower frequency-set -g performance || true

# NUMA and topology tools for GPU affinity tuning
sudo apt-get install -qq -y numactl libnuma-dev hwloc

# Disable irqbalance — let NVIDIA driver manage interrupt affinity
sudo systemctl disable irqbalance || true
sudo systemctl stop    irqbalance || true

# Apply all sysctl settings now
sudo sysctl --system

###############################################################
# Done
###############################################################
log "============================================"
log "Base layer provisioning complete."
log "  OS      : ${DISTRO}"
log "  Driver  : ${DRIVER_VERSION} (open kernel modules, compute-only)"
log "  CUDA    : cuda-toolkit-${CUDA_VERSION}"
log "  DCGM    : ${DCGM_VER}"
log "============================================"
