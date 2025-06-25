terraform {
  required_version = "~> 1.9"

  required_providers {
    alz = {
      source  = "Azure/alz"
      version = "~> 0.17, >= 0.17.4"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
