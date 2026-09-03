---
name: avm-tf-classifications
description: Use this skill whenever a contributor is deciding what KIND of Azure Verified Module to build in Terraform — resource module, pattern module, or utility module — or is naming a module / GitHub repo / Terraform Registry entry. Covers the three module classes, the criteria that separate them ("single resource only" vs "opinionated multi-resource solution" vs "shared logic"), the naming conventions per class (`avm-res-`, `avm-ptn-`, `avm-utl-`), and the corresponding GitHub repo name (`terraform-azure-avm-<class>-<name>` for new modules; `terraform-azurerm-avm-<class>-<name>` for legacy ones). Trigger on phrases like "resource module vs pattern module", "what class is this", "how do I name my AVM module", "wrapper module", "single resource", "multi-resource", "utility module", "avm-res-", "avm-ptn-", "avm-utl-".
---

# AVM module classifications & naming (Terraform)

Every AVM module is exactly one of three classes. The class drives the naming convention, the repo name, the spec set that applies, and the review process.

Classification does not change the provider rule. Every new resource, pattern, or utility module repository that deploys Azure resources MUST use AzAPI for every control-plane and supported direct Azure operation. Each permitted `azurerm_*` resource or data-source block must independently implement one specific unsupported data-plane/non-ARM operation, document the exact block and AzAPI gap with an upstream AzAPI issue or pull request, and be replaced when support ships. One valid block does not authorize another.

Fetch <https://azure.github.io/Azure-Verified-Modules/llms.txt> and confirm the current versions of these sources:
- <https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/module-classifications.md>
- [RMNFR1 — Resource Module Naming](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/resource/non-functional/RMNFR1.md)
- [PMNFR1 — Pattern Module Naming](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/pattern/non-functional/PMNFR1.md)
- [RMFR1 — Single Resource Only](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/resource/functional/RMFR1.md)
- [RMFR2 — No Resource Wrapper Modules](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/resource/functional/RMFR2.md)

## The three classes

### Resource module (`avm-res-`)

Deploys **a single instance of one primary Azure resource** ([RMFR1](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/resource/functional/RMFR1.md)) — e.g. one Key Vault, one Storage Account, one Search Service — plus the standard cross-cutting interfaces (lock, RBAC, diagnostic settings, private endpoints, etc. — see `avm-tf-interfaces`) and child resources that don't add value as standalone modules.

The primary resource MUST be implemented with AzAPI. Do not create a new AzureRM-based resource module.

> If a consumer needs N instances of the resource, they call the module N times. The module itself never loops over the primary resource.

**Must add value over raw `azapi_resource`** ([RMFR2](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/resource/functional/RMFR2.md)) — usually via the standard interfaces, validation, and sensible WAF-aligned defaults. If your module is a thin wrapper that just passes inputs through to a single `azapi_resource`, you don't have a resource module — you have a useless module.

### Pattern module (`avm-ptn-`)

Deploys an **opinionated multi-resource solution** to a recurring problem — e.g. "hub-and-spoke landing zone", "AKS baseline", "AI Foundry workspace with all dependencies". Pattern modules compose resource modules ([TFFR1](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/terraform/shared/functional/TFFR1.md) — Cross-Referencing Modules requires them to consume AVM resource modules where available rather than re-implementing).

If a resource module doesn't exist for a resource the pattern needs, the pattern owner **MUST** log an issue on the central AVM repo requesting it ([PMNFR4](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/pattern/non-functional/PMNFR4.md)).

Any control-plane resource implemented directly in a pattern module MUST use AzAPI. The absence of an AVM resource module is not permission to use AzureRM.

### Utility module (`avm-utl-`)

