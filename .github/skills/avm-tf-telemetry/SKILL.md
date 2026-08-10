---
name: avm-tf-telemetry
description: Use this skill whenever an Azure Verified Module (AVM) for Terraform needs to wire up, debug, or explain telemetry — the `main.telemetry.tf` file with `modtm_telemetry` + `random_uuid.telemetry` + `data.azapi_client_config.telemetry` + `data.modtm_module_source.telemetry`, the `enable_telemetry` consumer-facing variable (which MUST default to `true` per SFR4), the `modtm` provider's role in shipping anonymous deployment counts to Application Insights, and the AzAPI request-header telemetry that flows alongside it. Also covers the fork-detection logic (whether the module source comes from an `Azure/*` registry/repo vs a fork), and what to do when consumers ask "how do I turn telemetry off". Trigger on phrases like "modtm", "main.telemetry.tf", "enable_telemetry", "AVM telemetry", "turn off telemetry", "telemetry provider", "SFR3", "SFR4", "Data Collection notice", "avm_module_source", "fork_avm".
---

# AVM Terraform telemetry

Every AVM Terraform module that deploys resources collects anonymous deployment/usage telemetry, on by default, with a single opt-out variable. The wiring lives in `main.telemetry.tf` and is maintained by the Mapotf transforms bundled with `Avm.Authoring`.

Fetch <https://azure.github.io/Azure-Verified-Modules/llms.txt> and confirm the current versions of these sources:
- [SFR3](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/shared/functional/SFR3.md) — Deployment/Usage Telemetry
- [SFR4](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/shared/functional/SFR4.md) — Telemetry Enablement Flexibility
- <https://registry.terraform.io/providers/Azure/modtm/latest>
- The current `main_telemetry_tf.mptf.hcl` and `avm_headers_for_azapi.mptf.hcl` transforms in <https://github.com/Azure/azure-verified-modules-tools>
- `aka.ms/avm/telemetry` (the consumer-facing page)

## The headline rule

> Telemetry **MUST** be on/enabled by default. Consumers **MUST** be able to disable it by setting `enable_telemetry = false`. ([SFR4](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/shared/functional/SFR4.md))

A module that deploys resources cannot opt out of telemetry; it exposes the opt-out to the consumer. Removing or defaulting `enable_telemetry` to `false` fails AVM linting.

## What `main.telemetry.tf` does

```hcl
data "azapi_client_config" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}

data "modtm_module_source" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
  module_path = path.module
}

locals {
  # If the module deploys to a single location, surface it on the telemetry record.
  # If the module has no location concept, set this to "unknown".
  main_location = var.location
}

resource "random_uuid" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}

resource "modtm_telemetry" "telemetry" {
  count = var.enable_telemetry ? 1 : 0

  tags = merge({
    subscription_id = one(data.azapi_client_config.telemetry).subscription_id
    tenant_id       = one(data.azapi_client_config.telemetry).tenant_id
    module_source   = one(data.modtm_module_source.telemetry).module_source
    module_version  = one(data.modtm_module_source.telemetry).module_version
    random_id       = one(random_uuid.telemetry).result
  }, { location = local.main_location })
}

# Derived headers passed to AzAPI requests so server-side telemetry can correlate
locals {
  valid_module_source_regex = [
    "registry.terraform.io/[A|a]zure/.+",
    "registry.opentofu.io/[A|a]zure/.+",
    "git::https://github\\.com/[A|a]zure/.+",
    "git::ssh:://git@github\\.com/[A|a]zure/.+",
  ]

  fork_avm = !anytrue([
    for r in local.valid_module_source_regex :
    can(regex(r, one(data.modtm_module_source.telemetry).module_source))
  ])

  avm_azapi_headers = !var.enable_telemetry ? {} : (local.fork_avm ? {
    fork_avm  = "true"
    random_id = one(random_uuid.telemetry).result
    } : {
    avm                = "true"
    random_id          = one(random_uuid.telemetry).result
    avm_module_source  = one(data.modtm_module_source.telemetry).module_source
    avm_module_version = one(data.modtm_module_source.telemetry).module_version
  })

  # tflint-ignore: terraform_unused_declarations
  avm_azapi_header = join(" ", [for k, v in local.avm_azapi_headers : "${k}=${v}"])
}
```

### The moving parts

