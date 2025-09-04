# Creates the Harbor project which will serve as the proxy cache.
resource "harbor_project" "default" {
  name                        = var.project_name
  registry_id                 = harbor_registry.default.registry_id
  public                      = true
  vulnerability_scanning      = true
  enable_content_trust        = false
  enable_content_trust_cosign = false
  auto_sbom_generation        = true
}

# Defines the upstream public registry that Harbor will proxy and cache from.
resource "harbor_registry" "default" {
  provider_name = var.registry_provider
  name          = var.project_name # Using project name for consistency
  endpoint_url  = var.registry_endpoint_url
}

# Assigns an OIDC group with administrative permissions to the project.
resource "harbor_project_member_group" "default" {
  project_id = harbor_project.default.id
  group_name = var.admin_group_name
  role       = "projectadmin"
  type       = "oidc"
}


resource "harbor_retention_policy" "main" {
  scope    = harbor_project.default.id
  schedule = "Hourly"
  rule {
    n_days_since_last_pull = var.n_days_since_last_pull_retention
    repo_matching          = "**"
    tag_matching           = "**"
  }
}