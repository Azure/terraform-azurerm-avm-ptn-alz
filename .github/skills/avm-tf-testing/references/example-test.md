# Manual AVM Example Testing

> **When to use this reference:**
>
> - You want to **distribute tests across multiple Azure subscriptions**.
> - You want to **retain deployed resources** after testing for manual validation (skip destroy).
> - You are debugging an example outside the standard E2E runner.

Use `avm test e2e`, `avm test e2e --list`, or `avm test e2e --example <name>` for normal example validation on every operating system. Each subfolder under `examples/` is a standalone Terraform root module; use the manual workflow below only when the standard runner does not fit the scenario.

## Provider rule

Examples and E2E configurations for a newly authored module use AzAPI for all control-plane and ordinary supporting resources. When an example needs a direct Azure setup resource that is not supplied through the module under test, use an AzAPI resource, data source, or action. Its `required_providers` block must include `Azure/azapi`.

An example may configure or exercise `hashicorp/azurerm` only for independently permitted `azurerm_*` resource or data-source blocks. Each block must implement one specific unsupported data-plane/non-ARM operation, document the exact block and why AzAPI cannot implement it with an upstream AzAPI issue or pull request, and be replaced when support ships. One valid block does not authorize another.

A published AVM module source ending in `/azurerm` is a legacy Terraform Registry namespace, not permission to use the AzureRM provider. Preserve a legitimate legacy source address when needed.

## Testing Workflow

For each example directory, run these steps in order. Stop and fix any errors before proceeding.

1. Run Terraform init
2. Run Terraform plan
3. Run Terraform apply
4. Run Terraform plan again (idempotency check)

The idempotency check (step 4) must show **"No changes"**. If it reports drift, that is a bug - fix it. Common causes:

- **Server-side defaults**: A property not set in config gets a default from Azure. Set it explicitly. For known static drift, prefer `lifecycle.ignore_changes`; use the TFFR8 `ignore_body_changes` interface when callers need dynamic body-relative paths.
- **Computed attributes**: An output or reference that changes on every read.
- **Provider bugs**: Check for known issues in the provider repository.

### Destroy

**Ask the user before destroying.** They may want to inspect resources in the Azure portal or keep them for debugging.

```powershell
terraform destroy
```

Some resources (e.g., soft-delete enabled Key Vaults) may require manual purging.

## Distributing Examples Across Subscriptions

To avoid quota limits or reduce blast radius, distribute examples across multiple subscriptions.

**Always ask the user before changing the subscription.**

Set `ARM_SUBSCRIPTION_ID` before running each example:

```powershell
$env:ARM_SUBSCRIPTION_ID = "<subscription-id>"
```

### Round-Robin Example

```powershell
$subscriptions = @(
  "00000000-0000-0000-0000-000000000001"
  "00000000-0000-0000-0000-000000000002"
  "00000000-0000-0000-0000-000000000003"
)

$i = 0
foreach ($dir in Get-ChildItem -Path examples -Directory) {
  $env:ARM_SUBSCRIPTION_ID = $subscriptions[$i % $subscriptions.Count]
  Write-Host "=== Testing $($dir.Name) on subscription $env:ARM_SUBSCRIPTION_ID ==="
  Push-Location $dir.FullName
  terraform init -upgrade
  terraform plan -out=tfplan
  terraform apply tfplan
  terraform plan  # idempotency check
  Pop-Location
  $i++
}
```
