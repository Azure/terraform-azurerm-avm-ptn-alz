terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0, >= 2.0.1"
    }
    alz = {
      source  = "Azure/alz"
      version = ">= 0.15.2, < 1.0.0"
    }
  }
}
