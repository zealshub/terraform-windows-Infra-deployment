#!/usr/bin/env bash
set -euo pipefail

echo "==> Terraform init"
terraform init -input=false

echo "==> Terraform apply"
terraform apply -input=false -auto-approve tfplan

