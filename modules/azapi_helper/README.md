<!-- BEGIN_TF_DOCS -->
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/Azure/terraform-azurerm-avm-ptn-alz/badge)](https://scorecard.dev/viewer/?uri=github.com/Azure/terraform-azurerm-avm-ptn-alz)

# ALZ Terraform Module (azapi\_helper)

> ⚠️ **\_Warning\_** ⚠️ This module is still in development but is ready for initial testing and feedback via [GitHub Issues](https://github.com/Azure/terraform-azurerm-avm-ptn-alz/issues).

This module is a wrapper for `azapi_resource`, adding convenience features.
As we are using AzAPI, we do not have the full Terraform schema options available for detecting attribute changes that require recreating the resource.

This submodule is therefore used to enable the `terraform_data` method for `replace_triggered_by`: <https://developer.hashicorp.com/terraform/language/resources/terraform-data#example-usage-data-for-replace_triggered_by>.
This allows us to replace the resource when certain key attributes change.

You can use the `var.replace_triggered_by` attribute to specify any data, that when changed, will trigger a replacement of the resource.

```hcl
resource "azapi_resource" "this" {
  type                    = var.type
  body                    = var.body
  ignore_missing_property = var.ignore_missing_property
  location                = var.location
  name                    = var.name
  parent_id               = var.parent_id
  response_export_values  = var.response_export_values

  dynamic "identity" {
    for_each = var.identity == null ? [] : var.identity.type != "None" ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }

  lifecycle {
    ignore_changes = [
      body.properties.metadata.createdBy,
      body.properties.metadata.createdOn,
      body.properties.metadata.updatedBy,
      body.properties.metadata.updatedOn,
    ]
    replace_triggered_by = [
      terraform_data.replace_trigger
    ]
  }
}

resource "terraform_data" "replace_trigger" {
  input = var.replace_triggered_by
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 1.14)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 1.14)

- <a name="provider_terraform"></a> [terraform](#provider\_terraform)

## Resources

The following resources are used by this module:

- [azapi_resource.this](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [terraform_data.replace_trigger](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_body"></a> [body](#input\_body)

Description: The body object of the resource.

Type: `any`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of resource.

Type: `string`

### <a name="input_parent_id"></a> [parent\_id](#input\_parent\_id)

Description: The parent ID of the resource.

Type: `string`

### <a name="input_type"></a> [type](#input\_type)

Description: The type and API version of the resource.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_identity"></a> [identity](#input\_identity)

Description:   Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `type` - Either: `SystemAssigned`, `SystemAssigned, UserAssigned`, or `UserAssigned`.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    type         = string
    identity_ids = optional(set(string), [])
  })
```

Default: `null`

### <a name="input_ignore_missing_property"></a> [ignore\_missing\_property](#input\_ignore\_missing\_property)

Description: If set to true, the resource will not be replaced if a property is missing.

Type: `bool`

Default: `false`

### <a name="input_location"></a> [location](#input\_location)

Description: Location of the resource.

Type: `string`

Default: `null`

### <a name="input_replace_triggered_by"></a> [replace\_triggered\_by](#input\_replace\_triggered\_by)

Description: Values that trigger a replacement.

Type: `any`

Default: `null`

### <a name="input_response_export_values"></a> [response\_export\_values](#input\_response\_export\_values)

Description: List of values to export from the response, made available in the output.

Type: `set(string)`

Default: `null`

### <a name="input_timeouts"></a> [timeouts](#input\_timeouts)

Description:   A map of timeouts to apply to the creation and destruction of the resource.

Type:

```hcl
object({
    create = string
    delete = string
    update = string
    read   = string
  })
```

Default:

```json
{
  "create": "10m",
  "delete": "10m",
  "read": "10m",
  "update": "10m"
}
```

## Outputs

The following outputs are exported:

### <a name="output_id"></a> [id](#output\_id)

Description: The Azure resource id of the resource.

### <a name="output_identity"></a> [identity](#output\_identity)

Description: The identity configuration of the resource.

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the resource.

### <a name="output_output"></a> [output](#output\_output)

Description: The output values of the resource as defined by `response_export_values`.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->