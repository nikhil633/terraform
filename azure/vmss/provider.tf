terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 5.9.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  required_version = ">=1.9.0"
}

provider "azurerm" {
  subscription_id = "f626625b-e3b0-4db1-9ede-d461bfe18a56"

  features {
  }
}