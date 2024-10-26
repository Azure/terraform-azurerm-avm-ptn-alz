provider "alz" {
  library_references = [{
    path = "platform/alz"
    ref  = "2024.10.0"
  }]
}

provider "azurerm" {
  features {}
}

variable "random_suffix" {
  type        = string
  default     = "sdjfnbf"
  description = "Change me to something unique"
}

data "azapi_client_config" "current" {}

module "management" {
  source  = "Azure/avm-ptn-alz-management/azurerm"
  version = "0.4.0"

  automation_account_name      = "aa-terraform-${var.random_suffix}"
  location                     = "swedencentral"
  log_analytics_workspace_name = "law-terraform-${var.random_suffix}"
  resource_group_name          = "rg-terraform-${var.random_suffix}"
}

module "alz" {
  source             = "../../"
  architecture_name  = "alz"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = "swedencentral"
  policy_default_values = {
    ama_change_tracking_data_collection_rule_id = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, "rg-terraform-${var.random_suffix}", "Microsoft.Insights/dataCollectionRules", ["dcr-change-tracking"]) })
    ama_mdfc_sql_data_collection_rule_id        = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, "rg-terraform-${var.random_suffix}", "Microsoft.Insights/dataCollectionRules", ["dcr-defender-sql"]) })
    ama_vm_insights_data_collection_rule_id     = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, "rg-terraform-${var.random_suffix}", "Microsoft.Insights/dataCollectionRules", ["dcr-vm-insights"]) })
    ama_user_assigned_managed_identity_id       = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, "rg-terraform-${var.random_suffix}", "Microsoft.ManagedIdentity/userAssignedIdentities", ["uami-ama"]) })
    ama_user_assigned_managed_identity_name     = "uami-ama"
    log_analytics_workspace_id                  = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, "rg-terraform-${var.random_suffix}", "Microsoft.OperationalInsights/workspaces", ["law-terraform-${var.random_suffix}"]) })
  }
  policy_assignments_to_modify = {
    connectivity = {
      policy_assignments = {
        # As we don't have a DDOS protection plan, we need to disable this policy
        # to prevent a modify action from failing.
        Enable-DDoS-VNET = {
          enforcement_mode = "DoNotEnforce"
        }
      }
    }
  }
}
