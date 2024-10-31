terraform {
  required_version = "~> 1.8"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.16"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0, >= 2.0.1"
    }
  }
}
