terraform {
  required_version = "~> 1.6"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.12, >= 0.12.5"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.14"
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
