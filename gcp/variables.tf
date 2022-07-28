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

variable "agent_nums" {
  default = 1
}

variable "ssh_user" {
  default = ""
}
