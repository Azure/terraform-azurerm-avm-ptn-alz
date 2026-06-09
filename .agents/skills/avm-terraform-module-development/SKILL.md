---
name: avm-terraform-module-development
description: Azure Verified Modules (AVM) Terraform development workflow for reviewing, fixing, and extending Resource Modules and Pattern Modules
glob: "**/*.terraform,**/*.tf,**/*.tfvars,**/*.tfstate,**/*.tflint.hcl,**/*.tf.json,**/*.tfvars.json"
---

# Azure Verified Modules (AVM) Terraform

Azure Verified Modules (AVM) are pre-built, tested, and validated Terraform and Bicep modules that follow Azure best practices. Use this skill when reviewing, fixing, or extending an AVM Terraform module so the change stays aligned with the published AVM specifications.

## Before you start

### 1. Identify the module type

Look at the repo name and `_header.md` to classify the module. The naming convention is `terraform-<provider>-avm-<type>-<name>`:

| Type | Name token | Purpose |
|------|------------|---------|
| Resource Module | `res` | Deploys a single primary Azure resource plus its tightly-coupled children (e.g. `terraform-azurerm-avm-res-storage-storageaccount`). |
| Pattern Module | `ptn` | Composes multiple resource modules into an opinionated workload (e.g. `terraform-azurerm-avm-ptn-aks-production`). |
| Utility Module | `utl` | Helper module exposing shared inputs/outputs (e.g. `Azure/avm-utl-interfaces/azure`). |

The composition rules differ slightly per type. The shared rules below apply to **resource and pattern modules** — if you are working on a utility module, fetch its dedicated spec.

### 2. Read the right spec, on demand

Every AVM rule has an ID (e.g. `TFRMFR1`, `TFFR4`, `SNFR3`). When you need the authoritative text:

1. Fetch the AVM spec index once per session:
   - `https://azure.github.io/Azure-Verified-Modules/llms.txt`
2. Look up the raw markdown URL for the spec ID you need. URLs follow the pattern:
   - `https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/terraform/<scope>/<functional|non-functional>/<ID>.md`
3. Fetch and read the specific spec markdown.

Never cite a spec ID without first confirming its current text from the index — wording and severity can change.

### 3. Understand severity prefixes

AVM uses RFC 2119 keywords: **MUST**, **SHOULD**, **MAY**. Treat `MUST` rules as blocking and `SHOULD` as defaults that need an explicit reason to skip.

## Module composition checklist

Before you claim a change is done, verify the module still satisfies these MUST-level gates. For full text, look up each ID via `llms.txt`.

### Repository & file layout

- `RMNFR1` — Module names follow `terraform-<provider>-avm-<res|ptn|utl>-<service>[-<descriptor>]`. The approved name is the one in the module proposal / module-index CSV — don't construct it yourself.
- `TFNFR39` — Standard file layout: `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tf` are MUST; `locals.tf` is required if any locals exist. Files MAY be split as `main.<topic>.tf` / `variables.<topic>.tf` / `outputs.<topic>.tf` / `locals.<topic>.tf` using the canonical prefix. The `terraform {}` block appears exactly once, in `terraform.tf`. No `providers.tf` at module root.
- `TFNFR2` / `SNFR15` — `README.md` is auto-generated. Edit `_header.md` (and `_footer.md`) only — they are required inputs to docs generation, in every submodule too.
- `TFNFR4` — `snake_case` everywhere in Terraform code.

### Inputs & outputs

