---
name: avm-tf-lifecycle
description: Use this skill whenever an Azure Verified Module (AVM) is being proposed, approved, published, handed over to a new owner, orphaned, or deprecated — and whenever a contributor is choosing a version number for a Terraform AVM module release. Covers the four lifecycle stages (Proposed, Available, Orphaned, Deprecated), the 0.x.y pre-GA versioning rule that applies to ALL AVM modules right now, and the support obligations that come with module ownership. Trigger this skill on phrases like "propose an AVM module", "what version should I publish", "1.0.0", "GA", "deprecate this module", "module orphaned", "new owner", "handover", "release notes", "AVM lifecycle".
---

# AVM module lifecycle (Terraform)

Every Azure Verified Module moves through four lifecycle stages. This skill teaches what each stage means, what the contributor's obligations are at each stage, and the version-numbering rule that constrains releases at every stage.

Authoritative source: <https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/module-lifecycle.md>

## The four stages

```
   Proposed ──✅──► Available ──orphaned──► Orphaned ──end of life──► Deprecated
       │                  ▲                      │
       │                  └──── new owner ───────┘
       ❌
   Rejected
```

### 1. Proposed

The starting point for every new module. A contributor (anyone — Microsoft FTE or community) submits a **module proposal issue** in the central [AVM repository](https://github.com/Azure/Azure-Verified-Modules) using <https://aka.ms/AVM/ModuleProposal>.

The proposal **MUST** include:

- module name (following the [naming convention](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/resource/non-functional/RMNFR1.md) — see `avm-tf-classifications`)
- language (Terraform)
- module class (resource, pattern, or utility — see `avm-tf-classifications`)
- module description
- module owner(s), if known (must be a Microsoft FTE — see `avm-tf-process`)

The AVM core team reviews the proposal. If accepted → Available. If rejected → the issue is closed and the lifecycle ends.

### 2. Available

The module has been developed, tested, published in the `main` branch and to the Terraform Registry. Consumers can use it in any environment. The module owner is responsible for ongoing maintenance and for responding to issues within the timescales in the [Module Support](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/help-support/module-support.md) page.

**Publishing a new version of an Available module does NOT require a new proposal issue.** Just submit a PR in the module's own repository. PR approval logic depends on owner count — see `avm-tf-process`.

### 3. Orphaned

A module is orphaned when its owner can no longer maintain it and no replacement has been found.

While orphaned:

- The AVM core team provides essential maintenance only (critical bug and security fixes).
- **No new feature development** until a new owner is found.
- An issue is opened on the central AVM repo to track ownership re-assignment.
- The module receives the `Status: Module Orphaned 🟡` label.

The owner is responsible for finding a replacement before leaving, and must give the AVM core team warning. If a new owner is identified the module returns to Available.

### 4. Deprecated

End of life. Either because:

- An orphaned module's deprecation window has elapsed, OR
- The owner has chosen to deprecate (e.g. Azure has retired the underlying resource).

Deprecated modules receive the `Status: Module Deprecated 🔴` label and are removed from active support.

## The 0.x.y versioning rule

**This rule applies to every Available AVM module today.** It is not a choice.

> The AVM framework is not GA (generally available). The CI framework, test automation and specification validation are not fully implemented across all supported languages yet. Hence modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All modules **MUST** be published as a `0.x.y` pre-release version (e.g. `0.1.0`, `0.1.1`, `0.2.0`) until the AVM team provides guidance that publishing `v1.0.0` is allowed.

Source: <https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/contributing/process.md> and [SNFR12](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/shared/non-functional/SNFR12.md).

**Practical implications:**

- The first release of a new module is `0.1.0`, not `1.0.0`.
- Breaking changes bump the **minor** segment (`0.1.0` → `0.2.0`), not the major segment.
- Bug fixes and non-breaking features bump the **patch** segment (`0.1.0` → `0.1.1`).
- **Only the latest released version of a module is supported** ([SNFR12](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/shared/non-functional/SNFR12.md)). If a consumer hits a bug on `0.3.0`, the first triage step is "upgrade to the latest version".
- Release notes **MUST** call out breaking changes clearly — consumers rely on these to decide whether to upgrade.

**Do not propose a `1.0.0` release.** If a user asks for one, explain that the AVM framework itself is not GA and point at the contributing/process page. The 0.x.y constraint is lifted only when the AVM core team explicitly publishes guidance allowing it.

## Common pitfalls

- **Promising long-term support for an old minor version.** SNFR12 forbids this — owners aren't expected to maintain multiple major release lines.
- **Skipping the proposal issue and publishing a new module repo.** Without an approved proposal the module isn't an AVM module, even if the repo name follows the convention. Pattern modules in particular need the corresponding resource modules to also be proposed/available ([PMNFR4](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/includes/shared/pattern/non-functional/PMNFR4.md)).
- **Treating "Orphaned" as a soft state.** It blocks all feature work until a new owner takes over — be explicit about this when planning a contribution to an orphaned module.

## Handover checklist for a departing owner

1. Identify a replacement owner (Microsoft FTE — see `avm-tf-process`).
2. Hand over context: open issues, in-flight PRs, known consumer pain points, release plans.
3. Update the `avm-module-owners-terraform` Core Identity entitlement.
4. Update the `CODEOWNERS` file in the module's repo (Terraform) and add the new owner to the `-module-owners-` GitHub team (Bicep equivalent — not applicable here, but worth knowing).
5. Notify the AVM core team via the central AVM repo.

If no replacement is found, the module enters Orphaned status — see above.
