terraform {
  required_version = ">= 1.12, < 2.0"

  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.21"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
