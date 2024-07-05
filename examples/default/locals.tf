# These locals help keep the code DRY
locals {
  default_delays = {
    before_management_group_creation = {
      create = "30s"
    }
    before_policy_assignments = {
      create  = "300s"
      destroy = "120s"
    }
    before_policy_role_assignments = {
      create  = "60s"
      destroy = "60s"
    }
  }
  default_location = "westus2"
}
