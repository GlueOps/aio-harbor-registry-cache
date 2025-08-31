# --- Docker Hub Proxy Cache ---
module "dockerhub_proxy" {
  source = "./modules/proxy-project"

  project_name          = "proxy-docker-io"
  registry_provider     = var.harbor_registry_mode == "REPLICA" ? "docker-registry" : "docker-hub"
  registry_endpoint_url = var.harbor_registry_mode == "REPLICA" ? "https://${var.harbor_core_hostname}/proxy-docker-io" : "https://hub.docker.com"
}

# --- Quay.io Proxy Cache ---
module "quay_proxy" {
  source = "./modules/proxy-project"

  project_name          = "proxy-quay-io"
  registry_provider     = var.harbor_registry_mode == "REPLICA" ? "docker-registry" : "quay"
  registry_endpoint_url = var.harbor_registry_mode == "REPLICA" ? "https://${var.harbor_core_hostname}/proxy-quay-io" : "https://quay.io"
}

# --- Google Container Registry (GCR) Proxy Cache ---
module "gcr_proxy" {
  source = "./modules/proxy-project"

  project_name          = "proxy-gcr-io"
  registry_provider     = var.harbor_registry_mode == "REPLICA" ? "docker-registry" : "docker-registry"
  registry_endpoint_url = var.harbor_registry_mode == "REPLICA" ? "https://${var.harbor_core_hostname}/proxy-gcr-io" : "https://gcr.io"
}

# --- GitHub Container Registry (GHCR) Proxy Cache ---
module "ghcr_proxy" {
  source = "./modules/proxy-project"

  project_name          = "proxy-ghcr-io"
  registry_provider     = var.harbor_registry_mode == "REPLICA" ? "docker-registry" : "docker-hub"
  registry_endpoint_url = var.harbor_registry_mode == "REPLICA" ? "https://${var.harbor_core_hostname}/proxy-ghcr-io" : "https://ghcr.io"
}

# --- Amazon ECR Public Proxy Cache ---
module "ecr_public_proxy" {
  source = "./modules/proxy-project"

  project_name          = "proxy-public-ecr-aws"
  registry_provider     = var.harbor_registry_mode == "REPLICA" ? "docker-registry" : "docker-registry"
  registry_endpoint_url = var.harbor_registry_mode == "REPLICA" ? "https://${var.harbor_core_hostname}/proxy-public-ecr-aws" : "https://public.ecr.aws"
}


# --- Microsoft Container Registry (MCR) Proxy Cache ---
module "mcr_public_proxy" {
  source = "./modules/proxy-project"

  project_name          = "proxy-mcr-microsoft-com"
  registry_provider     = var.harbor_registry_mode == "REPLICA" ? "docker-registry" : "docker-registry"
  registry_endpoint_url = var.harbor_registry_mode == "REPLICA" ? "https://${var.harbor_core_hostname}/proxy-mcr-microsoft-com" : "https://mcr.microsoft.com"
}
