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
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }
}
