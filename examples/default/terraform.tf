terraform {
  required_version = "~> 1.6"
  required_providers {
    alz = {
      source  = "azure/azapi"
      version = "~> 1.14"
    }
  }
}

provider "azurerm" {
  features {}
}
