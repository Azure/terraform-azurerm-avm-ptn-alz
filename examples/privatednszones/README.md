<!-- BEGIN_TF_DOCS -->
# ALZ + Management

This example shows how to deploy the ALZ reference architecture combines with the ALZ management module.

```hcl
provider "alz" {
  library_references = [{
    path = "platform/alz"
    ref  = "2024.11.0"
  }]
}

provider "azurerm" {
  features {}
}

variable "random_suffix" {
  type        = string
  default     = "fgcsnm"
  description = "Change me to something unique"
}

data "azapi_client_config" "current" {}

locals {
  location            = "swedencentral"
  resource_group_name = "rg-private-dns-${var.random_suffix}"
}

module "private_dns_zones" {
  source              = "Azure/avm-ptn-network-private-link-private-dns-zones/azurerm"
  version             = "0.7.0"
  location            = local.location
  resource_group_name = local.resource_group_name
}

module "alz" {
  source             = "../../"
  architecture_name  = "alz"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = local.location
  policy_default_values = {
    private_dns_zone_subscription_id     = jsonencode({ value = data.azapi_client_config.current.subscription_id })
    private_dns_zone_region              = jsonencode({ value = local.location })
    private_dns_zone_resource_group_name = jsonencode({ value = local.resource_group_name })
  }
  dependencies = {
    policy_assignments = [
      module.private_dns_zones.private_dns_zone_resource_ids,
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

Default: `"fgcsnm"`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_alz"></a> [alz](#module\_alz)

Source: ../../

Version:

### <a name="module_private_dns_zones"></a> [private\_dns\_zones](#module\_private\_dns\_zones)

Source: Azure/avm-ptn-network-private-link-private-dns-zones/azurerm

Version: 0.7.0

<!-- END_TF_DOCS -->