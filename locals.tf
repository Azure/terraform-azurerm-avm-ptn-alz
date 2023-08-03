// Jsondecode the data source
locals {
  alz_policy_definitions_decoded     = { for k, v in data.alz_archetype.this.alz_policy_definitions : k => jsondecode(v) }
  alz_policy_set_definitions_decoded = { for k, v in data.alz_archetype.this.alz_policy_set_definitions : k => jsondecode(v) }
  alz_policy_assignments_decoded     = { for k, v in data.alz_archetype.this.alz_policy_assignments : k => jsondecode(v) }
  alz_role_assignments_decoded       = { for k, v in data.alz_archetype.this.alz_role_assignments : k => jsondecode(v) }
  alz_role_definitions_decoded       = { for k, v in data.alz_archetype.this.alz_role_definitions : k => jsondecode(v) }
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
                policy_assignment_name = k
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
