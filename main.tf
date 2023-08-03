data "alz_archetype" "this" {
  id = var.id
  defaults = {
    location                   = var.default_location
    log_analytics_workspace_id = var.default_log_analytics_workspace_id
  }
  display_name   = var.display_name
  base_archetype = var.base_archetype
  parent_id      = var.parent_id
}

resource "azurerm_management_group" "this" {
  name                       = data.alz_archetype.this.id
  display_name               = data.alz_archetype.this.display_name
  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${data.alz_archetype.this.parent_id}"
}

resource "azurerm_policy_definition" "this" {
  for_each = local.alz_policy_definitions_decoded

  name                = each.key
  description         = try(each.value.properties.description, "")
  display_name        = try(each.value.properties.displayName, "")
  policy_type         = try(each.value.properties.policyType, "Custom")
  mode                = each.value.properties.mode
  management_group_id = azurerm_management_group.this.id
  metadata            = jsonencode(try(each.value.properties.metadata, {}))
  policy_rule         = jsonencode(try(each.value.properties.policyRule, {}))
  parameters          = jsonencode(try(each.value.properties.parameters, {}))
}

resource "azurerm_policy_set_definition" "this" {
  for_each = local.alz_policy_set_definitions_decoded

  name                = each.key
  display_name        = each.value.properties.displayName
  policy_type         = try(each.value.properties.policyType, "Custom")
  management_group_id = azurerm_management_group.this.id
  metadata            = jsonencode(try(each.value.properties.metadata, {}))
  parameters          = jsonencode(try(each.value.properties.parameters, {}))

  dynamic "policy_definition_reference" {
    for_each = try(each.value.properties.policyDefinitions, [])

    content {
      policy_definition_id = policy_definition_reference.value.policyDefinitionId
      parameter_values     = try(jsonencode(policy_definition_reference.value.parameters), jsonencode({}))
      policy_group_names   = try(policy_definition_reference.value.groupNames, [])
      reference_id         = try(policy_definition_reference.value.policyDefinitionReferenceId, "")
    }
  }

  dynamic "policy_definition_group" {
    for_each = try(each.value.properties.policyDefinitionGroups, [])

    content {
      name                            = policy_definition_group.value.name
      display_name                    = try(policy_definition_group.value.displayName, "")
      description                     = try(policy_definition_group.value.description, "")
      category                        = try(policy_definition_group.value.category, "")
      additional_metadata_resource_id = try(policy_definition_group.value.additionalMetadataId, "")
    }
  }
}

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = local.alz_policy_assignments_decoded

  name                 = each.key
  management_group_id  = azurerm_management_group.this.id
  policy_definition_id = each.value.properties.policyDefinitionId
  description          = try(each.value.properties.description, "")
  enforce              = try(each.value.properties.enforce, "Default") == "Default" ? true : false
  metadata             = jsonencode(try(each.value.properties.metadata, {}))

  dynamic "identity" {
    for_each = try(each.value.properties.identity, [])

    content {
      type         = identity.value.type
      identity_ids = identity.value.type == "UserAssigned" ? one(keys(identity.value.userAssignedIdentities)) : null
    }
  }

  dynamic "non_compliance_message" {
    for_each = try(each.value.properties.nonComplianceMessages, [])

    content {
      content                        = non_compliance_message.value.message
      policy_definition_reference_id = try(non_compliance_message.value.policyDefinitionReferenceId, null)
    }
  }

  dynamic "resource_selectors" {
    for_each = try(each.value.properties.resourceSelectors, [])

    content {
      name = resource_selectors.value.name

      dynamic "selectors" {
        for_each = try(resource_selectors.value.selectors, [])

        content {
          kind   = selectors.value.kind
          in     = try(selectors.value.in, null)
          not_in = try(selectors.value.notIn, null)
        }
      }
    }
  }

  dynamic "overrides" {
    for_each = try(each.value.properties.overrides, [])

    content {
      value = overrides.value.value

      dynamic "selectors" {
        for_each = try(overrides.value.selectors, [])

        content {
          in     = try(selectors.value.in, null)
          not_in = try(selectors.value.notIn, null)
        }
      }
    }
  }
}

# resource "azurerm_role_assignment" "policy" {
#   for_each     =
#   principal_id = azurerm_management_group_policy_assignment.this.identity[0].principal_id
# }
