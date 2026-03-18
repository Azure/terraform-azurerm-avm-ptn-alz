# tfpluginschema

CLI tool for querying Terraform/OpenTofu provider schemas directly from the registry. Retrieves schemas for resources, data sources, ephemeral resources, functions, and provider configuration without needing a local Terraform init.

Source: <https://github.com/matt-FFFFFF/tfpluginschema>

## Installation

Download the latest release and extract the binary:

```bash
# Linux (amd64)
curl -sSfL https://github.com/matt-FFFFFF/tfpluginschema/releases/latest/download/tfpluginschema_0.8.0_linux_amd64.tar.gz | tar -xz -C /usr/local/bin tfpluginschema

# macOS (Apple Silicon)
curl -sSfL https://github.com/matt-FFFFFF/tfpluginschema/releases/latest/download/tfpluginschema_0.8.0_darwin_arm64.tar.gz | tar -xz -C /usr/local/bin tfpluginschema

# macOS (Intel)
curl -sSfL https://github.com/matt-FFFFFF/tfpluginschema/releases/latest/download/tfpluginschema_0.8.0_darwin_amd64.tar.gz | tar -xz -C /usr/local/bin tfpluginschema
```

Check latest version at: <https://github.com/matt-FFFFFF/tfpluginschema/releases>

## Global Options

| Flag | Short | Description |
|---|---|---|
| `--namespace` | `-n` | Provider namespace (e.g., `Azure`, `hashicorp`) |
| `--name` | `-p` | Provider name (e.g., `azapi`, `azurerm`, `aws`) |
| `--provider-version` | `--pv` | Version or constraint (e.g., `2.5.0`, `~>2.4`). Empty for latest |
| `--registry` | `-r` | Registry: `opentofu` (default) or `terraform` |

## Commands

### List available provider versions

```bash
tfpluginschema -n Azure -p azapi version list
```

### List resources, data sources, functions, or ephemeral resources

```bash
tfpluginschema -n Azure -p azapi resource list
tfpluginschema -n Azure -p azapi datasource list
tfpluginschema -n Azure -p azapi function list
tfpluginschema -n Azure -p azapi ephemeral list
```

### Get a resource schema

```bash
tfpluginschema -n Azure -p azapi resource schema azapi_resource
```

### Get a data source schema

```bash
tfpluginschema -n Azure -p azapi datasource schema azapi_client_config
```

### Get a function schema

```bash
tfpluginschema -n Azure -p azapi function schema build_resource_id
```

### Get an ephemeral resource schema

```bash
tfpluginschema -n Azure -p azapi ephemeral schema azapi_resource_action
```

### Get the provider configuration schema

```bash
tfpluginschema -n Azure -p azapi provider schema
```

### Pin to a specific provider version

```bash
tfpluginschema -n Azure -p azapi --pv 2.5.0 resource schema azapi_resource
```

### Use a version constraint

```bash
tfpluginschema -n hashicorp -p azurerm --pv "~>4.0" resource list
```

## Output Format

Output is JSON matching the Terraform plugin schema format. Key fields for resource/data source schemas:

```json
{
  "version": 2,
  "block": {
    "attributes": {
      "<name>": {
        "type": "<type>",
        "description": "<description>",
        "required": true,
        "optional": true,
        "computed": true
      }
    },
    "block_types": {
      "<name>": {
        "nesting_mode": "list|set|single|map",
        "block": { ... },
        "min_items": 0,
        "max_items": 1
      }
    }
  }
}
```

- `required`: Must be set by the user
- `optional`: May be set by the user
- `computed`: Set by the provider (read-only if not also optional)
- `optional` + `computed`: Can be set by user, has a provider default
