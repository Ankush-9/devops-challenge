variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "The AWS region where resources will be deployed"
}

variable "project_name" {
  type        = string
  default     = "nimbuskart"
  description = "Project identifier for resource tagging"
}

variable "environment" {
  type        = string
  default     = "staging"
  description = "Environment tier (e.g., staging, production)"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for the web tier"
}
