# GCP GPU-Enabled Image Builder

Packer configuration for building GCP compute images with NVIDIA GPU support and monitoring capabilities.

## Overview

This Packer build creates a Debian-based GCP image with:
- NVIDIA GPU drivers (version 590.48.01)
- CUDA Toolkit 13.1
- cuDNN libraries
- PyTorch with CUDA 12.1 support
- vLLM for LLM inference
- NVIDIA Dynamo (torch.compile)
- DCGM (Data Center GPU Manager) for GPU monitoring
- GPU persistence mode enabled
- Kernel DKMS support for automatic driver rebuilds

## Build Process

The build performs the following steps:
1. System update and upgrade
2. Reboot to apply kernel updates
3. Install DKMS, kernel headers, and build essentials
4. Install NVIDIA GPU drivers and CUDA ([gpu-driver-script.sh](script/gpu-driver-script.sh))
5. Install ML frameworks: PyTorch, vLLM, NVIDIA Dynamo ([ml-frameworks-script.sh](script/ml-frameworks-script.sh))
6. Enable GPU persistence mode ([performance-script.sh](script/performance-script.sh))
7. Install DCGM for monitoring ([monitoring-setup.sh](script/monitoring-setup.sh))

## Prerequisites

- Packer installed
- GCP credentials configured
- Valid GCP project with Compute Engine API enabled

## Usage

```bash
packer init .
packer build build.pkr.hcl
```

## Useful GCloud Commands

### Check GPU Availability in Your Zone
```bash
gcloud compute accelerator-types list --filter="zone:europe-west1-c"
```
Verify if specific GPU types are available in your target zone before configuring them in your Packer template.

### List Debian Images
```bash
gcloud compute images list --project debian-cloud --filter="family:debian-12"
```
Find the latest Debian 12 images for use as source images in your builds.

## Components

### DKMS (Dynamic Kernel Module Support)
A framework that automatically rebuilds kernel modules (like NVIDIA drivers) whenever you update your Linux kernel, preventing driver breakage after system updates.

### Build Essentials
Includes necessary compilers (`gcc`, `make`) required for building kernel modules.

### Kernel Headers
Must match your currently running kernel version for proper driver compilation.

## References

- [NVIDIA Driver Downloads](https://www.nvidia.com/en-us/drivers/)
- [DCGM Exporter](https://github.com/NVIDIA/dcgm-exporter) - Prometheus metrics exporter for GPU monitoring (not yet implemented)
- [AI Dynamo](https://github.com/ai-dynamo/dynamo) - High-throughput distributed inference framework for LLMs with disaggregated prefill/decode and dynamic GPU scheduling

## TODO

- [ ] Add DCGM Prometheus exporter configuration
- [ ] Add automated testing for GPU functionality
