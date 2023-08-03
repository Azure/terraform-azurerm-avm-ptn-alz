// Jsondecode the data source
locals {
  alz_policy_definitions_decoded     = { for k, v in data.alz_archetype.this.alz_policy_definitions : k => jsondecode(v) }
  alz_policy_set_definitions_decoded = { for k, v in data.alz_archetype.this.alz_policy_set_definitions : k => jsondecode(v) }
  alz_policy_assignments_decoded     = { for k, v in data.alz_archetype.this.alz_policy_assignments : k => jsondecode(v) }
  alz_role_assignments_decoded       = { for k, v in data.alz_archetype.this.alz_role_assignments : k => jsondecode(v) }
  alz_role_definitions_decoded       = { for k, v in data.alz_archetype.this.alz_role_definitions : k => jsondecode(v) }
}

locals {
  policy_role_assignments_set = toset(flatten([for k, v in data.alz_archetype.this.alz_policy_role_assignments : [
    for rdid in v.role_definition_ids : {
      key                = "${k}-${rdid}"
      role_definition_id = rdid
    }
  ]]))
}
