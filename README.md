

# **GPU Image Builder**  
High‑performance NVIDIA GPU images for training, inference, and multi‑node workloads  
*(HashiCorp Packer + CUDA + PyTorch + vLLM + DeepSpeed)*


A modular, production‑grade system for building GPU‑accelerated VM images using **HashiCorp Packer**.  
Designed for **training**, **inference**, and **multi‑node distributed** workloads on NVIDIA GPUs.

The build is fully layered:

```
┌──────────────────────────────────────────────┐
│ Training‑Optimized Layer (DeepSpeed, DALI)   │
├──────────────────────────────────────────────┤
│ Inference‑Optimized Layer (vLLM, TensorRT)   │
├──────────────────────────────────────────────┤
│ Framework Layer (PyTorch, Triton, HF stack)  │
├──────────────────────────────────────────────┤
│ Base Layer (Drivers, CUDA, DCGM, NUMA tuning)│
└──────────────────────────────────────────────┘
```

Each layer is optional and can be enabled independently.

---

## **Features**

### **GPU Runtime**
- NVIDIA driver + CUDA Toolkit  
- cuDNN, cuBLAS, NCCL  
- NVIDIA Container Toolkit  
- Fabric Manager (NVSwitch/HGX)  
- DCGM + DCGM Exporter  

### **Performance Tuning**
- NUMA awareness + CPU pinning tools  
- Hugepages  
- Swap disabled  
- CPU governor set to performance  
- irqbalance disabled  
- Docker default runtime set to NVIDIA  

### **ML Frameworks**
- PyTorch (CUDA‑enabled)  
- Triton, xFormers, Flash‑Attention  
- HuggingFace Transformers + Accelerate  
- cuPy, cuPyNumeric, NVIDIA Warp  

### **Inference‑Optimized**
- vLLM  
- TensorRT‑LLM  
- Quantization (bitsandbytes, AWQ, GPTQ)  
- Tokenizer acceleration  

### **Training‑Optimized**
- DeepSpeed  
- Megatron‑LM dependencies  
- NVIDIA DALI  
- UCX + RDMA + NCCL tuning  
- Multi‑node SHARP support  

---

## **Repository Structure**

```
.
├── build.pkr.hcl                           # Main build configuration
├── variable.pkr.hcl                        # Variable definitions
├── plugins.pkr.hcl                         # Packer plugin configuration
├── local.pkr.hcl                           # Local build settings
├── node.pkr.hcl                            # Node-specific configuration
├── example.pkrvars.hcl                     # Example variable values
├── script/
│   ├── base.sh                             # Base layer setup
│   ├── framework_setup.sh                  # ML framework installation
│   ├── performance-script.sh               # Performance tuning
│   ├── monitoring-setup.sh                 # Monitoring setup (DCGM)
│   ├── training_optimized_script.sh        # Training-specific setup
│   ├── inference_optimized_setup.sh        # Inference-specific setup
│   └── multinode_performance_tuning.sh     # Multi-node optimizations
└── README.md
```

---

## **Prerequisites**

- HashiCorp Packer  
- A GPU‑enabled VM base image (GCP, AWS, Azure, or on‑prem)  
- Ubuntu 22.04 LTS recommended  
- NVIDIA GPUs (Ampere, Hopper, Blackwell, or newer)  

---

## **Quick Start**

### **1. Validate the template**

```bash
packer validate -var-file=example.pkrvars.hcl build.pkr.hcl
```

### **2. Build a general‑purpose GPU image**

```bash
packer build -var-file=example.pkrvars.hcl build.pkr.hcl
```

This includes:

- Base layer
- Framework layer
- Performance tuning
- Monitoring

### **3. Build a training‑optimized image**
ensure you set 'enable_training  = true'

```bash
packer build -var-file=example.pkrvars.hcl  build.pkr.hcl
```

Adds:

- DeepSpeed
- DALI
- UCX + RDMA
- NCCL tuning
- Multi‑node optimizations

### **4. Build an inference‑optimized image**
ensure you set enable_inference = true in your example.pkrvars.hcl
```bash
packer build -var-file=example.pkrvars.hcl build.pkr.hcl
```

Adds:

- vLLM
- TensorRT‑LLM
- Quantization libraries  

---

## **Layer Details**

| Layer | Components | Purpose |
|-------|-----------|---------|
| **Base Layer** | • NVIDIA driver<br>• CUDA Toolkit<br>• DCGM + Fabric Manager<br>• NUMA tools<br>• Hugepages<br>• CPU governor tuning<br>• Docker NVIDIA runtime | Foundation layer that changes rarely and provides core GPU infrastructure |
| **Framework Layer** | • Python + uv<br>• PyTorch (CUDA)<br>• Triton<br>• xFormers<br>• Flash‑Attention<br>• HuggingFace stack<br>• cuPy / cuPyNumeric<br>• NVIDIA Warp | Shared layer for both training and inference with core ML frameworks |
| **Inference‑Optimized Layer** | • vLLM<br>• TensorRT‑LLM<br>• bitsandbytes, AWQ, GPTQ<br>• Tokenizer acceleration | Optimized for low latency and fast model loading |
| **Training‑Optimized Layer** | • DeepSpeed<br>• Megatron‑LM deps<br>• NVIDIA DALI<br>• UCX + RDMA<br>• NCCL tuning<br>• SHARP (if supported) | Optimized for high throughput and multi‑node scaling |

---

## **Customization**

You can customize:

- CUDA version  
- PyTorch version  
- Whether to enable training or inference layers  
- Whether to enable multi‑node tuning  

Modify `build.pkr.hcl` or pass variables at build time.

---

## **Why This Project Exists**

Modern GPU workloads require more than installing CUDA.  
Performance depends on:

- NUMA locality  
- CPU affinity  
- Hugepages  
- RDMA/UCX/NCCL tuning  
- Data pipeline acceleration  
- Framework‑specific optimizations  

This project packages all of that into a reproducible, open‑source build system.

---

## **License**

MIT License.  
Contributions are welcome.

