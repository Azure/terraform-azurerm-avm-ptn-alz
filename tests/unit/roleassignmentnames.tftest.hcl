mock_provider "alz" {}

mock_provider "azapi" {
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          role_name = "Storage Blob Data Contributor"
          id        = "/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
        }]
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "11111111-1111-4111-8111-111111111111"
    }
  }
}

mock_provider "time" {}

variables {
  architecture_name  = "test"
  enable_telemetry   = false
  location           = "swedencentral"
  parent_resource_id = "test"
  management_group_role_assignments = {
    rbac = {
      management_group_name      = "test"
      role_definition_id_or_name = "Storage Blob Data Contributor"
      principal_id               = "00000000-0000-0000-0000-000000000001"
      principal_type             = "ServicePrincipal"
      description                = "Role assignment naming regression."
    }
  }
}

run "legacy_deterministic_default" {
  command = apply

  assert {
    condition     = !var.role_assignment_name_use_random_uuid && azapi_resource.management_group_role_assignments["rbac"].name == "4334a07d-2e16-50c2-a0db-1c609ecd0787"
    error_message = "The default must preserve the exact Interfaces 0.5.0 URL-namespace UUIDv5 of principal ID concatenated with the resolved role definition resource ID."
  }

  assert {
    condition     = toset(keys(azapi_resource.management_group_role_assignments)) == toset(["rbac"]) && toset(keys(module.avm_interfaces["rbac"].role_assignments_azapi)) == toset(["this"])
    error_message = "The parent resource instance key and the utility role-assignment key must remain unchanged."
  }

  assert {
    condition = jsonencode(azapi_resource.management_group_role_assignments["rbac"].body.properties) == jsonencode({
      principalId                        = "00000000-0000-0000-0000-000000000001"
      roleDefinitionId                   = "/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
      conditionVersion                   = null
      condition                          = null
      description                        = "Role assignment naming regression."
      principalType                      = "ServicePrincipal"
      delegatedManagedIdentityResourceId = null
    })
    error_message = "Every consumed role-assignment body field must retain the legacy output contract."
  }
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}

run "legacy_random_enabled" {
  command = apply

  variables {
    role_assignment_name_use_random_uuid = true
  }

  assert {
    condition     = azapi_resource.management_group_role_assignments["rbac"].name == "11111111-1111-4111-8111-111111111111" && azapi_resource.management_group_role_assignments["rbac"].name == module.avm_interfaces["rbac"].role_assignments_azapi.this.name
    error_message = "Random naming must continue to consume the utility's existing random_uuid.role_assignment_name[this] result."
  }
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}

run "legacy_deterministic_restored" {
  command = apply

  variables {
    role_assignment_name_use_random_uuid = false
  }

  assert {
    condition     = azapi_resource.management_group_role_assignments["rbac"].name == "4334a07d-2e16-50c2-a0db-1c609ecd0787"
    error_message = "Disabling random naming must restore the original deterministic GUID without changing the resource instance key."
  }
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}
