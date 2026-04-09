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
  policy_assignments_to_modify = {
    ("${var.prefix}-connectivity") = {
      policy_assignments = {
        # Disable the DDoS protection policy assignment as we don't have a DDoS protection plan.
        Enable-DDoS-VNET = {
          creation_enabled = false
        }
      }
    }
    ("${var.prefix}-corp") = {
      policy_assignments = {
        # Disable the private DNS zones policy assignment as we don't have private DNS zones deployed.
        Deploy-Private-DNS-Zones = {
          creation_enabled = false
        }
      }
    }
    ("${var.prefix}-landingzones") = {
      policy_assignments = {
        # Disable the DDoS protection policy assignment as we don't have a DDoS protection plan.
        Enable-DDoS-VNET = {
          creation_enabled = false
        }
      }
    }
  }
}
