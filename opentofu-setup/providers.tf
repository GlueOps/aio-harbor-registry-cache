terraform {
  required_providers {
    harbor = {
      source  = "goharbor/harbor"
      version = "3.11.0"
    }
  }
}

provider "harbor" {
  username = "admin"
}