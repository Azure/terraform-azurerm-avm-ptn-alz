# This allows us to get the tenant id
data "azapi_client_config" "current" {}

provider "alz" {
  library_references = [
    {
      path = "platform/alz",
      ref  = "2026.01.3"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

module "alz_architecture" {
  source = "../../"

  architecture_name  = "alz_custom"
  location           = "northeurope"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  enable_telemetry   = var.enable_telemetry

  policy_assignment_non_compliance_message_settings = {
    default_message = "This resource {enforcementMode} be compliant with the assigned policy. Contact the cloud platform team for guidance."
    merge_mode      = "replace"
  }

  policy_assignments_to_modify = {
    ("${var.prefix}-alz") = {
      policy_assignments = {
        Audit-ResourceRGLocation = {
          non_compliance_messages = [
            {
              message = "Resources and resource groups must be deployed to one of the approved Azure regions."
            },
          ]
        }
        Deploy-MDFC-Config-H224 = {
          non_compliance_messages = [
            {
              message = "Microsoft Defender for Cloud must be configured for all subscriptions."
            },
            {
              message                        = "Defender for Servers must be enabled on all subscriptions."
              policy_definition_reference_id = "defenderForVM"
            },
            {
              message                        = "Defender for Storage must be enabled on all storage accounts."
              policy_definition_reference_id = "defenderForStorageAccountsV2"
            },
            {
              message                        = "Defender for SQL must be enabled on all Azure SQL databases."
              policy_definition_reference_id = "defenderForSqlPaas"
            },
          ]
        }
      }
    }
  }
}
