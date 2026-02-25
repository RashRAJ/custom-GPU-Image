build {
  sources = ["source.googlecompute.gpu-node"]

  provisioner "shell" {
    inline = [
      "set -e",
      "sudo apt update",
      "sudo apt -y dist-upgrade"
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    inline            = ["sudo reboot"]
  }

  # Base: NVIDIA drivers, CUDA, DCGM
  provisioner "shell" {
    pause_before = "60s"
    script       = "script/base.sh"
    max_retries  = 2
    environment_vars = [
      "DRIVER_VERSION=${var.driver_version}",
      "CUDA_VERSION=${var.cuda_version}"
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    inline            = ["sudo reboot"]
  }

  # Framework: Python, uv, /opt/ml venv
  provisioner "shell" {
    pause_before = "60s"
    script       = "script/framework_setup.sh"
  }

  provisioner "shell" {
    script = "script/performance-script.sh"
  }

  provisioner "shell" {
    pause_before = "60s"
    script       = "script/monitoring-setup.sh"
  }

  # Optional: Training workload (PyTorch + training stack)
  provisioner "shell" {
    script = "script/training_optimized_script.sh"
    environment_vars = [
      "ENABLE_TRAINING=${var.enable_training}",
      "PYTORCH_VERSION=${var.pytorch_version}"
    ]
  }

  # Optional: Inference workload (PyTorch + inference stack)
  provisioner "shell" {
    script = "script/inference_optimized_setup.sh"
    environment_vars = [
      "ENABLE_INFERENCE=${var.enable_inference}",
      "PYTORCH_VERSION=${var.pytorch_version}"
    ]
  }

  # Optional: Multi-node networking tuning
  provisioner "shell" {
    script = "script/multinode_performance_tuning.sh"
    environment_vars = ["ENABLE_MULTINODE=${var.enable_multinode}"]
  }

  post-processor "shell-local" {
    inline = [
      "echo '=== Image Build Complete ==='",
      "echo 'Image ID: ${build.ID}'",
      "date"
    ]
  }
}
