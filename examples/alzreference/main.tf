terraform {
  required_version = ">= 1.0.0"
  required_providers {
    alz = {
      source = "azure/alz"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "alz" {}

provider "azurerm" {
  features {}
}

resource "random_pet" "this" {}

module "alz_management" {
  source  = "Azure/alz-management/azurerm"
  version = "0.1.4"

  automation_account_name      = "aa-${random_pet.this.id}"
  location                     = local.default_location
  log_analytics_workspace_name = "law-${random_pet.this.id}"
  resource_group_name          = "rg-${random_pet.this.id}"
}

// These locals help keep the code DRY
locals {
  default_location                   = "eastus2"
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

// This allows us to get the tenant id
data "azurerm_client_config" "current" {}

// This creates the ALZ root management group
module "alz_root" {
  source                             = "../../"
  id                                 = "alz-root"
  display_name                       = "alz-root"
  parent_id                          = data.azurerm_client_config.current.tenant_id
  base_archetype                     = "root"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = local.default_log_analytics_workspace_id
}

// This creates the ALZ landing-zones management group
module "alz_landing_zones" {
  source                             = "../../"
  id                                 = "alz-landing-zones"
  display_name                       = "alz-landing-zones"
  parent_id                          = module.alz_root.management_group_name
  base_archetype                     = "landing_zones"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = local.default_log_analytics_workspace_id
}
