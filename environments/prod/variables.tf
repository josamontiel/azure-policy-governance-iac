variable "log_analytics_workspace_id" {
  description = "The full resource ID of the Log Analytics workspace for diagnostic settings forwarding."
  type        = string
  sensitive   = true
}

variable "public_network_access_effect" {
  description = "Effect for the public network access policy. Flipped from Audit to Deny in Phase 5 after audit data triage."
  type        = string
  default     = "Deny"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.public_network_access_effect)
    error_message = "public_network_access_effect must be one of: Audit, Deny, Disabled."
  }
}
