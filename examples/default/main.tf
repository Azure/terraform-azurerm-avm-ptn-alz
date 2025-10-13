# This allows us to get the tenant id
data "azapi_client_config" "current" {}

# Include the additional policies and override archetypes
provider "alz" {
  library_overwrite_enabled = true
  library_references = [
    {
      path = "platform/alz",
      ref  = "2025.09.0"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

module "alz_architecture" {
  source = "../../"

  architecture_name  = "alz"
  location           = "northeurope"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  enable_telemetry   = var.enable_telemetry
}
