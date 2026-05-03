variable "assignment_name" {
  description = "Internal name of the assignment (used in resource IDs). Defaults to the existing GUID for the imported assignment."
  type        = string
  default     = "714e6c7b52c24026a564e78e"
}

variable "display_name" {
  description = "Human-readable display name shown in the Azure portal."
  type        = string
  default     = "Governance Lab Security Baselines"
}

variable "description" {
  description = "Description shown alongside the assignment in the portal and compliance dashboards."
  type        = string
  default     = "Foundational governance baseline for the lab environment. Bundles tag enforcement, regional restrictions, public network controls, and diagnostic settings into a single MG-scoped initiative."
}

variable "management_group_id" {
  description = "The full resource ID of the management group where this assignment will live."
  type        = string
}

variable "initiative_id" {
  description = "The full resource ID of the initiative being assigned. Wired in from the initiative module's output."
  type        = string
}

variable "location" {
  description = "Azure region the assignment is anchored to. Required when a managed identity is attached."
  type        = string
  default     = "eastus"
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
  description = "Effect for the diagnostic settings DINE policy."
  type        = string
  default     = "DeployIfNotExists"
}

variable "public_network_access_effect" {
  description = "Effect for the public network access policy."
  type        = string
  default     = "Audit"
}

variable "non_compliance_message" {
  description = "Message shown to users when their deployment violates the assignment's policies."
  type        = string
  default     = "Resource violates one or more controls in the Governance Lab Security Baselines initiative. Check the Compliance dashboard for details."
}
