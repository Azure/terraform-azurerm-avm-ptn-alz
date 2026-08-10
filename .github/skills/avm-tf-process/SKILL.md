---
name: avm-tf-process
description: Use for the AVM Terraform contribution process from module proposal and repository setup through implementation, Avm.Authoring validation, pull request review, and release.
---

# AVM Terraform Contribution Process

Use the current AVM process and specification pages from <https://azure.github.io/Azure-Verified-Modules/llms.txt>. Older public setup pages or module repositories may still contain the retired launcher, Makefile, container, or Porch flow.

## 1. Confirm classification and ownership

Determine whether the work is a resource, pattern, or utility module. Confirm the approved module name and ownership from the AVM indexes and proposal rather than inventing a name.

Before creating or restructuring a repository, read the current requirements for:

- repository naming and visibility;
- owner and AVM team permissions;
- CODEOWNERS;
- branch protection and required checks;
- issue and pull request templates;
- release and publishing; and
- support lifecycle.

## 2. Establish the managed repository baseline

Start from the current AVM Terraform template or governance-managed repository state. Import `Avm.Authoring` and synchronize managed files:

```pwsh
Install-PSResource -Name Avm.Authoring -Repository PSGallery -TrustRepository
Import-Module Avm.Authoring
avm version
avm sync
```

Review synchronized changes before continuing. Do not restore files from the retired Make, Porch, or container workflow.

## 3. Implement from current specifications

Fetch `llms.txt`, then read each applicable raw spec page. At minimum, review:

- module classification and composition rules;
- TFFR3-TFFR8 for AzAPI;
- TFRMFR1 and TFNFR38 for parent and resource IDs;
- TFRMNFR1 and TFRMNFR2 for submodules and resource labels;
- TFNFR39 for file layout;
- standard interfaces and telemetry;
- tests and examples;
- documentation; and
- semantic versioning and breaking changes.

Use the local specialized skills for implementation details, but resolve any conflict in favor of the current published spec.

## 4. Develop on a focused branch

Keep changes scoped and preserve unrelated history. Add or update:

- Terraform implementation and exact types;
- root and submodule tests;
- representative examples;
- `_header.md` and `_footer.md`;
- migration or upgrade-path coverage when state or addresses change; and
- generated README files through `Avm.Authoring`.

Scripts and lifecycle hooks must be PowerShell. Supported hook names include:

- `tests/unit/setup.ps1`;
- `tests/integration/setup.ps1`;
- `examples/<name>/pre.ps1`;
- `examples/<name>/post.ps1`; and
- `examples/<name>/tflint-pre.ps1`.

Do not add shell-hook counterparts.

## 5. Run targeted tests

Choose the smallest tier that proves the change:

```pwsh
avm test unit
avm test integration
avm test e2e --example <example-name>
```

Unit tests mock all required providers. Integration and E2E tests need real Azure authentication. E2E tests must prove deployment, idempotency, and cleanup.

## 6. Apply pre-commit changes

Run:

```pwsh
avm pre-commit
```

For Terraform this performs managed-file sync, fixable convention rules, transforms, formatting, and documentation generation. Review every generated or synchronized change and rerun targeted tests if the generated change affects behavior.

## 7. Commit, then run the full PR gate

Commit the complete worktree before running:

```pwsh
avm pr-check
```

`avm pr-check` requires a clean Git worktree. It checks sync, formatting, transforms, lint, APRL/AVMSEC policy evaluation, conventions, Terraform validation, and documentation. Unit tests remain a separate test tier and CI job; a passing PR check is not a substitute for required unit, integration, or E2E coverage.

## 8. Open and review the pull request

The pull request must explain:

- what changed and why;
- applicable specification IDs;
- compatibility or breaking-change impact;
- state migration steps when addresses or providers changed;
- tests and examples exercised; and
- any narrow AzureRM exception and upstream tracking issue.

Review the final diff rather than only the hand-authored files. Managed and generated outputs are part of the change.

## 9. Release

Follow the current AVM semantic-versioning and publishing process. Confirm:

- the change classification matches the release version;
- generated documentation is current;
- required checks and test tiers passed;
- upgrade notes are included where needed; and
- repository permissions and release automation remain governance-compliant.

Use `Avm.Authoring` throughout. Do not substitute `./avm`, `avm.ps1`, Make, Porch, Docker, Podman, or manually installed pinned tools.
