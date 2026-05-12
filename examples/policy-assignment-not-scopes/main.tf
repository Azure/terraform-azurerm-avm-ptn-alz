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
}

module "alz_architecture" {
  source = "../../"

  architecture_name  = "alz_custom"
  location           = "northeurope"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  enable_telemetry   = var.enable_telemetry
  policy_assignments_to_modify = {
    ("${var.prefix}-platform") = {
      policy_assignments = {
        Enforce-ASR = {
          not_scopes = [
            "/subscriptions/${data.azapi_client_config.current.subscription_id}",
          ]
        }
      }
    }
  }
}
