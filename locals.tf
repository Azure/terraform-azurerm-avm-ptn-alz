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
  policy_role_assignments = {
    for pra in data.alz_archetype.this.alz_policy_role_assignments : "${pra.assignment_name}:${pra.source}:${pra.role_definition_id}" => {
      scope              = pra.scope
      role_definition_id = pra.role_definition_id
      assignment_name    = pra.assignment_name
    }
  }
}
