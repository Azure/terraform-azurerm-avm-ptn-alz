terraform {
  required_version = "~> 1.8"
  required_providers {
    alz = {
      source  = "Azure/alz"
      version = ">= 0.15.3, < 1.0.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0, >= 2.0.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}
