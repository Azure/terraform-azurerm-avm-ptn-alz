[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/Azure/terraform-azurerm-avm-ptn-alz/badge)](https://scorecard.dev/viewer/?uri=github.com/Azure/terraform-azurerm-avm-ptn-alz)

# ALZ Terraform Module

- This repository contains a Terraform module for deploying Azure Landing Zones (ALZs).
- Make sure to review the examples.

> [!IMPORTANT]
> Make sure to add `.alzlib` to your `.gitignore` file to avoid committing the downloaded ALZ library to your repository.

## Features

- Deploy management groups according to the supplied architecture (default is ALZ)
- Deploy policy assets (definitions, assignments, and initiatives) according to the supplied architecture ands associated archetypes
- Modify policy assignments:
  - Enforcement mode
  - Identity
  - Non-compliance messages
  - Overrides
  - Parameters
  - Resource selectors
- Create the required role assignments for Azure Policy, including support for the **assign permissions** metadata tag, just like the Azure Portal
- Deploy custom role definitions

## AzAPI Provider

We use the AzAPI provider to interact with the Azure APIs.
The new features allow us to be more efficient and reliable, with orders of magnitude speed improvements and retry logic for transient errors.

## Unknown Values & Depends On

This module uses the ALZ Terraform provider. This uses a data source which **must** be read prior to creating the plan.

The `depends_on` feature is therefore not supported in the ALZ provider.
Please do not add a `depends_on` attribute to the module declaration.

Similarly, if you pass an unknown (known after apply) value into the module, it will not be able to read the data source until the plan is being applied.
This may cause resources to be unnecessarily recreated.

To work around this, we have two features.
Firstly we have a `dependencies` variable.
This variable is used to ensure that policies and policy role assignments do not get created until dependent resources are available.

Secondly, for values that are passed into the module, use string interpolation or provider functions to create the required. For example:

### Using `var.dependencies`

This variable is used as a workaround for the lack of support for `depends_on` in the ALZ provider.
Place values into this variable to ensure that policies and policy role assignments do not get created until dependent resources are available.
See the variable documentation and the examples (private DNS and management) for more information.

### Using Provider Functions

Either: Use known values as inputs, or use Terraform Stacks.

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

We are awaiting the results of the upstream Terraform language experiment *deferred actions*.
This will provide a solution to this issue.
See the release notes [here](https://github.com/hashicorp/terraform/releases/tag/v1.10.0-alpha20241023) for more information.
