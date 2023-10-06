terraform {
  required_version = ">= 1.0.0"
  required_providers {
    alz = {
      source = "azure/alz"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "alz" {}

provider "azurerm" {
  features {}
}
