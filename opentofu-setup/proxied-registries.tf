# --- Docker Hub Proxy Cache ---
module "dockerhub_proxy" {
  source = "./modules/proxy-project"

  project_name          = "proxy-docker-io"
  registry_provider     = "docker-hub"
  registry_endpoint_url = "https://hub.docker.com"
  admin_group_name      = local.admin_group_name
}

# --- Quay.io Proxy Cache ---
module "quay_proxy" {
  source = "./modules/proxy-project"

  project_name          = "proxy-quay-io"
  registry_provider     = "quay"
  registry_endpoint_url = "https://quay.io"
  admin_group_name      = local.admin_group_name
}

# --- Google Container Registry (GCR) Proxy Cache ---
module "gcr_proxy" {
  source = "./modules/proxy-project"

  project_name          = "proxy-gcr-io"
  registry_provider     = "docker-registry"
  registry_endpoint_url = "https://gcr.io"
  admin_group_name      = local.admin_group_name
}

# --- GitHub Container Registry (GHCR) Proxy Cache ---
module "ghcr_proxy" {
  source = "./modules/proxy-project"

  project_name = "proxy-ghcr-io"
  # Note: Harbor uses the 'docker-hub' provider for GHCR as it's a compatible API
  registry_provider     = "docker-hub"
  registry_endpoint_url = "https://ghcr.io"
  admin_group_name      = local.admin_group_name
}

# --- NVIDIA NGC Proxy Cache ---
module "nvcr_proxy" {
  source = "./modules/proxy-project"

  project_name = "proxy-nvcr-io"
  # Note: Harbor uses the 'docker-hub' provider for NVCR as it's a compatible API
  registry_provider     = "docker-hub"
  registry_endpoint_url = "https://nvcr.io"
  admin_group_name      = local.admin_group_name
}


# --- Amazon ECR Public Proxy Cache ---
module "ecr_public_proxy" {
  source = "./modules/proxy-project"

  project_name          = "proxy-public-ecr-aws"
  registry_provider     = "docker-registry"
  registry_endpoint_url = "https://public.ecr.aws"
  admin_group_name      = local.admin_group_name
}