variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ssh_allowed_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Unsafe specification default. Flagged in Deviations section."
}

variable "project_name" {
  type    = string
  default = "nimbuskart"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "owner" {
  type    = string
  default = "engineering"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
