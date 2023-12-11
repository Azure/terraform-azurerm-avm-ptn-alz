terraform {
  required_providers {
    alz = {
      source = "azure/alz"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.79.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
}

provider "azurerm" {
  features {}
}
