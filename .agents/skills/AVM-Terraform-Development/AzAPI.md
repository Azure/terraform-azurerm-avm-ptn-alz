# AzAPI Provider

All Azure resources in AVM modules MUST be deployed using the **AzAPI provider** (`Azure/azapi`).

## Provider Configuration

```hcl
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.8"
    }
  }
}
```

## Resource Pattern

AzAPI resources use ARM resource types with explicit API versions:

```hcl
resource "azapi_resource" "example" {
  type      = "<ResourceProvider>/<ResourceType>@<ApiVersion>"
  parent_id = "<parent resource ID>"
  name      = "<resource name>"
  location  = "<Azure region>"

  body = {
    properties = {
      # Resource-specific properties (HCL object, NOT JSON string)
    }
  }

  # MUST include this, set to empty list if no exports are needed.
  response_export_values = [
    "properties.<field>",
  ]
}
```

### Key attributes

| Attribute                | Description                                                                                           |
| ------------------------ | ----------------------------------------------------------------------------------------------------- |
| `type`                   | ARM resource type with API version (e.g., `Microsoft.Storage/storageAccounts@2023-01-01`)             |
| `parent_id`              | ID of the parent resource. For top-level resources: `/subscriptions/{sub}/resourceGroups/{rg}`        |
| `name`                   | Resource name                                                                                         |
| `location`               | Azure region                                                                                          |
| `body`                   | Resource properties as an **HCL object** (not a JSON string)                                          |
| `response_export_values` | List of ARM property paths to export set to empty list if not used (e.g., `"properties.principalId"`) |
| `locks`                  | A mutex. List of resource IDs to lock on to prevent concurrent operations                             |

### Accessing outputs

Use `.output` to access exported values:

```hcl
azapi_resource.example.output.properties.principalId
```

## Data sources

```hcl
# Get current client context (subscription, tenant)
data "azapi_client_config" "current" {}

# Use in expressions:
data.azapi_client_config.current.subscription_id
data.azapi_client_config.current.subscription_resource_id
data.azapi_client_config.current.tenant_id
```

## Unit test mocking

```hcl
mock_provider "azapi" {}
```

## Azure Resource Schema Lookup

Use the `azure-schema` CLI tool (bundled at `.agents/skills/AVM-Terraform-Development/azure-schema`) to look up resource type schemas, properties, constraints, and available API versions. This is essential for knowing the correct `type` and `body` structure for `azapi_resource`.

### List available API versions

```bash
.agents/skills/AVM-Terraform-Development/azure-schema versions Microsoft.Storage
```

### Get a resource schema (human-readable)

```bash
.agents/skills/AVM-Terraform-Development/azure-schema get Microsoft.Storage/storageAccounts 2023-01-01
```

### Get a resource schema (resolved JSON)

```bash
.agents/skills/AVM-Terraform-Development/azure-schema get Microsoft.Storage/storageAccounts 2023-01-01 --json
```

### Control depth

```bash
# Shallow view (top-level properties only)
.agents/skills/AVM-Terraform-Development/azure-schema get Microsoft.Storage/storageAccounts 2023-01-01 --depth 2

# Deep view (default is 5)
.agents/skills/AVM-Terraform-Development/azure-schema get Microsoft.Storage/storageAccounts 2023-01-01 --depth 8
```

## Sensitive attributes

- Passwords, keys, etc should be passed in using the `sensitive_body` attribute. This object is merged with the `body` at runtime.
- All sensitive values MUST be ephemeral.
- Use `sensitive_body_version` as a map to track the JSON properties that are set via `sensitive_body`. This allows Terraform to know when the sensitive value has changed, e.g. `sensitive_body_version = { "properties.key1" = "1" }`."
- Reference each sensitive body version as a variable.

### Workflow

1. Find the API version: `azure-schema versions <Provider>`
2. Get the schema: `azure-schema get <ResourceType> <ApiVersion>`
3. Map the schema properties into the `body` block of your `azapi_resource`
4. Properties marked `[READ-ONLY]` should not be set in `body` -- use `response_export_values` to read them if required
5. Properties marked `[REQUIRED]` must be included in `body`
