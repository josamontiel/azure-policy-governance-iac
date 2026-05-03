variable "log_analytics_workspace_id" {
  description = "The full resource ID of the Log Analytics workspace for diagnostic settings forwarding."
  type        = string
  sensitive   = true
}
