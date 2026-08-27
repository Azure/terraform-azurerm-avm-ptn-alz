# tfpluginschema

Use this CLI to query Terraform/OpenTofu provider schemas directly from the registry without running `terraform init`. It retrieves schemas for resources, data sources, ephemeral resources, functions, and provider configuration.

Source: <https://github.com/matt-FFFFFF/tfpluginschema>

## Installation

Use PowerShell 7 to select and install the latest release for the current operating system and architecture:

```pwsh
$release = Invoke-RestMethod 'https://api.github.com/repos/matt-FFFFFF/tfpluginschema/releases/latest'
$version = $release.tag_name.TrimStart('v')
$platform = if ($IsWindows) { 'windows' } elseif ($IsLinux) { 'linux' } elseif ($IsMacOS) { 'darwin' } else { throw 'Unsupported operating system.' }
$architecture = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()) {
  'X64' { 'amd64' }
  'Arm64' { 'arm64' }
  default { throw 'Unsupported processor architecture.' }
}
$extension = if ($IsWindows) { 'zip' } else { 'tar.gz' }
$assetName = "tfpluginschema_${version}_${platform}_${architecture}.${extension}"
$asset = $release.assets | Where-Object name -EQ $assetName
if ($null -eq $asset) { throw "Release asset not found: $assetName" }

$destination = Join-Path $HOME '.tfpluginschema'
$archivePath = Join-Path ([System.IO.Path]::GetTempPath()) $assetName
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archivePath
if ($IsWindows) {
  Expand-Archive -Path $archivePath -DestinationPath $destination -Force
}
else {
  & tar -xzf $archivePath -C $destination
  if ($LASTEXITCODE -ne 0) { throw 'Failed to extract tfpluginschema.' }
}
Remove-Item -LiteralPath $archivePath
$env:PATH = "$destination$([System.IO.Path]::PathSeparator)$env:PATH"
```

Check latest version at: <https://github.com/matt-FFFFFF/tfpluginschema/releases>

## Global Options

| Flag | Short | Description |
|---|---|---|
| `--namespace` | `-n` | Provider namespace (e.g., `Azure`, `hashicorp`) |
| `--name` | `-p` | Provider name (e.g., `azapi`, `azurerm`, `aws`) |
| `--provider-version` | `--pv` | Version or constraint (e.g., `2.12.0`, `~>2.12`). Empty for latest |
| `--registry` | `-r` | Registry: `opentofu` (default) or `terraform` |

## Commands

### List available provider versions

```pwsh
tfpluginschema -n Azure -p azapi version list
```

### List resources, data sources, functions, or ephemeral resources

```pwsh
tfpluginschema -n Azure -p azapi resource list
tfpluginschema -n Azure -p azapi datasource list
tfpluginschema -n Azure -p azapi function list
tfpluginschema -n Azure -p azapi ephemeral list
```

### Get a resource schema

```pwsh
tfpluginschema -n Azure -p azapi resource schema azapi_resource
```

### Get a data source schema

```pwsh
tfpluginschema -n Azure -p azapi datasource schema azapi_client_config
```

### Get a function schema

```pwsh
tfpluginschema -n Azure -p azapi function schema build_resource_id
```

### Get an ephemeral resource schema

```pwsh
tfpluginschema -n Azure -p azapi ephemeral schema azapi_resource_action
```

### Get the provider configuration schema

```pwsh
tfpluginschema -n Azure -p azapi provider schema
```

### Pin to a specific provider version

```pwsh
tfpluginschema -n Azure -p azapi --pv 2.12.0 resource schema azapi_resource
```

### Use a version constraint

```pwsh
tfpluginschema -n hashicorp -p azurerm --pv "~>4.0" resource list
```

Use AzureRM schema inspection when analyzing an existing module as migration source input or verifying the exact resource for a permitted unsupported data-plane/non-ARM operation. Do not use it to choose AzureRM for convenience or for control-plane and ordinary supporting resources.

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
