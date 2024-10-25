<!-- BEGIN_TF_DOCS -->
# ALZ + Management

This example shows how to deploy the ALZ reference architecture combines with the ALZ management module.

```hcl
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
  version = "0.3.0"

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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.8)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (>= 0.15.2, < 1.0.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0, >= 2.0.1)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.100)

## Resources

The following resources are used by this module:

- [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_random_suffix"></a> [random\_suffix](#input\_random\_suffix)

Description: Change me to something unique

Type: `string`

Default: `"sdjfnbf"`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_alz"></a> [alz](#module\_alz)

Source: ../../

Version:

### <a name="module_management"></a> [management](#module\_management)

Source: Azure/avm-ptn-alz-management/azurerm

Version: 0.3.0

<!-- END_TF_DOCS -->