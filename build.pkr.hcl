build {
  name    = ${var.image_name}
  sources = ["source.googlecompute.gpu-node"]

  provisioner "shell" {
    inline = [
      "set -e",
      "sudo apt update",
      "sudo apt -y dist-upgrade"
    ]
  }
# Base OS upgrade and reboot to ensure clean state for driver installation
  provisioner "shell" {
    expect_disconnect = true
    inline            = ["sudo reboot"]
  }
# Kernel headers + build tools (required before drivers)

  provisioner "shell" {
    pause_before = "90s"
    inline = [
      "sudo apt update",
      "sudo apt install -y dkms",
      "sudo apt install -y linux-headers-$(uname -r)",
      "sudo apt install -y build-essential"
    ]
  }
#Base Layer (Drivers, CUDA, DCGM, NUMA tuning)
  provisioner "shell" {
    script = "script/base.sh"
    environment_vars = [
      "CUDA_VERSION=${var.cuda_version}"
    ]
  }
#Framework Layer (Python, PyTorch, Triton, HF)
  provisioner "shell" {
    script = "script/framework_setup.sh"
    environment_vars = [
      "PYTORCH_VERSION=${var.pytorch_version}"
    ]
  }

  # Performance Layer (GPU persistence, OS tuning)
  provisioner "shell" {
    script = "script/performance-script.sh"
  }
  # Monitoring Layer (DCGM setup, Prometheus node exporter)
  provisioner "shell" {
    script = "script/monitoring-setup.sh"
  }

  # Workload-specific optimizations (controlled via variables)
  provisioner "shell" {
    script = "script/training_optimized_setup.sh"
    when   = var.enable_training ? "always" : "never"
  }
  # Inference Layer (vLLM, TensorRT-LLM)
  provisioner "shell" {
    script = "script/inference_optimized_setup.sh"
    when   = var.enable_inference ? "always" : "never"
  }
  #Multi-node Layer (NCCL/UCX tuning, RDMA)
  provisioner "shell" {
    script = "script/multinode_performance_tuning.sh"
    when   = var.enable_multinode ? "always" : "never"
  }

  post-processor "shell-local" {
    inline = [
      "echo '=== Image Build Complete ==='",
      "echo 'Image ID: ${build.ID}'", # Local info only
      "date"
    ]
  }
}