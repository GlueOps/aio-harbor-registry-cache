locals {
  proxy_registries = {
    dockerhub_proxy = {
      project_name = "proxy-docker-io"
      upstream_url = "https://registry-1.docker.io"
    }
    quay_proxy = {
      project_name = "proxy-quay-io"
      upstream_url = "https://quay.io"
    }
    gcr_proxy = {
      project_name = "proxy-gcr-io"
      upstream_url = "https://gcr.io"
    }
    ghcr_proxy = {
      project_name = "proxy-ghcr-io"
      upstream_url = "https://ghcr.io"
    }
    ecr_public_proxy = {
      project_name = "proxy-public-ecr-aws"
      upstream_url = "https://public.ecr.aws"
    }
    mcr_public_proxy = {
      project_name = "proxy-mcr-microsoft-com"
      upstream_url = "https://mcr.microsoft.com"
    }
    registry_k8s_io_proxy = {
      project_name = "proxy-registry-k8s-io"
      upstream_url = "https://registry.k8s.io"
    }
  }
}

module "proxy_registry" {
  source   = "./modules/proxy-project"
  for_each = local.proxy_registries

  project_name          = each.value.project_name
  registry_provider     = var.harbor_registry_mode == "REPLICA" ? "harbor" : local.registry_provider
  registry_endpoint_url = var.harbor_registry_mode == "REPLICA" ? "https://${var.harbor_core_hostname}:8443" : each.value.upstream_url
  admin_group_name      = local.admin_group_name
}