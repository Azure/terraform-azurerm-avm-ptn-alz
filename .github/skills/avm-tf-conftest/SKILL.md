---
name: avm-tf-conftest
description: Use whenever an AVM Terraform task involves Conftest, OPA, Rego, APRL, AVMSEC, policy findings, policy exceptions, or files under an example exceptions directory. Covers current policy identifiers, example-local exception placement, package names, and managed policy validation. Trigger on "conftest", "rego", "APRL", "AVMSEC", "policy failure", "policy exception", "deny_", and "avm check policy".
---

# AVM Terraform Conftest

Use Conftest through `Avm.Authoring`. Fix the planned configuration instead of adding an exception unless the policy genuinely does not apply to the example.

## Read current sources first

Before diagnosing a finding or adding an exception:

1. Read the current [AVM OPA and Conftest policy exception guidance](https://azure.github.io/Azure-Verified-Modules/contributing/terraform/advanced/#opa-conftest-policy-exceptions).
2. Read the current [`Azure/policy-library-avm` documentation](https://github.com/Azure/policy-library-avm/blob/main/readme.md).
3. Locate the reported policy in `Azure/policy-library-avm` and confirm its package, exact `deny_` identifier, provider implementation, and expected behavior.
4. Check the planned values that caused the finding before deciding that the rule is inapplicable.

Do not copy an exception from another module without verifying the current rule source and the example's plan.

## Run the managed policy check

```pwsh
Import-Module Avm.Authoring
avm version
avm check policy
```

`avm check policy` creates plans for examples and evaluates both Azure Proactive Resiliency Library (APRL) and AVM Security (AVMSEC) policies through Conftest. It requires Azure credentials for plan generation. The full clean-worktree gate also runs policy checks:

```pwsh
avm pr-check
```

If the version gate reports a stale installation, run `avm update`, re-import the module, and retry. Do not replace the managed command with a separately installed Conftest binary or a hand-built policy checkout.

## Exception location and scope

Place exception files in the failing example:

```text
examples/<example-name>/exceptions/<descriptive-name>.rego
```

An exception in this directory applies only while evaluating that example. Use a descriptive filename and keep different Rego packages in separate files.

Every exception must:

- name only the policy identifiers that are genuinely inapplicable;
- explain why the example cannot or should not comply;
- link an issue or authoritative source when the exception is temporary or depends on an upstream limitation; and
- remain narrower than excluding the example from policy or E2E validation.

Never use an empty rule identifier. Conftest treats it as an exception for unqualified `deny` or `violation` rules. Do not exclude an entire policy family merely to make the check pass.

## APRL exceptions

APRL policies use the `Azure_Proactive_Resiliency_Library_v2` package. The exception identifier is the suffix of the policy's `deny_<identifier>` rule:

```rego
package Azure_Proactive_Resiliency_Library_v2

import rego.v1

# The service does not support zones in the region used by this example.
exception contains rules if {
  rules = ["configure_aks_default_node_pool_zones"]
}
```

Do not include the `deny_` prefix in `rules`.

## AVMSEC exceptions

AVMSEC policies use the `avmsec` package. Findings and policy source identify rules with names such as `deny_AVM_SEC_137`; use the suffix without `deny_`:

```rego
package avmsec

import rego.v1

# AVM_SEC_137 does not apply for the documented reason tracked in <issue-url>.
exception contains rules if {
  rules = ["AVM_SEC_137"]
}
```

The policy library exposes severity collections such as `rules_below_high` and `rules_below_medium`. Do not use those broad collections for a normal module example exception; list exact policy identifiers so unrelated security checks remain active.

## Validate the result

After adding or changing an exception:

1. Run `avm check policy`.
2. Confirm the intended finding is reported as an exception rather than silently disappearing.
3. Confirm no unrelated APRL or AVMSEC findings were suppressed.
4. Review whether the example can be changed to remove the exception.

Conftest reports exceptions separately from passes, warnings, and failures. Treat that exception count as review evidence, not as a clean-policy result.
