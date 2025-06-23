<!-- BEGIN_TF_DOCS -->
# ALZ + AMBA

This example shows how to deploy the ALZ reference architecture combined with the AMBA module.

```hcl
# This allows us to get the tenant id
data "azapi_client_config" "current" {}

# Include the additional policies and override archetypes
provider "alz" {
  library_overwrite_enabled = true
  library_references = [
    {
      "path" : "platform/alz",
      "ref" : "2025.02.0"
    },
    {
      "path" : "platform/amba",
      "ref" : "2025.05.0"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

provider "azurerm" {
  alias           = "management"
  subscription_id = var.management_subscription_id != "" ? var.management_subscription_id : data.azapi_client_config.current.subscription_id
  features {}
}

locals {
  root_management_group_name = keys(module.alz_architecture.management_group_resource_ids)[0]
}

module "amba_alz" {
  source  = "Azure/avm-ptn-monitoring-amba-alz/azurerm"
  version = "0.1.1"
  providers = {
    azurerm = azurerm.management
  }
  count = var.bring_your_own_user_assigned_managed_identity ? 0 : 1

  location                            = var.location
  root_management_group_name          = local.root_management_group_name
  resource_group_name                 = var.resource_group_name
  user_assigned_managed_identity_name = var.user_assigned_managed_identity_name
}

module "alz_architecture" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.12.0"

  architecture_name  = "alz-amba"
  location           = var.location
  parent_resource_id = data.azapi_client_config.current.tenant_id
  enable_telemetry   = var.enable_telemetry
  policy_default_values = {
    amba_alz_management_subscription_id            = jsonencode({ value = var.management_subscription_id != "" ? var.management_subscription_id : data.azapi_client_config.current.subscription_id })
    amba_alz_resource_group_location               = jsonencode({ value = var.location })
    amba_alz_resource_group_name                   = jsonencode({ value = var.resource_group_name })
    amba_alz_resource_group_tags                   = jsonencode({ value = var.tags })
    amba_alz_user_assigned_managed_identity_name   = jsonencode({ value = var.user_assigned_managed_identity_name })
    amba_alz_byo_user_assigned_managed_identity_id = jsonencode({ value = var.bring_your_own_user_assigned_managed_identity_resource_id })
    amba_alz_disable_tag_name                      = jsonencode({ value = var.amba_disable_tag_name })
    amba_alz_disable_tag_values                    = jsonencode({ value = var.amba_disable_tag_values })
    amba_alz_action_group_email                    = jsonencode({ value = var.action_group_email })
    amba_alz_arm_role_id                           = jsonencode({ value = var.action_group_arm_role_id })
    amba_alz_webhook_service_uri                   = jsonencode({ value = var.webhook_service_uri })
    amba_alz_event_hub_resource_id                 = jsonencode({ value = var.event_hub_resource_id })
    amba_alz_function_resource_id                  = jsonencode({ value = var.function_resource_id })
    amba_alz_function_trigger_url                  = jsonencode({ value = var.function_trigger_uri })
    amba_alz_logicapp_resource_id                  = jsonencode({ value = var.logic_app_resource_id })
    amba_alz_logicapp_callback_url                 = jsonencode({ value = var.logic_app_callback_url })
    amba_alz_byo_alert_processing_rule             = jsonencode({ value = var.bring_your_own_alert_processing_rule_resource_id })
    amba_alz_byo_action_group                      = jsonencode({ value = var.bring_your_own_action_group_resource_id })
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (~> 0.17, >= 0.17.4)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.2)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azapi_client_config.current](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_action_group_arm_role_id"></a> [action\_group\_arm\_role\_id](#input\_action\_group\_arm\_role\_id)

Description: Action group ARM role ID

Type: `list(string)`

Default: `[]`

### <a name="input_action_group_email"></a> [action\_group\_email](#input\_action\_group\_email)

Description: Action group email

Type: `list(string)`

Default: `[]`

### <a name="input_amba_disable_tag_name"></a> [amba\_disable\_tag\_name](#input\_amba\_disable\_tag\_name)

Description: Tag name used to disable monitoring at the resource level.

Type: `string`

Default: `"MonitorDisable"`

### <a name="input_amba_disable_tag_values"></a> [amba\_disable\_tag\_values](#input\_amba\_disable\_tag\_values)

Description: Tag value(s) used to disable monitoring at the resource level.

Type: `list(string)`

Default:

```json
[
  "true",
  "Test",
  "Dev",
  "Sandbox"
]
```

### <a name="input_bring_your_own_action_group_resource_id"></a> [bring\_your\_own\_action\_group\_resource\_id](#input\_bring\_your\_own\_action\_group\_resource\_id)

Description: The resource id of the action group, required if you intend to use an existing action group for monitoring purposes.

Type: `list(string)`

Default: `[]`

### <a name="input_bring_your_own_alert_processing_rule_resource_id"></a> [bring\_your\_own\_alert\_processing\_rule\_resource\_id](#input\_bring\_your\_own\_alert\_processing\_rule\_resource\_id)

Description: The resource id of the alert processing rule, required if you intend to use an existing alert processing rule for monitoring purposes.

Type: `string`

Default: `""`

### <a name="input_bring_your_own_user_assigned_managed_identity"></a> [bring\_your\_own\_user\_assigned\_managed\_identity](#input\_bring\_your\_own\_user\_assigned\_managed\_identity)

Description: Flag to indicate if the user-assigned managed identity is provided by the user.

Type: `bool`

Default: `false`

### <a name="input_bring_your_own_user_assigned_managed_identity_resource_id"></a> [bring\_your\_own\_user\_assigned\_managed\_identity\_resource\_id](#input\_bring\_your\_own\_user\_assigned\_managed\_identity\_resource\_id)

Description: The resource ID of the user-assigned managed identity.

Type: `string`

Default: `""`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: Enable telemetry for the module.

Type: `bool`

Default: `true`

### <a name="input_event_hub_resource_id"></a> [event\_hub\_resource\_id](#input\_event\_hub\_resource\_id)

Description: The resource ID of the event hub.

Type: `list(string)`

Default: `[]`

### <a name="input_function_resource_id"></a> [function\_resource\_id](#input\_function\_resource\_id)

Description: The resource ID of the Azure function.

Type: `string`

Default: `""`

### <a name="input_function_trigger_uri"></a> [function\_trigger\_uri](#input\_function\_trigger\_uri)

Description: The trigger URI of the Azure function.

Type: `string`

Default: `""`

### <a name="input_location"></a> [location](#input\_location)

Description: Location

Type: `string`

Default: `"swedencentral"`

### <a name="input_logic_app_callback_url"></a> [logic\_app\_callback\_url](#input\_logic\_app\_callback\_url)

Description: The callback URL of the logic app.

Type: `string`

Default: `""`

### <a name="input_logic_app_resource_id"></a> [logic\_app\_resource\_id](#input\_logic\_app\_resource\_id)

Description: The resource ID of the logic app.

Type: `string`

Default: `""`

### <a name="input_management_subscription_id"></a> [management\_subscription\_id](#input\_management\_subscription\_id)

Description: Management subscription ID

Type: `string`

Default: `""`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

Default: `"rg-amba-monitoring-001"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default:

```json
{
  "_deployed_by_amba": "True"
}
```

### <a name="input_user_assigned_managed_identity_name"></a> [user\_assigned\_managed\_identity\_name](#input\_user\_assigned\_managed\_identity\_name)

Description: The name of the user-assigned managed identity.

Type: `string`

Default: `"id-amba-prod-001"`

### <a name="input_webhook_service_uri"></a> [webhook\_service\_uri](#input\_webhook\_service\_uri)

Description: The service URI of the webhook.

Type: `list(string)`

Default: `[]`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_alz_architecture"></a> [alz\_architecture](#module\_alz\_architecture)

Source: Azure/avm-ptn-alz/azurerm

Version: 0.12.0

### <a name="module_amba_alz"></a> [amba\_alz](#module\_amba\_alz)

Source: Azure/avm-ptn-monitoring-amba-alz/azurerm

Version: 0.1.1

<!-- END_TF_DOCS -->