# Jsondecode the data source but use known (at plan time) map keys from `alz_archetype_keys`
# and combine with (potentially) known after apply data from the `alz_archetype` data source.
locals {
  alz_policy_definitions_decoded     = { for k in data.alz_archetype_keys.this.alz_policy_definition_keys : k => jsondecode(data.alz_archetype.this.alz_policy_definitions[k]) }
  alz_policy_set_definitions_decoded = { for k in data.alz_archetype_keys.this.alz_policy_set_definition_keys : k => jsondecode(data.alz_archetype.this.alz_policy_set_definitions[k]) }
  alz_policy_assignments_decoded     = { for k in data.alz_archetype_keys.this.alz_policy_assignment_keys : k => jsondecode(data.alz_archetype.this.alz_policy_assignments[k]) }
  alz_role_definitions_decoded       = { for k in data.alz_archetype_keys.this.alz_role_definition_keys : k => jsondecode(data.alz_archetype.this.alz_role_definitions[k]) }
}

// Create a map of role assignment for the scope of the management group
locals {
  policy_role_assignments = data.alz_archetype.this.alz_policy_role_assignments != null ? {
    for pra_key, pra_val in data.alz_archetype.this.alz_policy_role_assignments : pra_key => {
      scope              = pra_val.scope
      role_definition_id = pra_val.role_definition_id
      principal_id       = one(azurerm_management_group_policy_assignment.this[pra_val.assignment_name].identity).principal_id
    }
  } : {}
}

//Non-compliance message constants
locals {
  policy_set_mode                               = "PolicySet"
  non_compliance_message_supported_policy_modes = ["All", "Indexed", local.policy_set_mode]
}


