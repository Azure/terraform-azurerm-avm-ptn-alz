mock_provider "alz" {}

mock_provider "azapi" {
  override_during = plan

  mock_data "azapi_client_config" {
    defaults = {
      tenant_id                = "00000000-0000-0000-0000-000000000001"
      subscription_id          = "00000000-0000-0000-0000-000000000002"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000002"
    }
  }

  mock_data "azapi_resource_action" {
    defaults = {
      output = {
        value = [{
          displayName = "Sweden Central"
          name        = "swedencentral"
          metadata = {
            geography      = "Sweden"
            geographyGroup = "Europe"
            regionCategory = "Recommended"
            regionType     = "Physical"
          }
        }]
      }
    }
  }
}

mock_provider "random" {}
mock_provider "time" {}

override_module {
  target          = module.alz
  override_during = plan
  outputs         = {}
}

override_resource {
  target          = module.resource_group.azapi_resource.this[0]
  override_during = plan
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-private-dns-test"
  }
}

run "preserves_private_dns_example_contract" {
  command = plan

  module {
    source = "./examples/privatednszones"
  }

  variables {
    enable_telemetry = false
    random_suffix    = "test"
  }

  assert {
    condition = (
      module.resource_group.name == "rg-private-dns-test" &&
      module.private_dns_zones.resource_group_resource_id == module.resource_group.resource_id
    )
    error_message = "Private DNS must use the example's resource group without changing its name."
  }

  assert {
    condition     = length(module.private_dns_zones.private_dns_zone_resource_ids) == 75
    error_message = "The upgrade must preserve the example's 75-zone catalog."
  }

  assert {
    condition = (
      module.private_dns_zones.private_link_private_dns_zones_map["azure_acr_data"].zone_name == "swedencentral.data.privatelink.azurecr.io" &&
      module.private_dns_zones.private_link_private_dns_zones_map["azure_healthcare_workspaces"].zone_name == "privatelink.workspace.azurehealthcareapis.com" &&
      module.private_dns_zones.private_link_private_dns_zones_map["azure_healthcare_fhir"].zone_name == "privatelink.fhir.azurehealthcareapis.com" &&
      module.private_dns_zones.private_link_private_dns_zones_map["azure_app_service_scm"].zone_name == "scm.privatelink.azurewebsites.net" &&
      module.private_dns_zones.private_link_private_dns_zones_map["azure_backup"].zone_name == "privatelink.sdc.backup.windowsazure.com"
    )
    error_message = "Legacy zones and region substitutions must survive the dependency upgrade."
  }
}
