variable "harbor_registry_mode" {
  description = "Harbor registry mode: CORE or REPLICA"
  type        = string
  default     = "CORE"

  validation {
    condition     = contains(["CORE", "REPLICA"], var.harbor_registry_mode)
    error_message = "Harbor registry mode must be either 'CORE' or 'REPLICA'."
  }
}

variable "harbor_core_hostname" {
  description = "Hostname of the CORE Harbor instance (required for REPLICA mode)"
  type        = string
  default     = null

  validation {
    condition     = var.harbor_registry_mode == "REPLICA" ? var.harbor_core_hostname != null : true
    error_message = "harbor_core_hostname is required when harbor_registry_mode is 'REPLICA'."
  }
}

variable "GOOGLE_OIDC_CLIENT_ID" {
  description = "Google OIDC Client ID for authentication"
  type        = string
}

variable "GOOGLE_OIDC_CLIENT_SECRET" {
  description = "Google OIDC Client Secret for authentication"
  type        = string
  sensitive   = true
}
