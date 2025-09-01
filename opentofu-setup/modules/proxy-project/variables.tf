variable "project_name" {
  description = "The name of the Harbor project for the proxy cache."
  type        = string
}

variable "registry_provider" {
  description = "The provider of the public registry (e.g., 'docker-hub', 'quay')."
  type        = string
}

variable "registry_endpoint_url" {
  description = "The endpoint URL of the public registry."
  type        = string
}

variable "admin_group_name" {
  description = "The name of the OIDC group to be granted project admin privileges."
  type        = string
}