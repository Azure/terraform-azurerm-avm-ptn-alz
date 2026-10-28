terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    alz = {
      source  = "Azure/alz"
      version = "~> 0.16"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0, >= 2.0.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    modtm = {
      source  = "registry.terraform.io/azure/modtm"
      version = "~> 0.3"
    }
  }
}
