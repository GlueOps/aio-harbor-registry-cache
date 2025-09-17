terraform {
  required_providers {
    harbor = {
      source  = "goharbor/harbor"
      version = "3.11.1"
    }
  }
}

provider "harbor" {
  username = "admin"
}