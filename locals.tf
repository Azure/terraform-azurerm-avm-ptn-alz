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
  policy_assignment_non_compliance_fallback_message = var.policy_assignment_non_compliance_message_settings.fallback_message == null ? "" : var.policy_assignment_non_compliance_message_settings.fallback_message
  policy_assignment_non_compliance_messages = {
    for k, v in local.policy_assignments : k => {
      nonComplianceMessages = length(try(v.assignment.properties.nonComplianceMessages, [])) == 0 && (!var.policy_assignment_non_compliance_message_settings.fallback_message_enabled || contains(var.policy_assignment_non_compliance_message_settings.fallback_message_unsupported_assignments, v.assignment.name)) ? null : [{
        message = replace(try(v.assignment.properties.nonComplianceMessages[0].message, var.policy_assignment_non_compliance_message_settings.fallback_message), var.policy_assignment_non_compliance_message_settings.enforecement_mode_placeholder, (lookup(v.assignment.properties, "enforcementMode", "Default") == "Default" ? var.policy_assignment_non_compliance_message_settings.enforced_replacement : var.policy_assignment_non_compliance_message_settings.non_enforced_replacement))
      }]
  } }
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
  policy_assignments_final = {
    for k, v in local.policy_assignments : k => {
      mg         = v.mg
      assignment = merge(v.assignment, local.policy_assignments_properties_final[k])
    }
  }
  policy_assignments_properties_final = {
    for k, v in local.policy_assignments : k => {
      properties = merge(v.assignment.properties, local.policy_assignment_non_compliance_messages[k])
    }
  }
}

locals {
  policy_role_assignments = data.alz_architecture.this.policy_role_assignments != null ? {
    for pra in data.alz_architecture.this.policy_role_assignments : uuidv5("url", "${pra.policy_assignment_name}${pra.scope}${pra.management_group_id}${pra.role_definition_id}") => {
      principal_id       = lookup(local.policy_assignment_identities, "${pra.management_group_id}/${pra.policy_assignment_name}", { principal_id = null }).principal_id
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
  tenant_root_group_resource_id             = "${local.management_group_resource_provider_prefix}${data.azapi_client_config.hierarchy_settings.tenant_id}"
}

locals {
  policy_assignment_identities = {
    for k, v in azapi_resource.policy_assignments : k => try(v.identity[0], null)
  }
}
