terraform {
  required_version = ">= 1.0.0"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = ">= 0.5.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.74.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

provider "alz" {}

provider "azurerm" {
  features {}
}
