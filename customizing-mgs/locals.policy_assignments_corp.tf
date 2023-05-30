locals {
  policy_assignments_to_add_corp = {
    new_assignment = local.policy_assignment_new_assignment
    # new-other-assignment - showing simpler example without optional features
    new_other_assignment = local.policy_assignment_new_other_assignment
  }
}
