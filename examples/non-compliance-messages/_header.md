# Non-Compliance Messages

This example shows how to configure non-compliance messages for policy assignments.

It demonstrates two complementary mechanisms:

1. A global **default non-compliance message** applied by the `alz` provider via the `policy_assignment_non_compliance_message_settings` variable.
2. **Per-assignment non-compliance messages** (including multiple messages targeting different `policy_definition_reference_id` values within an initiative) using the `policy_assignments_to_modify` variable.

The default message is merged into every policy assignment using the configured `merge_mode` (`replace` or `prefer_existing`). Policy-specific messages (those with a `policy_definition_reference_id`) are always preserved.
