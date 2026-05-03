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

module "initiative_security_baselines" {
  source = "../../modules/initiatives/security-baselines"

  management_group_id        = local.management_group_id
  shared_key_policy_id       = module.policy_deny_shared_key_access.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
}

module "assignment_security_baselines" {
  source = "../../modules/assignments/security-baselines"

  management_group_id        = local.management_group_id
  initiative_id              = "/providers/microsoft.management/managementgroups/mg-governance-lab-prod/providers/Microsoft.Authorization/policySetDefinitions/${module.initiative_security_baselines.name}"
  log_analytics_workspace_id = var.log_analytics_workspace_id
}
