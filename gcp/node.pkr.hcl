source "googlecompute" "gpu-node" {
  project_id              = var.project_id
  zone                    = var.zone
  source_image_family     = var.image_family
  source_image_project_id = var.image_project_id
  ssh_username            = var.ssh_username
  machine_type            = var.machine_type



  image_name        = var.image_name
  image_description = "Debian 12 GPU Optimized with drivers and health checks"

  tags = ["gpu-node"]

}