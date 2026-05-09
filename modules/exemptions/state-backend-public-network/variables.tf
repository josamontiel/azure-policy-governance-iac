variable "exemption_name" {
  description = "Internal name of the exemption (used in resource IDs). Lowercase, no whitespace."
  type        = string
  default     = "exempt-state-backend-public-network"
}

variable "display_name" {
  description = "Human-readable display name shown in the Azure portal."
  type        = string
  default     = "State Backend Public Network Access — Time-Bound Waiver"
}

variable "description" {
  description = "Justification for the exemption. Should name an owner or ticket and explain why the resource cannot be made compliant."
  type        = string
}

variable "scope_id" {
  description = "The full resource ID of the resource being exempted (e.g. the storage account)."
  type        = string
}

variable "policy_assignment_id" {
  description = "The full resource ID of the policy assignment that includes the policy this exempts from."
  type        = string
}

variable "policy_definition_reference_ids" {
  description = "List of reference IDs (within the initiative) of the policies being exempted. Empty list exempts from the entire assignment."
  type        = list(string)
  default     = []
}

variable "exemption_category" {
  description = "Category of exemption — Waiver (accepted risk) or Mitigated (alternative control in place)."
  type        = string
  default     = "Waiver"
  validation {
    condition     = contains(["Waiver", "Mitigated"], var.exemption_category)
    error_message = "exemption_category must be either 'Waiver' or 'Mitigated'."
  }
}

variable "expires_on" {
  description = "ISO 8601 timestamp at which the exemption expires. No open-ended waivers — must be set."
  type        = string
}

variable "metadata" {
  description = "Free-form metadata attached to the exemption. Use for ticket references, review dates, etc."
  type        = map(string)
  default     = {}
}
