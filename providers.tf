terraform {
  required_version = ">= 1.8.0"

  required_providers {
    validatefx = {
      source  = "registry.terraform.io/The-DevOps-Daily/validatefx"
      version = ">= 0.11.2"
    }
  }
}