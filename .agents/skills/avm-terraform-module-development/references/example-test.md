# Testing Examples Manually

> **When to use this reference:**
>
> - You are running on **Windows** (on non-Windows systems, use the `avm` command instead).
> - You want to **distribute tests across multiple Azure subscriptions**.
> - You want to **retain deployed resources** after testing for manual validation (skip destroy).

Each subfolder under `examples/` is a standalone Terraform root module. Test each one independently.

## Testing Workflow

For each example directory, run these steps in order. Stop and fix any errors before proceeding.

1. Run Terraform init
2. Run Terraform plan
3. Run Terraform apply
4. Run Terraform plan again (idempotency check)

The idempotency check (step 4) must show **"No changes"**. If it reports drift, that is a bug - fix it. Common causes:

- **Server-side defaults**: A property not set in config gets a default from Azure. Set it explicitly. Use `ignore_changes` only as a last resort.
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
