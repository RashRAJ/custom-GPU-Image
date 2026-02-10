source "googlecompute" "rtx6000-node" {
  project_id              = var.project_id
  zone                    = var.zone
  source_image_family     = var.image_family
  source_image_project_id = var.image_project_id
  machine_type            = var.machine_type
  ssh_username              = var.ssh_username

  accelerator_type    = var.accelerator_type
  accelerator_count   = 1
  on_host_maintenance = "TERMINATE"

  image_name        = var.image_name
  image_description = "Debian 12 with nvidia-rtx-pro-6000 drivers and health checks"

  tags = ["rtx6000-node"]

}