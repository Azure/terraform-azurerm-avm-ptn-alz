terraform {
  required_version = ">= 1.0.0"
  required_providers {
    alz = {
      source = "azure/alz"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "alz" {}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "law_rg" {
  name     = "rg-law"
  location = "eastus2"
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-alz"
  location            = azurerm_resource_group.law_rg.location
  resource_group_name = azurerm_resource_group.law_rg.name
}

// These locals help keep the code DRY
locals {
  default_location                   = "eastus2"
  default_log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
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
