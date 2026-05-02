# Top-level composition for the prod management group.
# Modules are wired in as policies, initiatives, and assignments are translated
# from the exported JSON into Terraform.

locals {
  management_group_id = "/providers/Microsoft.Management/managementGroups/mg-governance-lab-prod"
}

module "policy_deny_shared_key_access" {
  source = "../../modules/policies/deny-shared-key-access"

  management_group_id = local.management_group_id
  policy_name         = "3bf4d15f1bd944fc875ce789"
}
