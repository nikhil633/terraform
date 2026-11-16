variable "enable_irsa" {
  type    = bool
  default = true
}

variable "cluster_name" {
  type = string
}


variable "tags" {
  type    = map(string)
  default = {}
}

# IAM Module Variables