Provides **shared logic with no resource deployments of its own**, or rarely with a single supporting resource (e.g. a deployment script). Today the canonical example is [`avm-utl-interfaces`](https://registry.terraform.io/modules/Azure/avm-utl-interfaces/azure/latest) — the variable schemas for the standard cross-cutting interfaces. Utility modules are introduced gradually and the specifications around them are still maturing.

If a utility module deploys a supporting control-plane Azure resource, that resource MUST use AzAPI.

If a utility module deploys no resources, telemetry collection **MUST NOT** be added ([SFR3](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/shared/functional/SFR3.md)).

## Decision tree

```
Are you deploying Azure resources?
  ├─ No → utility module (avm-utl-)
  └─ Yes
       ├─ Exactly one primary resource (+ standard interfaces + child resources)?
       │    └─ Yes → resource module (avm-res-)
       └─ Multiple primary resources composed into a solution?
            └─ Yes → pattern module (avm-ptn-)
```

If you find yourself wanting to deploy "a Key Vault AND a Storage Account" as one module, that's a pattern module composing two resource modules — not a single resource module.

## Naming conventions

### Module name (used in the Terraform Registry and in the proposal issue)

| Class | Format | Example |
|---|---|---|
| Resource | `avm-res-<resource provider>-<ARM resource type>` | `avm-res-keyvault-vault`, `avm-res-search-searchservice`, `avm-res-compute-virtualmachine` |
| Pattern | `avm-ptn-<short pattern name>` | `avm-ptn-aks-production`, `avm-ptn-alz-management` |
| Utility | `avm-utl-<utility name>` | `avm-utl-interfaces`, `avm-utl-types` |

Notes on the resource segment:

- `<resource provider>` is the **lowercased and trimmed** ARM provider name — `Microsoft.KeyVault` → `keyvault`, `Microsoft.Storage` → `storage`, `Microsoft.Search` → `search`.
- `<ARM resource type>` is the **lowercased and singular-ish** resource type — `vaults` → `vault`, `storageAccounts` → `storageaccount`, `searchServices` → `searchservice`, `virtualMachines` → `virtualmachine`.
- For sub-resources that warrant their own module: `avm-res-keyvault-vault-key`, `avm-res-storage-storageaccount-blob`. But sub-resources within a single resource module live under `modules/` ([TFRMNFR1](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/terraform/resource/non-functional/TFRMNFR1.md)) — not every child resource becomes its own AVM module.

### GitHub repo name (in the `Azure` org)

The repo name **prefixes the module name with `terraform-azure-`** ([RMNFR1](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/resource/non-functional/RMNFR1.md)). The `<provider>` segment is a legacy Terraform Registry requirement; the spec now fixes it to `azure` for **new** modules — even though AVM Terraform modules use AzAPI:

| Class | Repo |
|---|---|
| Resource | `terraform-azure-avm-res-<rp>-<type>` — e.g. `terraform-azure-avm-res-storage-storageaccount` |
| Pattern | `terraform-azure-avm-ptn-<name>` — e.g. `terraform-azure-avm-ptn-aks-production` |
| Utility | `terraform-azure-avm-utl-<name>` — e.g. `terraform-azure-avm-utl-interfaces` |

This expands to the Terraform Registry source string `Azure/avm-res-<rp>-<type>/azure` (the `/azure` suffix is the Registry's "provider" namespace, fixed by convention even though the module's code uses AzAPI).

> **Legacy note.** Most existing repos are still named `terraform-azurerm-avm-*` with an `Azure/avm-res-.../azurerm` Registry source — RMNFR1 changed the required `<provider>` segment from `azurerm` to `azure`, and the bulk of published modules pre-date the change. Keep an existing module's published name/source as-is; use `azure` only for **new** modules. The template repo itself remains `terraform-azurerm-avm-template`.

### Primary resource name in code

Inside a new module, the primary `azapi_resource` **MUST** be named `this` ([TFRMNFR2](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/terraform/resource/non-functional/TFRMNFR2.md)):

```hcl
resource "azapi_resource" "this" {
  type      = var.resource_types.search_search_services
  parent_id = var.parent_id
  name      = var.name
  location  = var.location
  body      = { properties = { ... } }

  ignore_body_changes    = length(var.ignore_body_changes.search_search_services) > 0 ? var.ignore_body_changes.search_search_services : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
```

When maintaining a pre-existing AzureRM module, keep its existing primary resource label `this` until migration. Do not copy that legacy implementation into a new module.

## Common pitfalls

- **Treating "I want to deploy 5 VMs" as a resource module.** It isn't — RMFR1 requires single-resource. Call a `avm-res-compute-virtualmachine` module 5 times, or write a pattern module if there's reusable orchestration.
- **Inventing a new naming convention.** The repo name `terraform-azure-avm-...` is mechanical — don't substitute `terraform-azapi-avm-...` "because we're using AzAPI now". The Registry-side convention is fixed.
- **Treating the Registry namespace as provider selection.** A legacy `/azurerm` Registry source identifies an existing published module; it does not allow a new module to use AzureRM as its primary provider.
- **Using AzureRM for supporting resources.** Examples, tests, fixtures, and E2E setup use AzAPI for control-plane dependencies even when AzureRM would be easier. Every AzureRM block must independently satisfy the unsupported data-plane/non-ARM exception.
- **Adding a primary-resource `name` default.** Resource modules **MUST NOT** default the primary resource's name ([RMNFR2 / SNFR25](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/shared/non-functional/SNFR25.md)) — the consumer must always supply it. Defaults *are* permitted (and required) for the standard-interface child resources like `pep-<name>`.
- **Forgetting that pattern modules consume resource modules.** A pattern that re-implements a Key Vault inline instead of using `avm-res-keyvault-vault` violates TFFR1.