- `TFNFR1` / `TFNFR17` / `TFNFR18` — Every variable and output has a `description` and a precise `type`.
- `TFNFR20` — Collection variables (`map`, `set`, `list`) default to `{}` / `[]` with `nullable = false` rather than `null`.
- `RMFR7` / `TFFR2` / `TFNFR16` — Outputs follow AVM minimum requirements and naming rules. For Terraform-specific additional outputs, prefer discrete computed attributes over whole resource object outputs.
- `TFRMFR1` — **Resource Module Parent ID**: expose the parent scope as a single `string` variable named `parent_id`, `nullable = false`, no default. Assign it to `parent_id` on every primary `azapi_resource`. Modules **MUST NOT** accept `resource_group_name`, `resource_group_resource_id`, or any other parent-scope-specific variable. Modules **MUST NOT** create the parent scope themselves (supersedes the Terraform clause of `RMFR3`). Submodules typically receive `parent_id = azapi_resource.this.id` from the parent.
- `TFNFR38` — Validate `parent_id` with `can(provider::azapi::parse_resource_id("<ExpectedParentType>", var.parent_id))`. The expected parent type **MUST** be a literal string (e.g. `"Microsoft.Resources/resourceGroups"` or `"Microsoft.Network/virtualNetworks"`). Hand-rolled `regex`/`startswith`/`length` checks are not allowed. Extension-resource modules (locks, role assignments, diagnostic settings, tags, etc.) are the only exception and use a generic `startswith` check on `/subscriptions/` or `/providers/`, with the reason documented in the README.

### Resource implementation

- `TFRMNFR2` — **Primary Resource Naming**: the primary `azapi_resource` (or equivalent AzAPI resource) **MUST** be named `this`. Every satellite resource (lock, role assignments, diagnostic settings, private endpoints, child resources required by the primary, etc.) **MUST NOT** be named `this` — it **MUST** be named after what it represents (e.g. `azapi_resource.lock`, `azapi_resource.role_assignments`, `azapi_resource.diagnostic_settings`). Each submodule has its own `this`. This is what lets consumers and the AVM interface utility module rely on `azapi_resource.this.id` and `azapi_resource.this.output`.
- `TFRMNFR1` — **Subresources as submodules**: every ARM subresource (a child resource type in the API spec) **MUST** be implemented as a Terraform submodule under `modules/<singular-subresource-name>/`. Submodules are full AVM modules in their own right (same shared/RM/TF specs apply), each with their own `_header.md` and `_footer.md`. Submodules **MUST NOT** declare `count` / `for_each` on their primary `azapi_resource` — cardinality is the parent's responsibility. Parent modules **MUST** reference submodules by local relative path (`./modules/<name>`), not via the registry or git.
- `TFFR3` — Resources are implemented with the **AzAPI provider** (`Azure/azapi` `>= 2.0, < 3.0`). Only fall back to `azurerm` (preferring data sources) when AzAPI genuinely lacks an equivalent; document the reason in code and in `README.md` per the exception requirements.
- `TFFR4` — Every `azapi_resource` **MUST** specify `response_export_values`, even if it is `[]`. Use it (list or map form) to surface read-only properties needed by the module's outputs.
- `TFFR5` — Every `azapi_resource` **MUST** specify `replace_triggers_refs`, listing the body paths that should force replacement when changed. `name` and `location` already trigger replacement and don't need to be listed.
- `TFFR6` — The `type` argument **MUST NOT** be hard-coded. Source it from a `resource_types` object variable with one `optional(string, "<provider>/<resource>@<api-version>")` field per AzAPI resource the module declares. Defaults must be stable (non-preview) API versions. Parent modules **MUST** cascade the relevant subset of `resource_types` to each submodule.
- `TFFR7` — Expose `retry` and `timeouts` variables and apply them to every `azapi_resource`. `retry` is an attribute (assign directly); `timeouts` is a block (use `dynamic "timeouts"` so the `null` default works). Cascade unchanged into submodules. See [AzAPI.md](references/AzAPI.md).

For full AzAPI patterns, the `parent_id` variable shape, the `Get-AzureSchema` lookup CLI, and provider configuration, read [AzAPI.md](references/AzAPI.md).

### Telemetry, providers, and required versions

- `SFR3` / `SFR4` — `main.telemetry.tf` must declare the `modtm` telemetry resource gated on `var.enable_telemetry`. Do not remove or rename it.
- `TFFR3` / `TFNFR26` — Pin `required_providers` versions (`Azure/azapi`, `Azure/modtm`, `hashicorp/random`, any other providers used) in the single `terraform {}` block in `terraform.tf`. AzAPI version policy is governed by `TFFR3`.
- `TFNFR27` — No provider configuration blocks in modules (only `required_providers`). Provider configuration belongs in the consumer's root module.

