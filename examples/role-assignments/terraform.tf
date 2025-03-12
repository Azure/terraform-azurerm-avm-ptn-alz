terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.17"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0, >= 2.0.1"
    }
  }
}
