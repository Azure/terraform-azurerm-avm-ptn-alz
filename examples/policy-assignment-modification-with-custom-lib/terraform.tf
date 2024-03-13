terraform {
  required_version = "~> 1.0"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.11"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
  }
}

provider "azurerm" {
  features {}
}
