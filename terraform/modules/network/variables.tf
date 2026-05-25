variable "region" {
  type        = string
  description = "Target deployment AWS region"
}

variable "tags" {
  type        = map(string)
  description = "Global mandatory attribution tags"
}
