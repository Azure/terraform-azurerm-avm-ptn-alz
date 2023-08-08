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
    for pra in toset(
      flatten(
        [
          for k, v in data.alz_archetype.this.alz_policy_role_assignments : [
            for rdid in v.role_definition_ids : [
              for scope in v.scopes :
              {
                key                    = "${k}:${rdid}:${scope}"
                policy_assignment_name = k
                role_definition_id     = rdid
                scope                  = scope
              }
            ]
          ]
        ]
      )
      ) : pra.key => {
      policy_assignment_name = pra.policy_assignment_name
      role_definition_id     = pra.role_definition_id
      scope                  = pra.scope
      policy_assignment_name = pra.policy_assignment_name
    }
  }
}
