# This allows us to get the tenant id
data "azapi_client_config" "current" {}

provider "alz" {
  library_references = [
    {
      path = "platform/alz",
      ref  = "2026.04.2"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]

  # Optional settings for non-compliance messages at the provider level
  non_compliance_message_substitution_settings = {
    enforcement_mode_placeholder = "{enforcementMode}" # If you want a different placeholder, however, this may affect policies in the library that uses this placeholder.
    enforced_replacement         = "must"              # The word to replace the placeholder with when the policy is enforced
    not_enforced_replacement     = "should"            # The word to replace the placeholder with when the policy is not enforced
  }
}

module "alz_architecture" {
  source = "../../"

  architecture_name  = "alz_custom"
  location           = "northeurope"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  enable_telemetry   = var.enable_telemetry
  policy_assignment_non_compliance_message_settings = {
    default_message = "This resource {enforcementMode} be compliant with the assigned policy. Contact the cloud platform team for guidance."
    # merge_mode      = "prefer_existing"
  }

  policy_assignments_to_modify = {
    ("${var.prefix}-alz") = {
      policy_assignments = {
        Deploy-MDFC-Config-H224 = {
          non_compliance_messages = [
            {
              message = "Microsoft Defender for Cloud {enforcementMode} be configured for all subscriptions."
            },
            {
              message                        = "Defender for Servers {enforcementMode} be enabled on all subscriptions."
              policy_definition_reference_id = "defenderForVM"
            },
            {
              message                        = "Defender for Storage {enforcementMode} be enabled on all storage accounts."
              policy_definition_reference_id = "defenderForStorageAccountsV2"
            },
            {
              message                        = "Defender for SQL {enforcementMode} be enabled on all Azure SQL databases."
              policy_definition_reference_id = "defenderForSqlPaas"
            },
          ]
        }
      }
    }
  }
}
