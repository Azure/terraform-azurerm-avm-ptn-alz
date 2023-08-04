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
  parent_management_group_id = format("/providers/Microsoft.Management/managementGroups/%s", data.alz_archetype.this.parent_id)
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
  parameters          = try(each.value.properties.parameters, null) != null && try(each.value.properties.parameters, {}) != {} ? jsonencode(each.value.properties.parameters) : null
}

resource "azurerm_policy_set_definition" "this" {
  for_each = local.alz_policy_set_definitions_decoded

  name                = each.key
  display_name        = each.value.properties.displayName
  policy_type         = try(each.value.properties.policyType, "Custom")
  management_group_id = azurerm_management_group.this.id
  metadata            = jsonencode(try(each.value.properties.metadata, {}))
  parameters          = try(each.value.properties.parameters, null) != null && try(each.value.properties.parameters, {}) != {} ? jsonencode(each.value.properties.parameters) : null

  depends_on = [azurerm_policy_definition.this]

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
  parameters           = try(each.value.properties.parameters, null) != null && try(each.value.properties.parameters, {}) != {} ? jsonencode(each.value.properties.parameters) : null
  location             = try(each.value.location, null)

  depends_on = [azurerm_policy_definition.this, azurerm_policy_set_definition.this]

  dynamic "identity" {
    for_each = try(each.value.identity.type, "None") != "None" ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.type == "SystemAssigned" ? null : toset(keys(identity.value.userAssignedIdentities))
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

resource "azurerm_role_assignment" "policy" {
  for_each = local.policy_role_assignments

  principal_id       = try(one(azurerm_management_group_policy_assignment.this[each.value.policy_assignment_name].identity).principal_id, "")
  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id
  description        = "Created for policy assignment ${each.key} at scope ${azurerm_management_group.this.id}"
}

resource "azurerm_role_definition" "this" {
  for_each = local.alz_role_definitions_decoded

  name        = each.key
  description = try(each.value.properties.description, null)
  scope       = azurerm_management_group.this.id
  permissions {
    actions          = try(one(each.value.properties.permissions).actions, [])
    not_actions      = try(one(each.value.properties.permissions).notActions, [])
    data_actions     = try(one(each.value.properties.permissions).dataActions, [])
    not_data_actions = try(one(each.value.properties.permissions).notDataActions, [])
  }
  assignable_scopes = try(each.value.properties.assignableScopes, [])
}

resource "azurerm_role_assignment" "this" {
  for_each             = var.role_assignments
  scope                = azurerm_management_group.this.id
  principal_id         = each.value.principal_id
  role_definition_id   = each.value.role_definition_id != "" ? each.value.role_definition_id : null
  role_definition_name = each.value.role_definition_name != "" ? each.value.role_definition_name : null
  description          = each.value.description
}
