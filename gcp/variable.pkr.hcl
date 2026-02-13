variable "image_name" {
  type        = string
  description = "The name of the resulting image"
}

variable "image_description" {
  type        = string
  description = "Description of the image"
}

variable "project_id" {
  type        = string
  description = "The GCP project ID where the image will be created"
}

variable "image_family" {
  type        = string
  description = "The image family to which the resulting image belongs"
}

variable "image_project_id" {
  type        = list(string)
  description = "The project ID(s) to search for the source image"
}

variable "zone" {
  type        = string
  description = "The GCP zone where the build instance will be created"
}

variable "ssh_username" {
  type        = string
  description = "The SSH username to use for connecting to the instance"
}
variable "machine_type" {
  type        = string
  description = "The machine type to use for the build instance"
}