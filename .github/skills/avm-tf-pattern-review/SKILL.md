---
name: avm-tf-pattern-review
description: "Review an existing Azure Verified Modules (AVM) Terraform pattern module against current PTN conventions, implementation behavior, examples, and CI. Use for 'review this AVM pattern module', 'check Terraform AVM conventions', 'is this pattern AVM-ready', or 'audit AVM module compliance'. Read-only by default; verifies mocked test discovery, minimum Terraform compatibility, provider policy, and example wiring. Not a module generator, automatic fixer, or deployment workflow."
metadata:
  author: "Benjamin Van Brussel (@benvbr)"
---

# AVM Terraform Pattern Review

Review a supplied Terraform pattern module using current AVM requirements and reproducible local evidence, without modifying its source or deploying infrastructure.

## Scope and inputs

- Required: an accessible repository or extracted module directory. Accept quoted paths containing spaces and parentheses, including folders outside an open workspace.
- Optional: a commit or comparison baseline, proposed publication target, particular concerns, or a request for a saved report.
- Infer the subject from the conversation when unambiguous. Ask for a path only when it is missing or ambiguous; do not request Azure credentials, a region, or an ARM resource type for a local review.
- Inspect repository instructions and distinguish authored source from downloaded dependencies and pre-existing user changes.
- If the module is actually a resource or utility module, explain the classification mismatch and obtain agreement before changing review scope.

Use this skill for pattern-module code reviews and AVM submission-readiness checks. Do not use it to create modules, repair code automatically, assess deployed Azure resources, or execute a deployment. Hand those tasks to an appropriate workflow after explicit authorization.

## Runtime contract

| Item | Contract |
| --- | --- |
| Runtime | Runtime-neutral, on demand; use the host's current date |
| Sources | Supplied source, local instructions, declared dependencies, current official AVM specifications, relevant upstream release notes |
| Tools | File inspection/search, a terminal when available, and official-document retrieval; discover capabilities before invoking unavailable tools |
| Output | Findings-first chat review, verification results, caveats, and a readiness assessment |
| Allowed side effects | Isolated temporary copies, scoped tool/dependency downloads, and non-sensitive local validation logs |
| Approval gates | Source edits, persistent tool upgrades, authenticated cloud operations, deployment, remote writes, or sharing a report outside the conversation |
| Privacy | Keep source, logs, identities, state, and credentials local; never upload private code to documentation or search services |

Prefer the existing skills/toolchain; do not require a custom test framework or spawn agents unless the user authorizes delegation. A saved report is optional and requires a requested destination. Do not schedule recurring runs or create remote issues automatically.

## Current authority

At invocation time, fetch <https://azure.github.io/Azure-Verified-Modules/llms.txt>, then locate the current pattern specifications and relevant raw normative sections. Record the review date and the source URL for each alleged specification violation. These sources can change; memories and the regression probes below are leads, not frozen policy.

