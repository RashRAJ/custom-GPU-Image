
# **GPU Image Builder**
High‑performance NVIDIA GPU images for training, inference, and multi‑node workloads

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Packer](https://img.shields.io/badge/Packer-1.9+-blueviolet?logo=packer&logoColor=white)
![GCP](https://img.shields.io/badge/GCP-Google_Compute-4285F4?logo=googlecloud&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-EC2_(optional)-FF9900?logo=amazonaws&logoColor=white)
![CUDA](https://img.shields.io/badge/CUDA-13.1-76B900?logo=nvidia&logoColor=white)
![Driver](https://img.shields.io/badge/NVIDIA_Driver-590.48-76B900?logo=nvidia&logoColor=white)
![PyTorch](https://img.shields.io/badge/PyTorch-2.10-EE4C2C?logo=pytorch&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_LTS-E95420?logo=ubuntu&logoColor=white)
![vLLM](https://img.shields.io/badge/vLLM-Inference-blue)
![DeepSpeed](https://img.shields.io/badge/DeepSpeed-Training-orange)
![HuggingFace](https://img.shields.io/badge/HuggingFace-Transformers-yellow?logo=huggingface&logoColor=white)


A modular, production-grade system for building GPU-accelerated VM images on **Google Cloud** using **HashiCorp Packer**, with an option to use the **AWS plugin** for EC2 builds.
Designed for **training**, **inference**, and **multi-node distributed** workloads on NVIDIA GPUs.

---

## Why This Project Exists

Every time you spin up a new GPU node, you end up doing the same thing: installing drivers, CUDA, PyTorch, tuning sysctl knobs, fighting dependency conflicts — burning hours and cloud credits before any real work starts.

This project was born out of that frustration. Instead of repeating the same setup ritual on every node, it bakes everything into a single, reproducible image. Boot it up and you're ready to train or serve immediately.

It also became a way for me to explore and document the NVIDIA ecosystem — driver versions, DCGM, Fabric Manager, UCX/RDMA, NCCL tuning, and all the performance tweaks that are scattered across dozens of docs but rarely packaged together.

---

## Architecture

The build is fully layered — each layer is optional and can be enabled independently:

```
┌──────────────────────────────────────────────────┐
│  Multi-node Layer (NCCL, RDMA, SHARP)            │  enable_multinode = true
├──────────────────────────────────────────────────┤
│  Training Layer (PyTorch, DeepSpeed, DALI, UCX)  │  enable_training = true
├──────────────────────────────────────────────────┤
│  Inference Layer (PyTorch, vLLM, TensorRT-LLM)   │  enable_inference = true
├──────────────────────────────────────────────────┤
│  Monitoring Layer (DCGM 4, Fabric Manager)        │  always included
├──────────────────────────────────────────────────┤
│  Performance Layer (NUMA, hugepages, governors)   │  always included
├──────────────────────────────────────────────────┤
│  Framework Layer (Python, uv, /opt/ml venv)      │  always included
├──────────────────────────────────────────────────┤
│  Base Layer (Driver 590, CUDA 13.1, CTK)         │  always included
└──────────────────────────────────────────────────┘
```

---

## Features

### Base Layer
- NVIDIA driver 590+ (open kernel modules, compute-only)
- CUDA Toolkit 13.1
- NVIDIA Container Toolkit (Docker + containerd)
- DCGM + Fabric Manager (NVSwitch/HGX)
- NVIDIA Persistence Daemon
- Swap disabled, hugepages, CPU governor tuning, NUMA tools

### Framework Layer
- Python 3 + [uv](https://github.com/astral-sh/uv) package manager
- Shared ML virtual environment at `/opt/ml`

### Performance Tuning
- GPU persistence mode (`nvidia-smi -pm 1`)
- NUMA awareness + CPU pinning (numactl, hwloc)
- Hugepages (2048 pages)
- irqbalance disabled
- Swap disabled, `vm.swappiness=0`

### Monitoring
- DCGM 4 (matched to CUDA major version)
- DCGM Exporter for Prometheus
- Fabric Manager for NVLink/NVSwitch GPUs

### Training Layer (`enable_training = true`)
- PyTorch (CUDA-enabled) + Transformers + Accelerate
- DeepSpeed
- Megatron-LM dependencies (ninja, einops)
- NVIDIA DALI
- UCX + RDMA + InfiniBand
- Network sysctl tuning (BBR, large buffers)

### Inference Layer (`enable_inference = true`)
- PyTorch (CUDA-enabled) + Transformers + Accelerate
- Triton, xFormers, Flash-Attention
- cuPy, cupynumeric, NVIDIA Warp
- vLLM
- TensorRT-LLM
- Quantization (bitsandbytes, AutoAWQ, Optimum)

---

## Repository Structure

```
.
├── build.pkr.hcl                        # Build pipeline — provisioner ordering
├── node.pkr.hcl                         # GCP source definition (googlecompute)
├── variable.pkr.hcl                     # Variable definitions with defaults
├── local.pkr.hcl                        # Local values
├── plugins.pkr.hcl                      # Packer plugin requirements
├── example.pkrvars.hcl.example          # Example variable values (copy and customize)
├── script/
│   ├── base.sh                          # NVIDIA driver, CUDA, CTK, DCGM, system tuning
│   ├── framework_setup.sh               # Python, uv, /opt/ml venv
│   ├── performance-script.sh            # GPU persistence, NUMA, hugepages, irqbalance
│   ├── monitoring-setup.sh              # DCGM 4, Fabric Manager, DCGM Exporter
│   ├── training_optimized_script.sh     # PyTorch + DeepSpeed + DALI + UCX/RDMA
│   ├── inference_optimized_setup.sh     # PyTorch + vLLM + TensorRT-LLM + quantization
│   └── multinode_performance_tuning.sh  # Multi-node networking optimizations
└── README.md
```

---

## Prerequisites

- [HashiCorp Packer](https://www.packer.io/) >= 1.9
- [Google Compute Packer plugin](https://github.com/hashicorp/packer-plugin-googlecompute) (installed via `packer init`)
- Optionally, the [AWS Packer plugin](https://github.com/hashicorp/packer-plugin-amazon) can be used for EC2 builds by adding an `amazon-ebs` source to `node.pkr.hcl`
- GCP project with Compute Engine API enabled (or AWS account with EC2 access)
- GCP authentication (`gcloud auth application-default login`) or AWS credentials
- Ubuntu 22.04 LTS base image
- NVIDIA GPU instance type (e.g. A100, H100, L4 on GCP; p4d, p5 on AWS)

---

## Quick Start

### 1. Initialize Packer plugins

```bash
packer init .
```

### 2. Configure variables

```bash
cp example.pkrvars.hcl.example my.pkrvars.hcl
# Edit my.pkrvars.hcl with your GCP project, zone, machine type, etc.
```

### 3. Validate the template

```bash
packer validate -var-file=my.pkrvars.hcl .
```

### 4. Build a general-purpose GPU image

```bash
packer build -var-file=my.pkrvars.hcl .
```

This builds all always-included layers: base, framework, performance, and monitoring.

### 5. Build a training-optimized image

Set `enable_training = true` in your `.pkrvars.hcl` file, then:

```bash
packer build -var-file=my.pkrvars.hcl .
```

Adds PyTorch, DeepSpeed, DALI, UCX/RDMA, and NCCL tuning.

### 6. Build an inference-optimized image

Set `enable_inference = true` in your `.pkrvars.hcl` file, then:

```bash
packer build -var-file=my.pkrvars.hcl .
```

Adds PyTorch, vLLM, TensorRT-LLM, and quantization libraries.

### 7. Build with multi-node optimizations

Set `enable_multinode = true` in your `.pkrvars.hcl` file for NCCL/RDMA/SHARP tuning.

---

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `image_name` | string | — | Name of the resulting image |
| `image_description` | string | — | Description of the image |
| `project_id` | string | — | GCP project ID |
| `image_family` | string | — | Source image family (e.g. `ubuntu-2204-lts`) |
| `image_project_id` | list(string) | — | Project(s) to search for the source image |
| `zone` | string | — | GCP zone for the build instance |
| `machine_type` | string | — | GCP machine type (e.g. `a2-highgpu-1g`) |
| `ssh_username` | string | — | SSH username for Packer |
| `disk_size` | number | `100` | Boot disk size in GB |
| `driver_version` | string | `590.48.01` | NVIDIA latest driver version |
| `cuda_version` | string | `13.1` | CUDA toolkit version |
| `pytorch_version` | string | `2.5.1` | PyTorch version |
| `enable_training` | bool | `false` | Enable training layer |
| `enable_inference` | bool | `false` | Enable inference layer |
| `enable_multinode` | bool | `false` | Enable multi-node optimizations |

---

## Layer Details

| Layer | Script | Components | When |
|-------|--------|------------|------|
| **Base** | `base.sh` | NVIDIA driver (open kernel modules), CUDA toolkit, Container Toolkit, DCGM, Persistence Daemon, swap/hugepages/NUMA tuning | Always |
| **Framework** | `framework_setup.sh` | Python 3, uv, `/opt/ml` shared venv | Always |
| **Performance** | `performance-script.sh` | GPU persistence mode, swap off, hugepages, NUMA/hwloc tools, irqbalance disabled | Always |
| **Monitoring** | `monitoring-setup.sh` | DCGM 4 (CUDA-version matched), DCGM Exporter, Fabric Manager | Always |
| **Training** | `training_optimized_script.sh` | PyTorch, Transformers, DeepSpeed, DALI, UCX/RDMA, network tuning | `enable_training` |
| **Inference** | `inference_optimized_setup.sh` | PyTorch, Triton, xFormers, Flash-Attention, vLLM, TensorRT-LLM, quantization | `enable_inference` |
| **Multi-node** | `multinode_performance_tuning.sh` | NCCL tuning, RDMA, SHARP | `enable_multinode` |

---

## Using AWS Instead of GCP

The provisioning scripts are cloud-agnostic. To build on AWS instead of GCP:

1. Add the AWS plugin to `plugins.pkr.hcl`:
   ```hcl
   amazon = {
     source  = "github.com/hashicorp/amazon"
     version = "~> 1"
   }
   ```

2. Add an `amazon-ebs` source in `node.pkr.hcl` targeting a GPU instance type (e.g. `p4d.24xlarge`, `p5.48xlarge`)

3. Update the `sources` list in `build.pkr.hcl` to reference the new source

All shell scripts under `script/` will work without modification.

---



## References

- [AI Systems Performance Engineering — O'Reilly](https://www.oreilly.com/library/view/ai-systems-performance/9798341627772/)
- [CUDA Installation Guide for Linux — NVIDIA](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/#ubuntu)
- [Tesla Driver 590.48.01 Release Notes — NVIDIA](https://docs.nvidia.com/datacenter/tesla/tesla-release-notes-590-48-01/index.html)

---

## License

MIT License. Contributions are welcome.

