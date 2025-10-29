# OpenTofu support is experimental and subject to change.
# We do not test with OpenTofu in our CI/CD pipelines,
# so please use at your own risk.
# Please do raise issues, but we cannot guarantee timely fixes.
terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.20"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
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
