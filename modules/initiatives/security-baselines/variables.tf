variable "management_group_id" {
  description = "The full resource ID of the management group where this initiative will live."
  type        = string
}

variable "initiative_name" {
  description = "Internal name of the initiative (used in resource IDs). Defaults to the existing GUID for the imported initiative."
  type        = string
  default     = "4e90b22a2f4c451083a749d4"
}

variable "display_name" {
  description = "Human-readable display name shown in the Azure portal."
  type        = string
  default     = "Governance Lab Security Baselines"
}

variable "description" {
  description = "Description of the initiative shown in the portal and compliance dashboards."
  type        = string
  default     = "Foundational governance baseline for the lab environment. Bundles tag enforcement, regional restrictions, public network controls, and diagnostic settings into a single MG-scoped initiative."
}

variable "shared_key_policy_id" {
  description = "The full resource ID of the custom Deny Shared Key Access policy. Wired in from the policy module output."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The full resource ID of the Log Analytics workspace that diagnostic settings will forward to."
  type        = string
  sensitive   = true
}

variable "allowed_locations" {
  description = "List of Azure regions where resources are permitted to be deployed."
  type        = list(string)
  default     = ["eastus"]
}

variable "required_tag_name" {
  description = "Tag key required on every resource."
  type        = string
  default     = "costCenter"
}

variable "required_tag_value" {
  description = "Tag value required for the required tag."
  type        = string
  default     = "IT"
}

variable "diagnostic_settings_effect" {
  description = "Effect for the diagnostic settings DINE policy. DeployIfNotExists in production, AuditIfNotExists during rollout."
  type        = string
  default     = "DeployIfNotExists"
  validation {
    condition     = contains(["DeployIfNotExists", "AuditIfNotExists", "Disabled"], var.diagnostic_settings_effect)
    error_message = "diagnostic_settings_effect must be one of: DeployIfNotExists, AuditIfNotExists, Disabled."
  }
}

variable "public_network_access_effect" {
  description = "Effect for the public network access policy. Audit during rollout, Deny once the audit data is reviewed."
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.public_network_access_effect)
    error_message = "public_network_access_effect must be one of: Audit, Deny, Disabled."
  }
}
