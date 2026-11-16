variable "cluster_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}


variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer_url" {
  type = string
}

