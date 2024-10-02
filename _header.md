[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/Azure/terraform-azurerm-avm-ptn-alz/badge)](https://scorecard.dev/viewer/?uri=github.com/Azure/terraform-azurerm-avm-ptn-alz)

# ALZ Terraform Module

- This repository contains a Terraform module for deploying Azure Landing Zones (ALZs).
- Make sure to review the examples.

> [!IMPORTANT]
> Make sure to add `.alzlib` to your `.gitignore` file to avoid committing the downloaded ALZ library to your repository.

## Features

- Deploy management groups according to the supplied architecture (defaut is ALZ)
- Deploy policy assets (definitions, assignments, and initiatives) according to the supplied architecture ands associated archetyes
- Modify policy assignments:
  - Enforcement mode
  - Identity
  - Non-compliance messages
  - Overrides
  - Parameters
  - Resource selectors
- Create the required role assignments for Azure Policy, including support for the **assign permissions** metadata tag, just like the Azure Portal
- Deploy custom role definitions

## Unknown Values

This module uses the ALZ Terraform provider. This uses a data source which **must** be read prior to creating the plan.
If you pass an unknown (known after apply) value into the module, it will not be able to read the data source until the plan is being applied.
This may cause resources to be unnecessarily recreated.

Such unknown values include resource ids. For example, if you are creating a resource and passing the id of the resource group to the module, this will cause the issue.
Instead, use string interpolation or provider functions to pass the values. For example:

### Recommended

This is the recommended way to use this module:

> [!NOTE]
> We assume that all variable inputs are literals.

```terraform
locals {
  subscription_id     = data.azapi_client_config.current.subscription_id
  resource_group_name = "rg1"
  resource_type       = "Microsoft.Network/virtualNetworks"
  resource_names      = ["vnet1"]
  my_resource_id = provider::azapi::resource_group_resource_id(
    data.azapi_client_config.current.subscription_id,
    local.resource_group_name,
    local.resource_type,
    local.resource_names
  )
}

module "example" {
  source = "Azure/terraform-azurerm-avm-ptn-alz/azurerm"

  policy_assignments_to_modify = {
    alzroot = {
      policy_assignments = {
        mypolicy = {
          parameters = {
            parameterName = jsonencode({ value = local.my_resource_id })
          }
        }
      }
    }
  }
}
```

### Deferred Actions

We are awaiting the results of the upstream Terraform language experiment *deferred actions*. This may provide a solution to this issue.
See the release notes [here](https://github.com/hashicorp/terraform/releases/tag/v1.10.0-alpha20240619) for more information.
