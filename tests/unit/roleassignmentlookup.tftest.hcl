provider "alz" {
  library_references = [{
    custom_url = "./tests/unit/testdata/roleassignmentlookup"
  }]
  library_fetch_dependencies                  = false
  role_definitions_use_supplied_names_enabled = true
  skip_provider_registration                  = true
  use_cli                                     = true
  use_msi                                     = false
  use_oidc                                    = false
}

mock_provider "azapi" {
  mock_data "azapi_resource_list" {
    override_during = plan

    defaults = {
      output = {
        results = [
          {
            role_name = "Security-Operations"
            id        = "/providers/Microsoft.Authorization/roleDefinitions/ce58096d-b508-5d2c-ab60-fcd02e554406"
          },
          {
            role_name = "Storage Blob Data Contributor"
            id        = "/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
          },
          {
            role_name = "Ancestor role"
            id        = "/providers/Microsoft.Authorization/roleDefinitions/55555555-5555-4555-8555-555555555555"
          },
          {
            role_name = "External custom"
            id        = "/providers/Microsoft.Authorization/roleDefinitions/66666666-6666-4666-8666-666666666666"
          },
          {
            role_name = "case-sensitive role"
            id        = "/providers/Microsoft.Authorization/roleDefinitions/88888888-8888-4888-8888-888888888888"
          },
          {
            role_name = "Assignable elsewhere"
            id        = "/providers/Microsoft.Authorization/roleDefinitions/99999999-9999-4999-8999-999999999999"
          }
        ]
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

override_resource {
  target          = azapi_resource.role_definitions["test/Security-Operations"]
  override_during = plan
  values = {
    id       = "/providers/Microsoft.Management/managementGroups/test/providers/Microsoft.Authorization/roleDefinitions/ce58096d-b508-5d2c-ab60-fcd02e554406"
    location = null
  }
}

variables {
  architecture_name  = "test"
  enable_telemetry   = false
  location           = "swedencentral"
  parent_resource_id = "tenant"
  management_group_role_assignments = {
    custom = {
      management_group_name                  = "test"
      role_definition_id_or_name             = "Security-Operations"
      principal_id                           = "00000000-0000-0000-0000-000000000001"
      principal_type                         = "ServicePrincipal"
      description                            = "Owned custom-role lookup regression."
      skip_service_principal_aad_check       = true
      condition                              = "((ActionMatches{'Microsoft.Authorization/roleAssignments/write'}))"
      condition_version                      = "2.0"
      delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test"
    }
  }
}

run "deterministic_owned_apply" {
  command = apply

  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }

  assert {
    condition     = azapi_resource.management_group_role_assignments["custom"].name == "809aac92-825b-5f76-b559-8ffc236769f6"
    error_message = "Owned custom roles must retain the legacy Interfaces 0.5.0 principal-plus-canonical-role-ID UUIDv5."
  }

  assert {
    condition = jsonencode(azapi_resource.management_group_role_assignments["custom"].body.properties) == jsonencode({
      principalId                        = "00000000-0000-0000-0000-000000000001"
      roleDefinitionId                   = "/providers/Microsoft.Authorization/roleDefinitions/ce58096d-b508-5d2c-ab60-fcd02e554406"
      conditionVersion                   = "2.0"
      condition                          = "((ActionMatches{'Microsoft.Authorization/roleAssignments/write'}))"
      description                        = "Owned custom-role lookup regression."
      principalType                      = "ServicePrincipal"
      delegatedManagedIdentityResourceId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test"
    })
    error_message = "The canonical custom-role ID and every existing body field must reach the assignment unchanged."
  }

  assert {
    condition     = toset(keys(azapi_resource.management_group_role_assignments)) == toset(["custom"]) && toset(keys(module.avm_interfaces["custom"].role_assignments_azapi)) == toset(["this"])
    error_message = "Owned-role resolution must not change the root resource or helper instance keys."
  }

  assert {
    condition     = output.role_definition_resource_ids["test/Security-Operations"] == "/providers/Microsoft.Management/managementGroups/test/providers/Microsoft.Authorization/roleDefinitions/ce58096d-b508-5d2c-ab60-fcd02e554406"
    error_message = "The public role-definition output must remain the scoped resource ID, not the canonical assignment-body ID."
  }
}

run "deterministic_owned_refresh_without_list_entry" {
  command = plan

  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }

  override_data {
    target          = module.avm_interfaces["custom"].data.azapi_resource_list.role_definitions[0]
    override_during = plan
    values = {
      output = { results = [] }
    }
  }

  assert {
    condition     = azapi_resource.management_group_role_assignments["custom"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/ce58096d-b508-5d2c-ab60-fcd02e554406" && azapi_resource.management_group_role_assignments["custom"].name == "809aac92-825b-5f76-b559-8ffc236769f6"
    error_message = "A refreshed lookup missing the owned role must not change its canonical body ID or legacy deterministic assignment name."
  }

  assert {
    condition     = jsonencode(azapi_resource.management_group_role_assignments["custom"].body) == jsonencode(module.avm_interfaces["custom"].role_assignments_azapi.this.body) && toset(keys(azapi_resource.management_group_role_assignments)) == toset(["custom"])
    error_message = "Refresh must retain the helper's complete body and the existing assignment address."
  }

  assert {
    condition     = output.role_definition_resource_ids["test/Security-Operations"] == azapi_resource.role_definitions["test/Security-Operations"].id && output.role_definition_resource_ids["test/Security-Operations"] != azapi_resource.management_group_role_assignments["custom"].body.properties.roleDefinitionId
    error_message = "Refresh must not rewrite the scoped public role-definition resource ID."
  }
}

run "random_owned_apply" {
  command = apply

  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }

  variables {
    role_assignment_name_use_random_uuid = true
  }

  assert {
    condition     = azapi_resource.management_group_role_assignments["custom"].name == "11111111-1111-4111-8111-111111111111" && azapi_resource.management_group_role_assignments["custom"].name == module.avm_interfaces["custom"].role_assignments_azapi.this.name
    error_message = "Random mode must retain the existing helper UUID rather than creating a new root-owned naming resource."
  }

  assert {
    condition     = azapi_resource.management_group_role_assignments["custom"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/ce58096d-b508-5d2c-ab60-fcd02e554406" && jsonencode(azapi_resource.management_group_role_assignments["custom"].body) == jsonencode(module.avm_interfaces["custom"].role_assignments_azapi.this.body)
    error_message = "Random naming must not alter canonical custom-role resolution or body propagation."
  }
}

run "random_owned_refresh_without_list_entry" {
  command = plan

  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }

  variables {
    role_assignment_name_use_random_uuid = true
  }

  override_data {
    target          = module.avm_interfaces["custom"].data.azapi_resource_list.role_definitions[0]
    override_during = plan
    values = {
      output = { results = [] }
    }
  }

  assert {
    condition     = azapi_resource.management_group_role_assignments["custom"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/ce58096d-b508-5d2c-ab60-fcd02e554406" && azapi_resource.management_group_role_assignments["custom"].name == "11111111-1111-4111-8111-111111111111"
    error_message = "The owned canonical ID and existing random assignment UUID must survive a refreshed lookup missing the custom role."
  }

  assert {
    condition     = toset(keys(azapi_resource.management_group_role_assignments)) == toset(["custom"]) && toset(keys(module.avm_interfaces["custom"].role_assignments_azapi)) == toset(["this"]) && jsonencode(azapi_resource.management_group_role_assignments["custom"].body) == jsonencode(module.avm_interfaces["custom"].role_assignments_azapi.this.body)
    error_message = "Random refresh must preserve the complete body and both existing instance keys."
  }
}

run "owned_scope_casing_override" {
  command = apply

  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }

  variables {
    parent_id_overrides = {
      role_definitions = {
        "test/Security-Operations" = "/providers/Microsoft.Management/managementgroups"
      }
    }
  }

  override_data {
    target          = module.avm_interfaces["custom"].data.azapi_resource_list.role_definitions[0]
    override_during = plan
    values = {
      output = { results = [] }
    }
  }

  assert {
    condition     = azapi_resource.role_definitions["test/Security-Operations"].parent_id == "/providers/Microsoft.Management/managementgroups/test" && azapi_resource.management_group_role_assignments["custom"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/ce58096d-b508-5d2c-ab60-fcd02e554406"
    error_message = "A supported parent-ID casing override must be retained while matching the same ARM management-group scope."
  }
}

run "other_lookup_contracts" {
  command = apply

  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }

  variables {
    management_group_role_assignments = {
      builtin = {
        management_group_name      = "test"
        role_definition_id_or_name = "Storage Blob Data Contributor"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
      external = {
        management_group_name      = "test"
        role_definition_id_or_name = "External custom"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
      inherited = {
        management_group_name      = "test"
        role_definition_id_or_name = "Ancestor role"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
      explicit_id = {
        management_group_name      = "test"
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/77777777-7777-4777-8777-777777777777"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
      case_sensitive = {
        management_group_name      = "test"
        role_definition_id_or_name = "case-sensitive role"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
      restricted = {
        management_group_name      = "test"
        role_definition_id_or_name = "Assignable elsewhere"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
      sibling = {
        management_group_name      = "elsewhere"
        role_definition_id_or_name = "Security-Operations"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
  }

  override_data {
    target          = module.avm_interfaces["sibling"].data.azapi_resource_list.role_definitions[0]
    override_during = plan
    values = {
      output = {
        results = [{
          role_name = "Security-Operations"
          id        = "/providers/Microsoft.Authorization/roleDefinitions/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
        }]
      }
    }
  }

  assert {
    condition = alltrue([
      for ids in values(local.role_assignment_owned_role_definition_ids) : length(ids) == 0
    ])
    error_message = "Builtin, external, inherited, explicit-ID, case-mismatched, unassignable and sibling-scope inputs must remain on the existing utility lookup path."
  }

  assert {
    condition = {
      for key, assignment in azapi_resource.management_group_role_assignments : key => assignment.body.properties.roleDefinitionId
      } == {
      builtin        = "/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
      external       = "/providers/Microsoft.Authorization/roleDefinitions/66666666-6666-4666-8666-666666666666"
      inherited      = "/providers/Microsoft.Authorization/roleDefinitions/55555555-5555-4555-8555-555555555555"
      explicit_id    = "/providers/Microsoft.Authorization/roleDefinitions/77777777-7777-4777-8777-777777777777"
      case_sensitive = "/providers/Microsoft.Authorization/roleDefinitions/88888888-8888-4888-8888-888888888888"
      restricted     = "/providers/Microsoft.Authorization/roleDefinitions/99999999-9999-4999-8999-999999999999"
      sibling        = "/providers/Microsoft.Authorization/roleDefinitions/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
    }
    error_message = "Every unaffected input must keep the actual Interfaces lookup/fallback result rather than guessing an owned role by display name."
  }

  assert {
    condition     = azapi_resource.management_group_role_assignments["builtin"].name == "4334a07d-2e16-50c2-a0db-1c609ecd0787" && toset(keys(azapi_resource.management_group_role_assignments)) == toset(keys(var.management_group_role_assignments))
    error_message = "Builtin legacy GUIDs and arbitrary assignment resource keys must remain unchanged."
  }
}

run "lookup_disabled_explicit_id" {
  command = apply

  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }

  variables {
    role_assignment_definition_lookup_enabled = false
    management_group_role_assignments = {
      custom = {
        management_group_name      = "test"
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/ce58096d-b508-5d2c-ab60-fcd02e554406"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
  }

  assert {
    condition     = length(local.role_assignment_owned_role_definition_ids["custom"]) == 0 && azapi_resource.management_group_role_assignments["custom"].body.properties.roleDefinitionId == var.management_group_role_assignments["custom"].role_definition_id_or_name && azapi_resource.management_group_role_assignments["custom"].name == "809aac92-825b-5f76-b559-8ffc236769f6"
    error_message = "Disabling lookup must preserve a supplied canonical ID and its existing deterministic GUID without owned-role resolution."
  }
}

run "lookup_disabled_does_not_resolve_names" {
  command = plan

  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }

  variables {
    role_assignment_definition_lookup_enabled = false
  }

  assert {
    condition     = length(local.role_assignment_owned_role_definition_ids["custom"]) == 0 && azapi_resource.management_group_role_assignments["custom"].body.properties.roleDefinitionId == "Security-Operations"
    error_message = "Disabling definition lookup must not silently resolve a supplied display name."
  }
}

run "ambiguous_owned_name_is_rejected" {
  command = plan

  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }

  variables {
    architecture_name = "ambiguous"
  }

  expect_failures = [azapi_resource.management_group_role_assignments["custom"]]
}
