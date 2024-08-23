terraform {
  required_version = "~> 1.9"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    alz = {
      source  = "azure/alz"
      version = "~> 0.13"
    }
  }
}