- [Terraform pattern specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/ptn/)
- [Terraform composition](https://azure.github.io/Azure-Verified-Modules/contributing/terraform/composition/)
- [Contribution flow and test tiers](https://azure.github.io/Azure-Verified-Modules/contributing/terraform/contribution-flow/)
- [TFLint rules and applicability](https://azure.github.io/Azure-Verified-Modules/contributing/terraform/tflint-rules/)
- [Provider policy: TFFR3](https://azure.github.io/Azure-Verified-Modules/spec/TFFR3/)
- [Provider declarations: TFNFR26](https://azure.github.io/Azure-Verified-Modules/spec/TFNFR26/)
- [Telemetry: SFR3](https://azure.github.io/Azure-Verified-Modules/spec/SFR3/)

Follow specific specification links only when needed to adjudicate a candidate finding. Read normative text, not just a summary table, lint rule name, or search excerpt. Separate MUST violations, SHOULD recommendations, functional defects, and verification gaps. If documentation is unavailable, finish a source-based review but label current-policy conclusions unverified.

Load only the relevant existing skills, such as `avm-tf-classifications`, `avm-tf-azapi`, `avm-tf-testing`, and `avm-tf-tflint`. Their implementation, tool-update, and release sequences do not authorize source changes, hooks, or cloud operations during a read-only review.

## Bounded review loop

Use an observe-decide-check loop because each result determines the next useful check.

Maintain a compact evidence ledger with: target and source baseline; module classification; scope inventory; specification URLs and applicability; candidate finding with file and line; falsifiable hypothesis; discriminating check; tool/version/exit status; warnings and test counts; disposition; remaining coverage gaps.

- Maximum 12 review iterations, excluding a blocking user response. Each iteration must verify or dismiss a candidate, complete a coverage category, or record a concrete blocker.
- Default executable budget: 12 scope/version combinations. Inspect the complete first-level inventory; prioritize the root, behavior-owning submodules, and affected examples for execution. Report any untested scopes.
- Research budget: the specification index and three primary specification/composition/contribution pages plus at most eight targeted rule or upstream pages. Stop searching once the controlling path and discriminating check are known.
- Retry a failed tool operation once only when a specific correction is available. Do not retry deterministic source failures or weaken a rule to obtain a pass.
- Independent read-only observations may run together. Keep scratch preparation, dependency initialization, and check execution as separate primary actions; do not batch unrelated writes.
- At the budget limit, return a clearly partial review with outstanding checks, rather than silently expanding scope or claiming full compliance.

| Observation | Next action | Disposition |
| --- | --- | --- |
| Target inaccessible or wrong classification | Ask one focused question | Blocked until clarified |
| Plausible defect with an owning path | Run the cheapest safe check that could disprove it | Confirm, dismiss, or mark inferred |
| Green command with warnings or zero discovered tests | Inspect diagnostics and discovery counts | Do not equate exit zero with compliance or coverage |
| Check needs credentials, live providers, hooks, or deployment | Stop that check and request scoped authorization only if needed | Continue other safe checks; record unverified scope |
| Tool missing or outdated | Use a trusted temporary installation when supported, otherwise state the limitation | No persistent upgrade without approval |
| Requirements and meaningful risks addressed | Assemble the evidence ledger into the review | Complete |

## Review procedure

### 1. Anchor the review

Read the root provider requirements, implementation, variable and output contracts, then the specific child module that controls behavior. Inventory direct submodules, nested module roots, examples, tests, workflows, lint overrides, and documentation configuration.

Do not spend the whole review mapping the repository. For each candidate, identify an owning expression, a concrete failure condition, and one cheap check before taking another exploratory hop. Never edit source merely to investigate a review finding.

Record the original source baseline using Git status/diff when available or a file digest manifest otherwise. An extracted archive without Git is still a valid review target; do not invent branch, release, or CI history.

### 2. Apply pattern-specific rules

- Check each rule's language, class, scope, severity, and lifecycle applicability. Do not demand a single root `resource_id`, a universal `parent_id`, or every resource-module interface merely because a pattern composes Azure resources.
- Review AVM dependency sources, version pins, direct provider declarations, and permitted native resources separately. A published registry source ending in `/azurerm` is not itself a direct AzureRM declaration or a violation.
- Check the current AzAPI policy for authored control-plane resources, including examples and fixtures. Microsoft-maintained providers such as Fabric can be valid for patterns. Judge a dependency's implementation separately from code owned by the reviewed repository.
- Do not add or remove a provider blindly: distinguish a provider requirement from a provider configuration, required aliases, default inheritance, test mocks, and direct resource/function usage. Trace any claimed exception to current policy and an actual unsupported operation.
- Inspect lint overrides as evidence of exceptions, not proof of compliance. Evaluate version constraints correctly: `~> 0.3` permits 0.4.0, whereas `~> 0.3.0` does not. A newer provider release does not alone justify disabling an official rule.
- Check flat module/example layout and compare the inventory with the scopes the AVM runner discovers. A nested scope omitted by lint is not a passing scope.
- Apply AzAPI `resource_types`, `retry`, `timeouts`, and `ignore_body_changes` rules at the scope that directly owns supported managed resource blocks. Recheck current TFFR6/TFFR7/TFFR8 applicability; declarations, data sources, or child resources alone do not automatically impose every interface on a composition-only parent.
- Review telemetry implementation, disclosure, opt-out propagation, preview gates, generated documentation, examples, and publication readiness.
- Do not infer repository permissions or approval settings from CODEOWNERS. Owner registration, access packages, branch protections, registry publication, and successful remote CI require independent evidence.

### 3. Trace behavioral contracts

Follow important inputs from an example through the root object type, locals, child inputs, and the resource or pinned dependency that consumes them.

Prioritize optional branches and defaults that ordinary validation can miss:

- Diagnostic categories, destinations, enabled flags, retention, and renamed fields.
- Locks, customer-managed keys, managed identities, RBAC, and telemetry toggles.
- Private endpoints, DNS, inbound lockdown readiness, outbound policy, and provider subscription/tenant selection.
- Stable map keys, optional/null values, ignored inputs, and combinations that are validated but never exercised.
- Dependency outputs that remain unknown during planning or need propagation after creation.

Terraform object conversion can discard unexpected attributes and substitute optional defaults. Passing `terraform validate` therefore does not prove that an example actually configures diagnostics or security settings. Exercise the exact example input shape with mocked providers where safe.

For every advertised Terraform version floor, inspect compatibility-sensitive expressions and dependencies. Do not assume `object == null || object.attribute ...` short-circuits safely on every supported version; test the exact null case on the advertised minimum. A fix in a local expression does not repair similar guards in input validation or upstream modules.

### 4. Run safe, scoped checks

Prepare a disposable copy outside the source directory. Exclude live state, saved plans, credential files, environment files, and provider caches; preserve relevant committed configuration, lock files, and approved non-sensitive fixtures. Keep review logs and downloaded tooling outside the configuration tree so they cannot alter scope discovery.

Inspect the executable surface before running anything: tests, alternate test modules, provider mocks, provisioners, external data sources, setup hooks, and custom lint/plugin configuration. Mocked providers do not make arbitrary scripts or provisioners safe. Reject mixed live/mock suites for the default review.

Use PowerShell 7.4 or later with the supported `Avm.Authoring` toolchain; do not substitute retired repository launchers, Make, Porch, or container workflows. Before invoking a managed command, verify which scopes and hooks it will execute. If `avm test unit` would run `tests/unit/setup.ps1`, or `avm lint` would run an example's `tflint-pre.ps1`, do not run that command without scoped authorization. Use safe direct checks where possible and report the managed gate as unverified; do not silently delete hooks to manufacture a passing result.

Use the existing toolchain and capture versions, exit codes, warning details, discovered scopes, and actual test counts:

1. `terraform fmt -check -recursive` without write mode.
2. `terraform init -backend=false -input=false` in the disposable copy only.
3. `terraform validate` for the root and selected independently consumable scopes.
4. Existing, inspected, fully mocked tests. AVM unit suites belong under `tests/unit` at the root or within a direct submodule. Plain `terraform test` discovers loose `tests/*.tftest.hcl`; use `terraform test -test-directory=tests/unit` for the unit tier rather than assuming recursive discovery.
5. `avm test unit` with the current supported Avm.Authoring version, subject to the hook gate above. Compare discovered tests with the source inventory.
6. `avm lint` using the supported invocation and the repository's real overrides, subject to the hook gate above. Record diagnostics even if the command returns zero.
7. The cheapest relevant mocked test on the advertised minimum Terraform version, not only on the CI-pinned version. Keep the alternate binary temporary and verify its official checksum.
8. One focused reproduction for each remaining high-impact candidate, using existing fixtures, command-line test inputs, or syntax-only checks in the disposable copy. Do not create a parallel test framework.

Use an absolute `-Path` for managed commands targeting the disposable module and `-Ecosystem terraform` when context detection is ambiguous. Capture structured results with `--passthru` where supported. Managed command failures throw; `$LASTEXITCODE` alone is not evidence of success for PowerShell commands.

Initialize/cache approved dependencies once where practical. Obtain tools only from trusted upstream publishers and verify published checksums when provided. If Avm.Authoring refuses an outdated installation, save/import the supported version in temporary storage instead of upgrading the user's installation. Create its destination before package-saving commands that require an existing directory.

Never run `terraform apply`, `terraform destroy`, state mutations, integration tests, E2E tests, or repository hooks during the default review. An inspected mocked `terraform test` run with `command = apply` is distinct from a live apply, but only run it after verifying the complete execution surface.

`avm pr-check` is NOT an offline check: its policy checks create example plans and require Azure credentials. Do not run it, `avm check policy`, a live `terraform plan`, or authenticated cloud diagnostics without explicit scope approval. `avm pre-commit` changes files; never run it against the supplied source as part of a read-only review.

### 5. Audit CI and examples

- Verify unit-tier locations, scope discovery, test counts, and minimum-version coverage. An installed job that skips all tests is a coverage defect even if another job runs plain Terraform tests.
- Check whether standard example plans receive every required input through fixtures, environment variables, variable files, or appropriate hooks. Inputs supplied only to a separate manual workflow do not satisfy the normal PR-check path.
- Distinguish static wiring defects from unverified external configuration. Inspect all input channels before concluding a workflow cannot run.
- Inspect E2E approval gates, identity configuration, cleanup strategy, state recovery, and idempotency checks without executing them. `if: always()` attempts cleanup; it cannot guarantee no resources remain after a failed destroy or cancelled runner.
- Look for secrets or JSON interpolated directly into shell source. An apostrophe-containing JSON string can break a single-quoted command. Use harmless synthetic input with a syntax-only parser to demonstrate the defect, never actual secrets or execution of the generated shell body.
- Recommend environment-variable transport, quoted output, and structured parsers for JSON. Do not generate an executable injection payload.
- Verify the intended telemetry opt-out reaches the root module; an environment variable is ineffective if the example never declares and forwards that input.
- Review generated documentation and preview/support notices. Treat archived lock files and required examples according to current AVM policy, not generic application-repository habits.

### 6. Verify and report

Reconcile the source baseline and disclose any source changes observed without reverting them. Separate original test results from injected reproductions. Never turn a skipped test, a warning-bearing pass, an unexecuted workflow, or a mocked apply into evidence of deployment success.

Retain only actionable findings with a demonstrated consequence or a current applicable requirement. Give each finding a severity, a precise source location, the trigger/impact, evidence status, and a minimal remediation. Cite the governing rule for convention findings. Keep recommendations and publication prerequisites separate from confirmed runtime defects.

## Regression probes

These are reusable probes, not findings to copy into another repository. Re-establish each observation for the current target rather than freezing a past module, tool version, or test total.

| Probe | Discriminating evidence |
| --- | --- |
| Minimum-version compatibility | Run the same null-input case on the current and advertised minimum Terraform versions; inspect local and dependency guards separately |
| Diagnostic schema drift | Exercise the exact example input shape with mocks to detect obsolete fields discarded by object conversion |
| AVM unit discovery | Compare source suites with actual managed-runner discovery and pass/fail/skip counts; exit zero with no runs is not coverage |
| Nested module roots | Compare lint discovery with actual Terraform roots to expose omitted nested scopes |
| Provider-policy warnings | Record both the overall lint status and individual provider-policy diagnostics |
| E2E JSON quoting | Parse, without executing, a synthetic shell step containing valid JSON with an apostrophe |

## Output format

Start with findings ordered by severity. Keep the normal review concise, approximately 50-70 lines maximum, and combine related instances rather than listing repetitive warnings.

For each finding use:

**[Severity] Specific defect or convention gap** - source file and line. State when it fails, why it matters, whether it is reproduced/observed/inferred, the relevant specification if applicable, and the smallest practical correction.

Then provide:

1. **Assumptions and limits:** unavailable documentation, inaccessible repository settings, untested scopes, and cloud checks not authorized.
2. **Verification:** commands, scopes, versions, actual pass/fail/skip counts, and significant warnings. Distinguish source defects from environment/tooling failures.
3. **Assessment:** ready for the next review gate, not ready, or partial review; do not certify official AVM verification. Mention material strengths briefly and state whether source files were changed.

If there are no findings, say so explicitly while preserving residual risks and test gaps. Use resolvable local file references where the runtime supports them; outside a workspace, identify the supplied review root and give unambiguous module-relative file/line references rather than claiming broken links are clickable.

## Exit conditions

- **Complete:** bounded review finished, meaningful findings verified, and remaining required deployment/publication gates clearly named.
- **No-op:** no matching Terraform pattern module was supplied; no files or systems changed.
- **Blocked:** target unreadable or essential clarification unanswered; explain the specific next input needed.
- **Approval declined:** omit the requested gated action, keep the review read-only, and return available evidence.
- **Partial:** tools, current sources, credentials, scope budget, or execution safety prevented full coverage; list what was and was not checked.
- **Error:** a safe targeted retry failed; report that check as unavailable and finish any independent safe work.

Every exit ends with a self-contained user-facing response. Do not continue work indefinitely or claim a gate passed without its evidence.

## Runtime adaptation notes

- Install using the host's repository-local skill conventions; no absolute user paths belong in the workflow.
- On Windows, distinguish Windows file-tool paths from WSL terminal paths and quote paths with spaces. Use the detected shell rather than assuming Bash syntax works in PowerShell.
- Use synchronous execution for one-shot checks. If execution becomes asynchronous, follow the host's completion notifications; do not poll, sleep, or launch a duplicate while the first command may still run.
- Missing, truncated, or replayed terminal output is not a success signal. Use bounded logs and explicit exit status; summarize only the current command's evidence.
- Without terminal access, perform a static review and label every executable gate unverified. Without current documentation, do not claim current AVM compliance.

Invocation example: `/avm-tf-pattern-review <module-folder>`.
