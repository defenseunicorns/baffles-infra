variable "project" {}

variable "credentials_file" {}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-b"
}

variable "name" {
  default = "terraform"
}

variable "service_account" {
  default = ""
}

variable "os_family" {
  default = "redhat"
}

variable "agent_nodes" {
  default = 1
}

variable "ssh_user" {
  default = ""
}

variable "disk_size" {
  default = "70"
  description = "Size of the attached disk on the GCP instances."
  
}