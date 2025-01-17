provider "alz" {
  library_references = [{
    path = "platform/alz"
    ref  = "2024.11.0"
  }]
}

provider "azurerm" {
  features {}
}

variable "random_suffix" {
  type        = string
  default     = "fgcsnm"
  description = "Change me to something unique"
}

data "azapi_client_config" "current" {}

locals {
  location            = "swedencentral"
  resource_group_name = "rg-private-dns-${var.random_suffix}"
}

module "private_dns_zones" {
  source              = "Azure/avm-ptn-network-private-link-private-dns-zones/azurerm"
  version             = "0.7.0"
  location            = local.location
  resource_group_name = local.resource_group_name
}

module "alz" {
  source             = "../../"
  architecture_name  = "alz"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = local.location
  policy_default_values = {
    private_dns_zone_subscription_id     = jsonencode({ value = data.azapi_client_config.current.subscription_id })
    private_dns_zone_region              = jsonencode({ value = local.location })
    private_dns_zone_resource_group_name = jsonencode({ value = local.resource_group_name })
  }
  dependencies = {
    policy_assignments = [
      module.private_dns_zones.private_dns_zone_resource_ids,
    ]
  }
  policy_assignments_to_modify = {
    connectivity = {
      policy_assignments = {
        # As we don't have a DDOS protection plan, we need to disable this policy
        # to prevent a modify action from failing.
        Enable-DDoS-VNET = {
          enforcement_mode = "DoNotEnforce"
        }
      }
    }
  }
}
