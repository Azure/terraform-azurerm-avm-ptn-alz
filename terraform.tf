terraform {
  required_version = "~> 1.8"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = ">= 0.15.1, < 1.0.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "2.0.0-beta"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