| Symbol | Role |
|---|---|
| `data.azapi_client_config.telemetry` | Reads the current subscription + tenant ID for the telemetry record. Same data source other places in the module use; the `telemetry` instance is independent so you can read it even if no AzAPI resource is created. |
| `data.modtm_module_source.telemetry` | Inspects `path.module` and figures out where the module was loaded from (Registry, GitHub, OpenTofu Registry, etc.) and what version. |
| `random_uuid.telemetry` | Generates a random ID retained with the module instance's Terraform state so telemetry can be correlated without identifying a person. |
| `modtm_telemetry.telemetry` | The actual telemetry "resource" — its lifecycle hooks send a HTTP POST to the AVM telemetry collector with the tags map. |
| `local.fork_avm` | True if the module wasn't loaded from an official `Azure/*` source — i.e. someone forked the module. Telemetry still flows but is tagged differently. |
| `local.avm_azapi_headers` / `avm_azapi_header` | Builds the `User-Agent` value that `avm transform` merges into the applicable AzAPI create, read, update, and delete header attributes. |

### What gets sent

The telemetry record contains:

- `subscription_id`, `tenant_id` (from the current ARM client context — not consumer's identity)
- `module_source`, `module_version` (so AVM team knows which module + version)
- `location` (so we know regional adoption)
- `random_id` (correlation; not personally identifying)

No resource names, no resource configurations, no consumer code, no Azure resource IDs. The telemetry is genuinely lightweight — it answers "how often is this module used and at what version" and nothing else.

## Required `terraform.tf` entry

The `modtm` provider **MUST** appear in `required_providers`:

```hcl
modtm = {
  source  = "Azure/modtm"
  version = "~> 0.3"
}
```

AVM linting checks for this.

## The consumer-facing variable

In `variables.tf`:

```hcl
variable "enable_telemetry" {
  type        = bool
  default     = true
  nullable    = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}
```

Convention: put `enable_telemetry` **last** in `variables.tf`, after all interface variables (see `avm-tf-codestyle`).

## When a module references other AVM modules (cross-references)

If your module consumes another AVM module (typical for pattern modules), **pass `enable_telemetry` through** so the consumer's opt-out reliably disables telemetry across the whole module graph:

```hcl
module "kv" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.10"

  enable_telemetry = var.enable_telemetry   # pass through
  # ...
}
```

This is called out in SFR4: "the telemetry parameter value **MUST** be passed through to these modules".

## The Data Collection notice

Per SFR3 the README **MUST** include a Data Collection notice with the canonical wording (drawn from Microsoft's open-source guidance). For Terraform, this notice lives in `_footer.md` (NOT in `README.md` directly — `README.md` is auto-generated, see `avm-tf-documentation`):

```markdown
<!-- _footer.md -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
```

The template ships `_footer.md` with this notice — don't delete it.

## When do you edit `main.telemetry.tf`?

**Almost never.** The file is governance-managed and meant to stay identical across modules. Run `avm sync` and `avm transform` rather than copying a potentially stale template. The only normal module-specific edit is to `local.main_location` if your module:

- Doesn't accept a `location` variable (e.g. a global resource) — set `main_location = "unknown"`.
- Sources its location from a collection or computed value — set `main_location = <the right expression>`.

Everything else is part of the standard, validated wiring. If you find yourself wanting to modify how telemetry is collected, that's a conversation for the AVM core team, not a per-module change.

## Utility modules

Per SFR3, **utility modules that deploy no resources MUST NOT include telemetry.** The `modtm_telemetry` resource itself counts as a "resource that gets deployed", so adding it to a pure-logic utility module triggers a no-op resource in consumer plans for no benefit.

## Common pitfalls

- **Defaulting `enable_telemetry = false`.** SFR4 violation. Defaults to `true`, period.
- **Removing `main.telemetry.tf` because "I don't see why my module needs it".** SFR3 violation; CI fails. The whole point is that telemetry is uniform across the AVM ecosystem.
- **Editing the modtm logic to add custom tags.** Don't — telemetry shape is standardised. If you genuinely need richer telemetry (e.g. for a new module class), raise it with the AVM core team.
- **Not passing `enable_telemetry` through to child AVM modules.** A consumer who sets `enable_telemetry = false` on the pattern module expects telemetry off for the whole graph; if you don't pass it through, child resource modules still emit telemetry.
- **Forgetting the Data Collection notice in `_footer.md`.** Required by SFR3. The template includes it; deletions will fail review.
- **Putting the Data Collection notice in `README.md` directly.** It gets overwritten on the next `avm pre-commit` run. Put it in `_footer.md`.
- **Using a `modtm` version other than `~> 0.3`.** Pinned by spec and validated by lint.