The `mapotf` pre-commit config under [mapotf-configs/pre-commit](../../../../../mapotf-configs/pre-commit/) enforces the telemetry block and provider versions automatically — do not hand-edit those generated files.

### Standard interfaces

AVM defines a fixed set of standard interfaces that resource modules expose where the underlying Azure resource supports them. They standardise variable names, types, and behaviour across every module:

- **Resource features** (apply only when the underlying resource supports them): diagnostic settings (v2 schema), role assignments, locks, managed identities, private endpoints, customer-managed keys, tags.
- **AzAPI mechanics** (apply to every module): `resource_types` (API-version pinning per `azapi_resource`, module-specific keys, cascaded to submodules), `retry` (assigned as an attribute), `timeouts` (emitted via a `dynamic "timeouts"` block).

The resource-feature interfaces are backed by the shared utility module `Azure/avm-utl-interfaces/azure` — compose it rather than redefining variable shapes by hand. The diagnostic-settings interface MUST use the v2 shape (`diagnostic_settings_v2` input / `diagnostic_settings_azapi_v2` output on the utility module).

For variable shapes, defaults, the v2 diagnostic-settings details, and which interfaces apply to which resource, read [interfaces.md](references/interfaces.md). For the `retry` / `timeouts` variable schemas and the required `dynamic "timeouts"` wiring on `azapi_resource`, read [AzAPI.md](references/AzAPI.md).

### Module composition reference

For a single concise summary of how a resource or pattern module fits together (file layout, parent-child resource splitting, sub-module rules, examples folder conventions), read [module-composition.md](references/module-composition.md).

## Development Workflow

Follow these steps in order when fixing an issue or adding a feature.

### Step 1: Start from a clean main branch

```bash
git checkout main
git pull
```

### Step 2: Create and checkout a feature/issue branch

```bash
git checkout -b feature/<short-description>
# or
git checkout -b fix/<issue-number>-<short-description>
```

### Step 3: Implement the change

Make the necessary code changes, keeping the composition checklist above in mind.

For AzAPI resource patterns, schema lookups, and the `Get-AzureSchema` CLI tool, read [AzAPI.md](references/AzAPI.md). To query Terraform provider schemas (resources, data sources, functions, ephemeral resources), use the `tfpluginschema` CLI — see [tfpluginschema.md](references/tfpluginschema.md).

### Step 4: Add unit tests (if justified)

Unit tests use **provider mocking** and live in the `tests/unit` directory. Add or update unit tests when your change introduces new logic, variables, or outputs that can be validated without deploying real infrastructure. For test writing guidance, syntax, and patterns, read [terraform-test.md](references/terraform-test.md).

```bash
PORCH_NO_TUI=1 ./avm tf-test-unit
```

### Step 5: Add integration tests (if justified)

Integration tests do **not** use provider mocking and live in the `tests/integration` directory. Add or update integration tests when your change requires validation against real Azure infrastructure. For test writing guidance, syntax, and patterns, read [terraform-test.md](references/terraform-test.md).

```bash
PORCH_NO_TUI=1 ./avm tf-test-integration
```

### Step 6: Add or update examples (if justified)

If your change affects module usage or introduces new functionality, add or update examples in the `examples/` directory. Test only the pertinent example:

```bash
PORCH_NO_TUI=1 AVM_EXAMPLE="<ExampleDir>" ./avm test-examples
```

When running on Windows, distributing tests across multiple Azure subscriptions, or retaining deployed resources for manual validation, see [example-test.md](references/example-test.md) for manual local testing of examples (init, plan, apply, idempotency check, and optional destroy).

### Step 7: Update documentation (if justified)

If documentation changes are needed, edit `_header.md`. **NEVER edit README.md directly** -- it is auto-generated and will be overwritten.

### Step 8: Run pre-commit checks (MANDATORY)

This must **always** be run before committing:

