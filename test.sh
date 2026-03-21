#!/usr/bin/env bash
set -euo pipefail

PROVIDER_FILE="providers_override.tf"

# Inject required_providers for testing (uses provider:: function syntax)
cat > "$PROVIDER_FILE" <<'EOF'
terraform {
  required_providers {
    validatefx = {
      source  = "registry.terraform.io/The-DevOps-Daily/validatefx"
      version = ">= 0.11.2"
    }
  }
}
EOF

cleanup() { rm -f "$PROVIDER_FILE"; }
trap cleanup EXIT

terraform init -upgrade
terraform validate
terraform test "$@"
