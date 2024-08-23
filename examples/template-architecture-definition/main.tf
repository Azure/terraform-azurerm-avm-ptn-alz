# This allows us to get the tenant id
data "azapi_client_config" "current" {}

provider "alz" {
  library_references = [
    {
      path = "platform/alz"
      ref  = "2024.07.3"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

module "alz_architecture" {
  source             = "../../"
  architecture_name  = "custom"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = "northeurope"
}
