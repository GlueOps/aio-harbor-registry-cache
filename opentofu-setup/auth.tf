resource "harbor_config_auth" "oidc" {
  auth_mode          = "oidc_auth"
  primary_auth_mode  = false
  oidc_name          = "google"
  oidc_endpoint      = "https://accounts.google.com"
  oidc_client_id     = var.GOOGLE_OIDC_CLIENT_ID
  oidc_client_secret = var.GOOGLE_OIDC_CLIENT_SECRET
  oidc_scope         = "openid,email"
  oidc_verify_cert   = true
  oidc_auto_onboard  = true
  oidc_user_claim    = "email"
  oidc_admin_group   = "administrators"
}

resource "harbor_group" "administrators" {
  group_name = local.admin_group_name
  group_type = 3
}
