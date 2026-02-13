build {
  sources = ["source.googlecompute.rtx6000-node"]

  provisioner "shell" {
    inline = [
      "set -e",  
      "sudo apt update",
      "sudo apt -y dist-upgrade"
    ]  
  }
  
  provisioner "shell" {
    expect_disconnect = true
    inline = ["sudo reboot"]  
  }

  provisioner "shell" {
    pause_before = "90s"
    inline = [
      "sudo apt update",
      "sudo apt install -y dkms",
      "sudo apt install -y linux-headers-$(uname -r)",
      "sudo apt install -y build-essential"
    ]  
  }

  provisioner "shell" {
    script = "script/gpu-driver-script.sh"
  }

  # GPU Persistence Mode
  provisioner "shell" {
    script = "script/performace-script.sh"

  }

  provisioner "shell" {
    script = "script/monitoring-setup.sh"
  }


post-processor "shell-local" {
  inline = [
    "echo '=== Image Build Complete ==='",
    "echo 'Image ID: ${build.ID}'",  # Local info only
    "date"
  ]
}
}