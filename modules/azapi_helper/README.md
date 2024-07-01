<!-- BEGIN_TF_DOCS -->
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/Azure/terraform-azurerm-avm-ptn-alz/badge)](https://scorecard.dev/viewer/?uri=github.com/Azure/terraform-azurerm-avm-ptn-alz)

# ALZ Terraform Module (policy assignment)

> ⚠️ **\_Warning\_** ⚠️ This module is still in development but is ready for initial testing and feedback via [GitHub Issues](https://github.com/Azure/terraform-azurerm-avm-ptn-alz/issues).

As we are using AzAPI, we do not have the full Terraform schema optopns available for detecting attribute changes that require recreating the resource.
This submodule is therefore used to enable the `terraform_data` method for `replace_triggered_by`: <https://developer.hashicorp.com/terraform/language/resources/terraform-data#example-usage-data-for-replace_triggered_by>.
This allows us to replace the resource when certain key attributes change.

```hcl
resource "azapi_resource" "this" {
  type      = "Microsoft.Authorization/policyAssignments@2024-04-01"
  name      = var.name
  parent_id = var.parent_id
  location  = var.location
  body = {
    properties = var.properties
  }

  response_export_values = [
    "identity.principalId",
    "identity.tenantId",
    "identity.type",
  ]

  lifecycle {
    replace_triggered_by = [
      terraform_data.replace_trigger
    ]
  }
}

resource "terraform_data" "replace_trigger" {
  input = [
    var.name,
    lookup(var.properties, "location", null),
    lookup(var.properties, "policyDefinitionId", null),
  ]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 1.13, != 1.13.0)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 1.13, != 1.13.0)

- <a name="provider_terraform"></a> [terraform](#provider\_terraform)

## Resources

The following resources are used by this module:

- [azapi_resource.this](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [terraform_data.replace_trigger](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: Value of the location field in the resource.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the policy assignment.

Type: `string`

### <a name="input_parent_id"></a> [parent\_id](#input\_parent\_id)

Description: The parent ID of the policy assignment.

Type: `string`

### <a name="input_properties"></a> [properties](#input\_properties)

Description: The body properties object of the policy assignment.

Type: `any`

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_identity_type"></a> [identity\_type](#output\_identity\_type)

Description: Value of the type attribute of the identity object

### <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id)

Description: Value of the principalId attribute of the identity object

### <a name="output_tenant_id"></a> [tenant\_id](#output\_tenant\_id)

Description: Value of the tenantId attribute of the identity object

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->