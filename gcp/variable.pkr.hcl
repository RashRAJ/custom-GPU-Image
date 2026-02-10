variable "image_name" {
  type = string
}

variable "image_description" {
  type = string
}

variable "project_id" {
  type = string
}
variable "image_family" {
  type = string
}
variable "image_project_id" {
  type = list(string)
}
variable "machine_type" {
  type = string
}
variable "zone" {
  type = string
}
variable "accelerator_type" {
  type = string
}


variable "ssh_username" {
  type = string
}