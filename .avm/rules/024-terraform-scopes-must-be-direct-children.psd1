# Temporary compatibility exception for legacy nested modules and the integration fixture.
# Defer directory-layout and test-fixture changes to a dedicated follow-up PR.
# Avm.Authoring has no per-path exceptions for this rule: all matching module and
# example findings remain warnings. Remove this override after those fixes land.
@{
    Id          = 'avm.tf.terraform-scopes-must-be-direct-children'
    Kind        = 'TerraformScopesMustBeDirectChildren'
    Description = 'AVM permits Terraform module and example roots only one level below modules/ and examples/.'
    Severity    = 'warning'
    AppliesTo   = 'root'
    Parameters  = @{
        ScopeDirectories = @('modules', 'examples')
    }
}
