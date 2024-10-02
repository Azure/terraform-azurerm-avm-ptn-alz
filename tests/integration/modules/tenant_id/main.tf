terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "2.0.0-beta"
    }
  }
}

data "azapi_client_config" "current" {}

output "tenant_id" {
  value = data.azapi_client_config.current.tenant_id
}
