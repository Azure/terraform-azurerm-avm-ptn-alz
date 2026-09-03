---
name: avm-tf-tflint
description: Use whenever an AVM Terraform task involves TFLint findings, AVM rule names, rule applicability, severity, exclusions, exceptions, override files, or lint validation. Covers the current canonical avm_* rules and the Avm.Authoring override merge process. Trigger on "tflint", "lint failure", "disable rule", "ignore rule", "rule override", "avm.tflint", "severity", and any AVM TFLint rule identifier.
---

# AVM Terraform TFLint

Use TFLint through `Avm.Authoring`. Fix violations instead of suppressing them unless the published AVM requirement genuinely does not apply.

## Read current sources first

Before diagnosing a finding or changing rule configuration:

1. Read the current [AVM TFLint rules and configuration overrides](https://azure.github.io/Azure-Verified-Modules/contributing/terraform/tflint-rules/#tflint-configuration-overrides).
2. Read the current [`Azure/tflint-ruleset-avm` rule inventory](https://github.com/Azure/tflint-ruleset-avm/blob/main/RULES.md).
3. Check the [latest released ruleset](https://github.com/Azure/tflint-ruleset-avm/releases/latest) when a plugin version or supported option matters.
4. Fetch the linked AVM specification for the reported rule before changing Terraform.

The published rules guide controls applicability and the supported override process. The released plugin controls valid rule identifiers and configuration. Do not rely on an older module, cached rule name, or this inventory when a live source differs.

## Run the managed toolchain

```pwsh
Import-Module Avm.Authoring
avm version
avm lint
```

If the version gate reports a stale installation, run `avm update`, re-import the module, and retry. Run `avm pre-commit` before linting when managed sync or transforms can affect the configuration. Use `avm pr-check` only after committing the complete worktree because it requires a clean worktree.

Do not approximate the managed configuration with a separately installed TFLint binary, custom plugin setup, Make, Porch, or a container.

## Prefer configuration overrides

Use the supported AVM override files by default. They make exceptions visible, reviewable, and consistent across the intended root, submodule, or example scope.

Use a line-level TFLint annotation when a single finding is exceptional and disabling the rule for the full supported configuration scope would hide unrelated findings. TFLint annotations can suppress issues only in valid, parseable Terraform and only when the rule permits annotations. Read the current [TFLint annotation documentation](https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/annotations.md) before using one.

```hcl
# This declaration is consumed after the managed transform runs.
# tflint-ignore: terraform_unused_declarations
avm_azapi_header = join(" ", [for k, v in local.avm_azapi_headers : "${k}=${v}"])
```

Name only the specific rule and explain the reason. Do not use `all`. Avoid file-level annotations unless the entire file genuinely needs the same exception.

## Override only after investigating

1. Read the rule guidance and its linked AVM specification.
2. Confirm the rule applies to the failing root, submodule, or example.
3. Prefer a compliant code change.
4. If an exception is justified, decide whether a line-level annotation preserves more coverage than the narrowest supported override file.
5. Explain why the exception is valid, its exact scope, and any issue or pull request that will remove it.
6. Re-run `avm lint` and inspect the merged-scope result.

Never disable a rule merely to make CI pass. Keep exceptions temporary where possible. A scope-wide override does not authorize unrelated violations in that scope; manually review the scope for any additional occurrences.

## Supported override files

| File | Scope |
| --- | --- |
| `avm.tflint.override.hcl` | Root module checks. |
| `avm.tflint_module.override.hcl` | Every direct submodule under `modules/*`. |
| `avm.tflint_example.override.hcl` | Every direct example under `examples/*`. |
| `modules/<name>/avm.tflint.override.hcl` | One direct submodule only. |
| `examples/<name>/avm.tflint.override.hcl` | One direct example only. |

`Avm.Authoring` merges the immutable AVM base configuration first, then the matching repository-wide scope override, then the target-directory override. The target override wins for that direct submodule or example. Nested module and example roots are prohibited, so do not invent override paths below `modules/*` or `examples/*`.

Use normal TFLint rule configuration with the current canonical rule name:

```hcl
# This pattern module does not represent one resource, so RMFR7 does not apply.
rule "avm_output_resource_id_required" {
  enabled = false
}
```

AVM plugin rules also accept `severity = "error"`, `"warning"`, or `"notice"`:

```hcl
# Track legacy interface migration without blocking unrelated maintenance.
rule "avm_interface_lock_deprecated" {
  enabled  = true
  severity = "notice"
}
```

Per-rule severity changes are separate from TFLint's global `--minimum-failure-severity` process threshold.

For a narrowly approved AzureRM exception, prefer an override of `avm_provider_azurerm_disallowed` in the narrowest supported scope and list every permitted `azurerm_*` block in the justification comments with the AzAPI gap and upstream issue or pull request. If the scope contains other AzureRM checks that must remain enforced, use a justified line-level annotation for the exceptional finding instead. Manually verify that no undocumented AzureRM declarations or usages exist.

## Canonical rule names

Ruleset v1.0.0 removed all legacy aliases. Every AVM rule identifier starts with `avm_`. Old names such as `provider_azurerm_disallowed`, `required_output_rmfr7`, `resource_types`, `retry`, and `timeouts` are invalid in current configuration.

This is the current v1.0.0 inventory. Verify it against the live sources above before use.

| Rule | Scope | Default severity |
| --- | --- | --- |
| `avm_azapi_data_response_export_values_required` | All module scopes | Error |
| `avm_azapi_replace_triggers_refs_valid` | All module scopes | Error |
| `avm_azapi_resource_tags_required` | All module scopes | Error |
| `avm_azapi_response_export_values_required` | All module scopes | Error |
| `avm_interface_customer_managed_key` | All module scopes | Error |
| `avm_interface_diagnostic_settings` | All module scopes | Error |
| `avm_interface_ignore_body_changes` | All module scopes | Error |
| `avm_interface_location` | All module scopes | Error |
| `avm_interface_lock` | All module scopes | Error |
| `avm_interface_lock_deprecated` | All module scopes | Notice |
| `avm_interface_managed_identities` | All module scopes | Error |
| `avm_interface_private_endpoints` | All module scopes | Error |
| `avm_interface_private_endpoints_deprecated` | All module scopes | Notice |
| `avm_interface_private_endpoints_manage_dns_zone_group` | All module scopes | Error |
| `avm_interface_resource_types` | All module scopes | Error |
| `avm_interface_retry` | All module scopes | Error |
| `avm_interface_role_assignments` | All module scopes | Error |
| `avm_interface_role_assignments_deprecated` | All module scopes | Notice |
| `avm_interface_tags` | All module scopes | Error |
| `avm_interface_timeouts` | All module scopes | Error |
| `avm_output_entire_resource_disallowed` | Module scopes | Error |
| `avm_output_resource_id_required` | Root module | Error |
| `avm_provider_azapi_version_constraint` | Module scopes | Error |
| `avm_provider_azurerm_disallowed` | Module scopes | Error |
| `avm_provider_azurerm_version_constraint` | Module scopes | Error |
| `avm_provider_modtm_version_constraint` | Module scopes | Error |
| `avm_terraform_configuration_file_required` | Module scopes | Error |
| `avm_terraform_ignore_changes_unquoted_references` | All module scopes | Error |
| `avm_terraform_literal_heredoc_disallowed` | All module scopes | Notice |
| `avm_terraform_module_source_required` | Module scopes | Error |
| `avm_terraform_provider_block_disallowed` | Module scopes | Warning |
| `avm_terraform_sensitive_variable_default_disallowed` | All module scopes | Warning |

## Understand adjacent tooling

The AVM plugin does not duplicate all formatting and Terraform checks:

- MAPOTF owns deterministic ordering, file placement transforms, formatting, and removal of redundant explicit `nullable = true`.
- The standard Terraform TFLint plugin validates Terraform and provider requirement declarations.
- The AVM ruleset adds AVM-specific specification checks.

Run the managed command and address findings from each owner. Do not create an AVM-rule override for a formatting problem owned by MAPOTF.
