variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "target_project" { 
  type = string
}

variable "terraform_service_account" {
    type = string
}

