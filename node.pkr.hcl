source "googlecompute" "gpu-node" {
  project_id              = var.project_id
  zone                    = var.zone
  source_image_family     = var.image_family
  source_image_project_id = var.image_project_id
  ssh_username            = var.ssh_username
  machine_type            = var.machine_type



  image_name        = var.image_name
  image_description = var.image_description

  disk_size           = var.disk_size
  on_host_maintenance = "TERMINATE"

  tags = ["gpu-node"]

}