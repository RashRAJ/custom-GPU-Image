# GPU-Enabled Image Builder

Packer templates for building cloud compute images with NVIDIA GPU support and monitoring capabilities across multiple cloud providers.

## Overview

This Packer build creates a compute image with:
- NVIDIA GPU drivers (version 590.48.01)
- CUDA Toolkit 13.1
- cuDNN libraries
- PyTorch with CUDA 12.1 support
- vLLM for LLM inference
- NVIDIA Dynamo (torch.compile)
- DCGM (Data Center GPU Manager) for GPU monitoring
- GPU persistence mode enabled
- Kernel DKMS support for automatic driver rebuilds

## Prerequisites

- [Packer](https://www.packer.io/downloads) installed (version 1.7.0 or later)
- Cloud provider credentials configured:
  - **GCP**: Service account key or Application Default Credentials
  - **AWS**: AWS credentials via environment variables, shared credentials file, or IAM role
  - **Azure**: Azure CLI authentication or service principal
- Valid cloud project/account with compute API enabled
- Sufficient quotas for GPU instances in your target region/zone

## Quick Start

### 1. Initialize Packer
```bash
packer init .
```
Downloads and installs the required cloud provider plugins.

### 2. Validate Configuration (Optional)
```bash
packer validate --var-file=example.pkrvars.hcl .
```
Validates the syntax and configuration of your templates.

### 3. Build the Image
```bash
packer build --var-file=example.pkrvars.hcl .
```
Builds the GPU-enabled image. The build process takes approximately 20-30 minutes.

**Note:** Packer automatically creates a temporary compute instance, provisions it, creates an image, and then stops and deletes the instance. Only the final image persists.

## Customization

### Cloud Provider Plugin
Configure only the plugin for your cloud provider by updating the `plugins.pkr.hcl` file in your provider directory:
- **GCP**: [gcp/plugins.pkr.hcl](gcp/plugins.pkr.hcl) - Google Cloud plugin
- **AWS**: [aws/plugins.pkr.hcl](aws/plugins.pkr.hcl) - Amazon EC2 plugin
- **Azure**: Configure Azure Compute plugin (adapt from existing templates)

### Machine Type
Select the appropriate GPU-enabled machine type for your cloud provider and update it in your variables file:

**GCP** ([gcp/variable.pkr.hcl](gcp/variable.pkr.hcl)):
- `n1-standard-4` with GPU accelerators
- `a2-highgpu-1g` (A100 GPU)
- `g2-standard-4` (L4 GPU)

**AWS** ([aws/variables.pkr.hcl](aws/variables.pkr.hcl)):
- `p3.2xlarge` (V100 GPU)
- `p4d.24xlarge` (A100 GPU)
- `g5.xlarge` (A10G GPU)

**Azure**:
- `Standard_NC6` (K80 GPU)
- `Standard_NC6s_v3` (V100 GPU)
- `Standard_ND96asr_v4` (A100 GPU)

### GPU Driver Version
The NVIDIA driver version (currently 590.48.01) is specified in [gpu-driver-script.sh](script/gpu-driver-script.sh). Update this version to match your GPU type and requirements:
- Check compatible driver versions at [NVIDIA Driver Downloads](https://www.nvidia.com/en-us/drivers/)
- Ensure the driver version matches your GPU type and CUDA toolkit requirements
- Update lines 5, 6, 9, and 13 in the script with your desired version

## Build Process

The build performs these steps automatically:

1. **System Update** - Updates and upgrades all packages
2. **Reboot** - Applies kernel updates
3. **Build Tools** - Installs DKMS, kernel headers, and build essentials
4. **GPU Drivers** - Installs NVIDIA drivers and CUDA Toolkit ([gpu-driver-script.sh](script/gpu-driver-script.sh))
5. **ML Frameworks** - Installs PyTorch, vLLM, and NVIDIA Dynamo ([ml-frameworks-script.sh](script/ml-frameworks-script.sh))
6. **Performance** - Enables GPU persistence mode ([performance-script.sh](script/performance-script.sh))
7. **Monitoring** - Installs DCGM for GPU monitoring ([monitoring-setup.sh](script/monitoring-setup.sh))

### Key Components Explained

**DKMS (Dynamic Kernel Module Support)**
Automatically rebuilds kernel modules (like NVIDIA drivers) when you update your Linux kernel, preventing driver breakage after system updates.

**Build Essentials**
Compilers (`gcc`, `make`) required for building kernel modules.

**Kernel Headers**
Must match your running kernel version for proper driver compilation.

## Image Management

### GCP

**List your built images:**
```bash
gcloud compute images list --filter="name:gpu-node*"
```

**Delete an image:**
```bash
gcloud compute images delete IMAGE_NAME --project=PROJECT_ID
```

**Check GPU availability in zone:**
```bash
gcloud compute accelerator-types list --filter="zone:europe-west1-c"
```

**List source images:**
```bash
gcloud compute images list --project debian-cloud --filter="family:debian-12"
```

### AWS

**List your AMIs:**
```bash
aws ec2 describe-images --owners self --filters "Name=name,Values=gpu-*"
```

**Delete an AMI:**
```bash
aws ec2 deregister-image --image-id ami-xxxxx
```

**List available GPU instance types:**
```bash
aws ec2 describe-instance-types --filters "Name=instance-type,Values=p*,g*" --query "InstanceTypes[].InstanceType"
```

### Azure

**List your images:**
```bash
az image list --resource-group YOUR_RESOURCE_GROUP
```

**Delete an image:**
```bash
az image delete --resource-group YOUR_RESOURCE_GROUP --name IMAGE_NAME
```

## Project Structure

```
.
├── build.pkr.hcl          # Main build configuration
├── node.pkr.hcl           # Compute node configuration
├── variable.pkr.hcl       # Variable definitions
├── plugins.pkr.hcl        # Plugin configuration
├── local.pkr.hcl          # Local values
├── example.pkrvars.hcl    # Example variables file
├── values.pkrvars.hcl     # Your custom values (gitignored)
└── script/                # Provisioning scripts
    ├── gpu-driver-script.sh        # NVIDIA driver installation
    ├── ml-frameworks-script.sh     # PyTorch, vLLM setup
    ├── performance-script.sh       # GPU performance tuning
    └── monitoring-setup.sh         # DCGM monitoring setup
```

## References

- [Packer Documentation](https://www.packer.io/docs)
- [NVIDIA Driver Downloads](https://www.nvidia.com/en-us/drivers/)
- [DCGM Exporter](https://github.com/NVIDIA/dcgm-exporter) - Prometheus metrics exporter for GPU monitoring
- [AI Dynamo](https://github.com/ai-dynamo/dynamo) - High-throughput distributed inference framework for LLMs
- Cloud Provider Plugin Docs:
  - [GCP Plugin](https://developer.hashicorp.com/packer/integrations/hashicorp/googlecompute)
  - [AWS Plugin](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon)
  - [Azure Plugin](https://developer.hashicorp.com/packer/integrations/hashicorp/azure)

## TODO

- [ ] Add DCGM Prometheus exporter configuration
- [ ] Add automated testing for GPU functionality
- [ ] Add Azure-specific templates
