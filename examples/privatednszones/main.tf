provider "alz" {
  library_references = [{
    path = "platform/alz"
    ref  = "2026.01.3"
  }]
}

data "azapi_client_config" "current" {}

locals {
  location            = "swedencentral"
  resource_group_name = "rg-private-dns-${var.random_suffix}"
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.5.0"

  location         = local.location
  name             = local.resource_group_name
  enable_telemetry = var.enable_telemetry
}

module "private_dns_zones" {
  source  = "Azure/avm-ptn-network-private-link-private-dns-zones/azurerm"
  version = "0.23.3"

  location         = local.location
  parent_id        = module.resource_group.resource_id
  enable_telemetry = var.enable_telemetry
  # Retain the example's existing zone catalog across the dependency upgrade.
  private_link_excluded_zones = [
    "azure_container_apps",
    "azure_ai_services",
    "azure_fabric",
    "azure_cosmos_db_mongo_vcore",
    "azure_managed_redis",
    "azure_event_grid_mqtt",
    "azure_healthcare",
    "azure_managed_prometheus",
    "azure_purview_service",
    "azure_static_web_apps_partitioned",
    "azure_synapse",
    "azure_synapse_sql",
    "azure_synapse_dev",
    "azure_web_pubsub",
  ]
  private_link_private_dns_zones_additional = {
    azure_acr_data = {
      zone_name = "{regionName}.data.privatelink.azurecr.io"
    }
    azure_healthcare_workspaces = {
      zone_name = "privatelink.workspace.azurehealthcareapis.com"
    }
    azure_healthcare_fhir = {
      zone_name = "privatelink.fhir.azurehealthcareapis.com"
    }
    azure_app_service_scm = {
      zone_name = "scm.privatelink.azurewebsites.net"
    }
  }
}

module "alz" {
  source = "../../"

  architecture_name  = "alz"
  location           = local.location
  parent_resource_id = data.azapi_client_config.current.tenant_id
  enable_telemetry   = var.enable_telemetry
  policy_assignments_dependencies = [
    module.private_dns_zones.private_dns_zone_resource_ids,
  ]
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
  policy_default_values = {
    private_dns_zone_subscription_id     = jsonencode({ value = data.azapi_client_config.current.subscription_id })
    private_dns_zone_region              = jsonencode({ value = local.location })
    private_dns_zone_resource_group_name = jsonencode({ value = local.resource_group_name })
  }
}
