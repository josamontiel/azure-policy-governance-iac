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
locals {
  state_backend_storage_account_id = "/subscriptions/176786fd-12ee-42f9-bcaa-772f8c3602d6/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/sttfstategovlab20901"
}

module "exemption_state_backend_public_network" {
  source = "../../modules/exemptions/state-backend-public-network"

  scope_id             = local.state_backend_storage_account_id
  policy_assignment_id = module.assignment_security_baselines.id
  policy_definition_reference_ids = [
    "Storage accounts should disable public network access_1"
  ]

  description = "The Terraform state backend storage account requires public network access for management operations from local engineering machines and GitHub-hosted CI runners. Closing public access would require private endpoints, a VNet, and either a jumphost or self-hosted runners — out of scope for the governance lab. Reviewed quarterly. Owner: lab operator."

  expires_on = "2026-11-09T00:00:00Z"

  metadata = {
    owner          = "lab-operator"
    ticket         = "lab-exemption-001"
    review_cadence = "quarterly"
    next_review    = "2026-08-09"
  }
}
