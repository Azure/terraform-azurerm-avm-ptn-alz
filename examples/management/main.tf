provider "alz" {
  library_references = [{
    path = "platform/alz"
    ref  = "2024.07.7"
  }]
}

provider "azurerm" {
  features {}
}

data "azapi_client_config" "current" {}

module "management" {
  source  = "Azure/avm-ptn-alz-management/azurerm"
  version = "0.3.0"

  automation_account_name      = "aa-terraform-slkfglknr"
  location                     = "swedencentral"
  log_analytics_workspace_name = "law-terraform-slkfglknr"
  resource_group_name          = "rg-terraform-slkfglknr"
}

module "alz" {
  source             = "../../"
  architecture_name  = "alz"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = "swedencentral"
  policy_default_values = {
    ama_change_tracking_data_collection_rule_id = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, "rg-terraform-slkfglknr", "Microsoft.Insights/dataCollectionRules", ["dcr-change-tracking"]) })
    ama_mdfc_sql_data_collection_rule_id        = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, "rg-terraform-slkfglknr", "Microsoft.Insights/dataCollectionRules", ["dcr-defender-sql"]) })
    ama_vm_insights_data_collection_rule_id     = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, "rg-terraform-slkfglknr", "Microsoft.Insights/dataCollectionRules", ["dcr-vm-insights"]) })
    ama_user_assigned_managed_identity_id       = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, "rg-terraform-slkfglknr", "Microsoft.ManagedIdentity/userAssignedIdentities", ["uami-ama"]) })
    ama_user_assigned_managed_identity_name     = "uami-ama"
    log_analytics_workspace_id                  = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, "rg-terraform-slkfglknr", "Microsoft.OperationalInsights/workspaces", ["law-terraform-slkfglknr"]) })
  }
  policy_assignments_to_modify = {
    connectivity = {
      policy_assignments = {
        Enable-DDoS-VNET = {
          enforcement_mode = "DoNotEnforce"
        }
      }
    }
  }
}
