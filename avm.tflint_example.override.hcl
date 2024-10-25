rule "location" {
  enabled = false
}

rule "terraform_comment_syntax" {
  enabled = false
}

plugin "terraform" {
  enabled = true
  version = "0.9.1"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}
