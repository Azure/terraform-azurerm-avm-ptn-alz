terraform {
  required_version = "~> 1.8"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.16"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