```bash
PORCH_NO_TUI=1 ./avm pre-commit
```

### Step 9: Commit changes

```bash
git add .
git commit -m "<type>: <meaningful description>"
```

### Step 10: Run PR checks (MANDATORY)

This must **always** be run after committing:

```bash
PORCH_NO_TUI=1 ./avm pr-check
```

### Step 11: Push and open a PR

Push the branch to remote and open a pull request with a meaningful description. Reference any issues that should be closed.

```bash
git push -u origin HEAD
```

When creating the PR, include:

- A summary of the change.
- The issue number(s) the PR closes.
- Any relevant context for reviewers.

## Common mistakes to avoid

- **Citing a spec from memory.** AVM specs change. Always fetch the current text via `llms.txt`. Several spec IDs are easy to mix up (e.g. `TFFR4` is `response_export_values`, `TFFR5` is `replace_triggers_refs`, `TFFR6` is `resource_types`, `TFFR7` is `retry`/`timeouts`).
- **Reaching for `azurerm`.** `TFFR3` requires AzAPI; only fall back to `azurerm` for genuinely missing capabilities, and document why.
- **Naming the primary resource anything other than `this`** (`TFRMNFR2`), or naming a satellite resource `this`. The primary `azapi_resource` MUST be `this`; satellites MUST be named after what they represent (`lock`, `role_assignments`, `diagnostic_settings`, ...).
- **Exposing `resource_group_name` (or any other parent-scope-specific variable) instead of `parent_id`** (`TFRMFR1`), or validating `parent_id` with hand-rolled regex/startswith instead of `can(provider::azapi::parse_resource_id("<ExpectedParentType>", var.parent_id))` (`TFNFR38`).
- **Creating the parent scope inside the module** (e.g. a `Microsoft.Resources/resourceGroups` `azapi_resource` for the resource group the module deploys into) — `TFRMFR1` forbids this; the consumer supplies an existing scope's ARM ID.
- **Hard-coding the `type` argument on an `azapi_resource`** instead of sourcing it from `var.resource_types` (`TFFR6`), or forgetting to cascade the relevant subset to each submodule.
- **Omitting `response_export_values` (`TFFR4`) or `replace_triggers_refs` (`TFFR5`)** — both are MUST on every `azapi_resource`, even when the value is `[]`.
- **Editing `README.md`, `main.telemetry.tf`, or `terraform.tf` provider versions by hand.** These are generated/enforced — edit `_header.md`, the `modtm` source via mapotf configs, and so on.
- **Defaulting collection variables to `null`** instead of `{}` / `[]` with `nullable = false` (`TFNFR20`).
- **Outputting whole resource objects by default** instead of discrete computed attributes (`TFFR2`), or missing required outputs (`RMFR7`).
- **Implementing an ARM subresource inline in the parent module** instead of as a submodule under `modules/<singular-name>/` (`TFRMNFR1`), or declaring `count`/`for_each` on a submodule's primary resource.
- **Adding a new interface (locks, diagnostic settings, role assignments, etc.) without re-using `Azure/avm-utl-interfaces/azure`**. See [interfaces.md](references/interfaces.md).
- **Using the legacy `diagnostic_settings` shape** instead of the v2 schema. The utility module's `diagnostic_settings_v2` input is the required entry point.
- **Omitting `retry`, `timeouts`, or `resource_types` from an `azapi_resource`** — or failing to cascade them unchanged into submodules. All three are MUST-level AVM interfaces.
- **Treating `timeouts` as an attribute.** It is a block; use `dynamic "timeouts"` so the `null` default works.
- **Skipping `./avm pre-commit` before commit, or `./avm pr-check` after commit.** Both are mandatory.

## Specifications

The canonical source of every AVM rule is the spec index:

- **Index of all specs and docs:** <https://azure.github.io/Azure-Verified-Modules/llms.txt>
- **Rendered docs site:** <https://azure.github.io/Azure-Verified-Modules/>

Fetch `llms.txt` first, locate the raw markdown URL for the spec ID you care about, then fetch that markdown. Do not hard-code spec URLs into module source.
