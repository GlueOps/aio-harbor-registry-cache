resource "harbor_interrogation_services" "main" {
  count = var.harbor_registry_mode == "CORE" ? 1 : 0

  default_scanner           = "Trivy"
  vulnerability_scan_policy = "Daily"
}