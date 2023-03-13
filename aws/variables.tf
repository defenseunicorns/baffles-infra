variable "region" {
  description = "The AWS region to deploy into"
  type        = string
}

variable "account" {
  description = "The AWS account to deploy into"
  type        = string
}

variable "aws_profile" {
  description = "The AWS profile to use for deployment"
  type        = string
}

variable "aws_admin_usernames" {
  description = "A list of one or more AWS usernames with authorized access to KMS and EKS resources"
  type        = list(string)
}

variable "name" {
  description = "Project name"
  type        = string
}

