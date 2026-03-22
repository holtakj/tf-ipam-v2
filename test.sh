#!/usr/bin/env bash
set -euo pipefail

terraform init
terraform validate
terraform test "$@"
