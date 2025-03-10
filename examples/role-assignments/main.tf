# This allows us to get the tenant id
data "azapi_client_config" "current" {}

# Include the additional policies and override archetypes
provider "alz" {
  library_references = [
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

module "alz_architecture" {
  source             = "../../"
  architecture_name  = "test"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = "northeurope"
  management_group_role_assignments = {
    test1 = {
      principal_type             = var.principal_type
      role_definition_id_or_name = "Storage Blob Data Contributor"
      principal_id               = data.azapi_client_config.current.object_id
      management_group_name      = "${var.prefix}test1"
    }
    test2 = {
      principal_type             = var.principal_type
      role_definition_id_or_name = "Security-Operations (${var.prefix}test2)"
      principal_id               = data.azapi_client_config.current.object_id
      management_group_name      = "${var.prefix}test2"
    }
  }
}
