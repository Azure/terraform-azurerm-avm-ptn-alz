locals {
  management_groups = { for v in data.alz_architecture.this.management_groups : v.id => {
    id           = v.id
    level        = v.level
    exists       = v.exists
    display_name = v.display_name
    parent_id    = v.parent_id
  } }
  management_groups_level_0 = { for k, v in local.management_groups : k => v if v.level == 0 && !v.exists }
  management_groups_level_1 = { for k, v in local.management_groups : k => v if v.level == 1 && !v.exists }
  management_groups_level_2 = { for k, v in local.management_groups : k => v if v.level == 2 && !v.exists }
  management_groups_level_3 = { for k, v in local.management_groups : k => v if v.level == 3 && !v.exists }
  management_groups_level_4 = { for k, v in local.management_groups : k => v if v.level == 4 && !v.exists }
  management_groups_level_5 = { for k, v in local.management_groups : k => v if v.level == 5 && !v.exists }
  management_groups_level_6 = { for k, v in local.management_groups : k => v if v.level == 6 && !v.exists }
}

locals {
  policy_definitions = {
    for pdval in flatten([
      for mg in data.alz_architecture.this.management_groups : [
        for pdname, pd in mg.policy_definitions : {
          key        = pdname
          definition = jsondecode(pd)
          mg         = mg.id
        }
      ]
  ]) : "${pdval.mg}/${pdval.key}" => pdval }
}

locals {
  policy_set_definitions = {
    for psdval in flatten([
      for mg in data.alz_architecture.this.management_groups : [
        for psdname, psd in mg.policy_set_definitions : {
          key            = psdname
          set_definition = jsondecode(psd)
          mg             = mg.id
        }
      ]
  ]) : "${psdval.mg}/${psdval.key}" => psdval }
}

locals {
  policy_assignments = {
    for paval in flatten([
      for mg in data.alz_architecture.this.management_groups : [
        for paname, pa in mg.policy_assignments : {
          key        = paname
          assignment = jsondecode(pa)
          mg         = mg.id
        }
      ]
  ]) : "${paval.mg}/${paval.key}" => paval }
}

locals {
  policy_role_assignments = data.alz_architecture.this.policy_role_assignments != null ? {
    for pra in data.alz_architecture.this.policy_role_assignments : uuidv5("url", "${pra.policy_assignment_name}${pra.scope}${pra.management_group_id}${pra.role_definition_id}") => {
      principal_id       = module.policy_assignment["${pra.management_group_id}/${pra.policy_assignment_name}"].identity.principal_id
      role_definition_id = startswith(lower(pra.scope), "/subscriptions") ? "/subscriptions/${split("/", pra.scope)[2]}${pra.role_definition_id}" : pra.role_definition_id
      scope              = pra.scope
    } if !strcontains(pra.scope, "00000000-0000-0000-0000-000000000000")
  } : {}
}

locals {
  role_definitions = {
    for rdval in flatten([
      for mg in data.alz_architecture.this.management_groups : [
        for rdname, rd in mg.role_definitions : {
          key             = rdname
          role_definition = jsondecode(rd)
          mg              = mg.id
        }
      ]
    ]) : "${rdval.mg}/${rdval.key}" => rdval
  }
}

# Hierarchy settings locals
locals {
  management_group_resource_provider_prefix = "/providers/Microsoft.Management/managementGroups/"
  tenant_root_group_resource_id             = "${local.management_group_resource_provider_prefix}${data.azapi_client_config.hierarchysettings.tenant_id}"
}
