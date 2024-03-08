terraform {
  required_version = ">= 1.0.0"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.10"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
