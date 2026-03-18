---
name: AVM-Terraform-Development
description: Azure Verified Modules (AVM) Terraform development workflow for fixing issues and adding features
glob: "**/*.terraform,**/*.tf,**/*.tfvars,**/*.tfstate,**/*.tflint.hcl,**/*.tf.json,**/*.tfvars.json"
---

# Azure Verified Modules (AVM) Terraform

Azure Verified Modules (AVM) are pre-built, tested, and validated Terraform and Bicep modules that follow Azure best practices. Use these modules to create, update, or review Azure Infrastructure as Code (IaC) with confidence.

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

All Azure resources MUST be deployed using the **AzAPI provider** (`Azure/azapi`). For AzAPI resource patterns, schema lookups, and the `azure-schema` CLI tool, read [AzAPI.md](AzAPI.md).

To query Terraform provider schemas (resources, data sources, functions, ephemeral resources), use the `tfpluginschema` CLI. See [tfpluginschema.md](tfpluginschema.md).

Make the necessary code changes to add the feature or fix the issue.

### Step 4: Add unit tests (if justified)

Unit tests use **provider mocking** and live in the `tests/unit` directory. Add or update unit tests when your change introduces new logic, variables, or outputs that can be validated without deploying real infrastructure. For test writing guidance, syntax, and patterns, read [terraform-test.md](terraform-test.md).

```bash
PORCH_NO_TUI=1 ./avm tf-test-unit
```

### Step 5: Add integration tests (if justified)

Integration tests do **not** use provider mocking and live in the `tests/integration` directory. Add or update integration tests when your change requires validation against real Azure infrastructure. For test writing guidance, syntax, and patterns, read [terraform-test.md](terraform-test.md).

```bash
PORCH_NO_TUI=1 ./avm tf-test-integration
```

### Step 6: Add or update examples (if justified)

If your change affects module usage or introduces new functionality, add or update examples in the `examples/` directory. Test only the pertinent example:

```bash
PORCH_NO_TUI=1 AVM_EXAMPLE="<ExampleDir>" ./avm test-examples
```

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

- A clear description of what was changed and why
- References to related issues (e.g., `Closes #123`)

## Troubleshooting Test Failures

If any issues arise during testing or PR checks, refer to the official AVM testing documentation:

<https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/contributing/terraform/testing.md>

## Reference

### Code Quality

- Always run `terraform fmt` after making changes
- Always run `terraform validate` after making changes
- Use meaningful variable names and descriptions
- Use snake_case
- Add proper tags and metadata
- Document complex configurations

### Tool Integration

- **AzAPI Provider & Schema Lookup**: See [AzAPI.md](AzAPI.md) for resource patterns and the `azure-schema` CLI tool
- **Terraform Provider Schemas**: See [tfpluginschema.md](tfpluginschema.md) for querying resource, data source, function, and ephemeral schemas from any provider
- **Terraform Tests**: See [terraform-test.md](terraform-test.md) for writing unit and integration tests
- **Deployment Guidance**: Use `azure_get_deployment_best_practices` tool
- **Service Documentation**: Use `microsoft.docs.mcp` tool for Azure service-specific guidance
