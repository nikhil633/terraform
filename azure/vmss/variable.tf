variable "rg" {
  type = string
  description = "rg name"
  default = "my-rg"
}

variable "location" {
  type = string
  description = "location"
  default = "CentralIndia"
}

variable "vnet" {
  type = string
  description = "vnet-name"
  default = "my-vnet"
}

variable "nsg_rules" {
  description = "Network Security Group inbound security rules"

  type = map(object({
    priority                   = number
    destination_port_range     = string
    source_address_prefix      = string
  }))

  default = {
    http = {
      priority               = 100
      destination_port_range = "80"
      source_address_prefix  = "*"
    }

    https = {
      priority               = 101
      destination_port_range = "443"
      source_address_prefix  = "*"
    }

    ssh = {
      priority               = 102
      destination_port_range = "22"
      source_address_prefix  = "*"
    }
  }
}


variable "subnet" {
  type = string
  description = "subnet-name"
  default = "subnet"
}

variable "public_ip" {
  type = string
  description = "public ip name"
  default = "public_ip"
}

variable "lb_name" {
  type = string
  description = "lb name"
  default = "lb"
}

