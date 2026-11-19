---
name: avm-tf-process
description: Use for the AVM Terraform contribution process from module proposal and repository setup through implementation, Avm.Authoring validation, pull request review, fork PR handoffs with avm release-branch, and release.
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

Start from the current AVM Terraform template or governance-managed repository state. Follow the [MAR installation prerequisites](https://github.com/Azure/azure-verified-modules-tools#install) to upgrade PSResourceGet and register MAR once; it is not registered by default. Import `Avm.Authoring` and synchronize managed files:

```pwsh
Install-PSResource -Name avm.authoring `
    -Repository MAR `
    -Scope CurrentUser
Import-Module Avm.Authoring
avm version
avm sync
```

Review synchronized changes before continuing. Do not restore files from the retired Make, Porch, or container workflow.

## 3. Implement from current specifications

Build every new resource-deploying module repository on AzAPI. Do not declare or configure `hashicorp/azurerm`, and do not create any `azurerm_*` resource or data source for control-plane operations, convenience, or ordinary supporting infrastructure in implementation, submodules, examples, E2E configurations, Terraform tests, fixtures, setup or teardown Terraform, migration examples, documentation examples, or generated snippets.

When supporting configuration needs a direct Azure resource that the module under test does not supply, use an AzAPI resource, data source, or action. Each standalone Terraform root that performs direct Azure operations includes `Azure/azapi` in `required_providers`.

Permit `hashicorp/azurerm ~> 4.0` only when required by an independently justified `azurerm_*` resource or data-source block. Each block scopes to one specific unsupported data-plane/non-ARM operation, documents the exact block and why AzAPI cannot implement it with an upstream AzAPI issue or pull request, and is replaced when support ships. Prefer an AVM TFLint override file, but use a justified line-level annotation when it avoids suppressing unrelated findings in the same scope. One valid block does not authorize another. Examples and tests may configure AzureRM only to exercise such blocks. Follow `avm-tf-tflint`.

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
- confirmation that control-plane and supporting resources use AzAPI, plus the evidence and upstream link for any narrow data-plane/non-ARM AzureRM exception.

Review the final diff rather than only the hand-authored files. Managed and generated outputs are part of the change.

Open PRs early, then add `PR: Run Required E2E Tests` when required examples are ready for deployment validation, or `PR: Run All E2E Tests` to include optional examples. This avoids unnecessary cloud cost and runtime during early development. Static PR checks, unit tests, and integration tests run without these labels.

Follow the [testing skill's label and merge-gate guidance](../avm-tf-testing/SKILL.md#pr-deployment-labels-and-merge-gates). The pending public-spec addition [TFNFR42](https://github.com/Azure/Azure-Verified-Modules/pull/3155) requires resource modules to provide executable `examples/defaults/` and `examples/waf-aligned/`; pattern and utility modules require only `examples/defaults/`. WAF-aligned is optional for pattern and utility modules. The exact canonical spelling is `defaults`; `default` remains only migration compatibility.

Existing required examples must run and pass; absent required examples are not yet mandatory. A Terraform composition warning for missing or misplaced canonical examples is advisory before v1 and cannot block merge or release. Do not use `.e2eignore` to satisfy coverage or copy placeholders to clear warnings. Backfill by renaming a suitable existing example; route a missing or ambiguous canonical scenario to the module owner instead of rewriting deployments or fabricating copies.

Required examples cover required and applicable conditional inputs and use module defaults for unrelated optional inputs. Keep location, telemetry, test harness setup, deployment scope, and dependency resources separate from module feature overrides. Terraform submodules need no separate example trees; parent examples must exercise relevant submodule behavior.

A name such as `waf-aligned` does not prove semantic WAF compliance. Use applicable [SFR2](https://github.com/Azure/Azure-Verified-Modules/pull/3155) recommendations to assess the scenario.

Class-aware Required-label selection and the warning-only Terraform composition check are pending Tools/Avm.Authoring behavior, not published functionality. The current shared workflow still discovers existing runnable `default`/`defaults` and `waf-aligned` examples. Confirm selected jobs actually passed rather than treating label presence or skipped tests as success. Fork labels do not grant deployment credentials; use the handoff below when credentialed E2E tests are needed.

### Fork PR release-branch handoff

Credentialed E2E testing of external fork PRs requires a same-repository release branch. Ordinary fork checks do not require this handoff. An authorized Microsoft FTE with write access to the upstream repository must first review all code, workflows, and dependencies on the current fork PR head that could access credentials. Do not infer this review or authorization from labels. Re-review later changes to the release branch before allowing them to use credentials.

Use the MAR-installed `Avm.Authoring` module and the existing authenticated `gh` session for github.com. The upstream repository must be a non-fork with default branch `main`, and the external fork PR must be open and ready for review. Replace `Azure/example` and `123` with the upstream repository and fork PR number:

```pwsh
avm release-branch `
    --repository 'Azure/example' `
    --pull-request 123
```

This command changes GitHub state: it creates `release/fork-pr-<number>-<sha-prefix>` from upstream `main`, retargets the original fork PR, merges its captured head into that release branch, and opens a follow-up PR back to `main`. It does not merge the follow-up, publish a release, approve reviews, or bypass branch protections and required checks. It detects a changed head during handoff but cannot verify which commit a human reviewed. Restrict write access to the release branch.

For Terraform, the command does not add an E2E label automatically. Apply `PR: Run Required E2E Tests` or `PR: Run All E2E Tests` to the follow-up PR when ready, then inspect the selected jobs and merge gates before merging to `main`.

A failure can leave a created branch or a retargeted or merged PR behind. Inspect the original PR, release branch, and any follow-up PR before manual recovery; do not blindly rerun. See the [command reference](https://github.com/Azure/azure-verified-modules-tools/blob/main/docs/reference/Invoke-AvmReleaseBranch.md) for parameters and preview support.

## 9. Release

Follow the current AVM semantic-versioning and publishing process. Confirm:

- the change classification matches the release version;
- generated documentation is current;
- required checks and test tiers passed;
- upgrade notes are included where needed; and
- repository permissions and release automation remain governance-compliant.

Use `Avm.Authoring` throughout. Do not substitute `./avm`, `avm.ps1`, Make, Porch, Docker, Podman, or manually installed pinned tools.
