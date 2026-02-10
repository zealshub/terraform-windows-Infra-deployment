#!/usr/bin/env bash
set -euo pipefail

echo "==> Terraform fmt"
terraform fmt -check -recursive

echo "==> Terraform init"
terraform init -input=false

echo "==> Terraform validate"
terraform validate

echo "==> Terraform plan"
terraform plan -input=false -out=tfplan
