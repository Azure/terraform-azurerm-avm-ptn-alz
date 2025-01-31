<!-- BEGIN_TF_DOCS -->
# ALZ + Management

This example shows how to deploy the ALZ reference architecture combines with the ALZ management module.

```hcl
provider "alz" {
  library_references = [{
    path = "platform/alz"
    ref  = "2024.10.1"
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

locals {
  automation_account_name      = "aa-${var.random_suffix}"
  location                     = "swedencentral"
  log_analytics_workspace_name = "law-${var.random_suffix}"
  resource_group_name          = "rg-alz-management-${var.random_suffix}"
  uami_name                    = "uami-ama"
}

module "management" {
  source  = "Azure/avm-ptn-alz-management/azurerm"
  version = "0.6.0"

  automation_account_name      = local.automation_account_name
  location                     = local.location
  log_analytics_workspace_name = local.log_analytics_workspace_name
  resource_group_name          = local.resource_group_name
}

module "alz" {
  source             = "../../"
  architecture_name  = "alz"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = local.location
  policy_default_values = {
    ama_change_tracking_data_collection_rule_id = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, local.resource_group_name, "Microsoft.Insights/dataCollectionRules", ["dcr-change-tracking"]) })
    ama_mdfc_sql_data_collection_rule_id        = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, local.resource_group_name, "Microsoft.Insights/dataCollectionRules", ["dcr-defender-sql"]) })
    ama_vm_insights_data_collection_rule_id     = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, local.resource_group_name, "Microsoft.Insights/dataCollectionRules", ["dcr-vm-insights"]) })
    ama_user_assigned_managed_identity_id       = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, local.resource_group_name, "Microsoft.ManagedIdentity/userAssignedIdentities", [local.uami_name]) })
    ama_user_assigned_managed_identity_name     = jsonencode({ value = local.uami_name })
    log_analytics_workspace_id                  = jsonencode({ value = provider::azapi::resource_group_resource_id(data.azapi_client_config.current.subscription_id, local.resource_group_name, "Microsoft.OperationalInsights/workspaces", [local.log_analytics_workspace_name]) })
  }
  dependencies = {
    policy_assignments = [
      module.management.data_collection_rule_ids,
      module.management.resource_id,
      module.management.user_assigned_identity_ids,
    ]
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

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (~> 0.16)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0, >= 2.0.1)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

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

Version: 0.6.0

<!-- END_TF_DOCS -->