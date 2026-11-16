variable "location" {
  type    = string
  default = "Central India"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project_name" {
  type    = string
  default = "staticwebsite"
}

variable "frontdoor_private_link_location" {
  description = "Azure region supporting Front Door Private Link"
  type        = string
  default     = "Central India"
}

variable "replication_type" {
  description = "Storage replication"
  type        = string
  default     = "ZRS"
}