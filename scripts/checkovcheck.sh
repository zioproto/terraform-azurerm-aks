#!/usr/bin/env bash
# override.tf will trigger false alarm
echo "==> Removing all override.tf files"
find . -name 'override.tf' -delete
echo "==> Checking Terraform code with BridgeCrew Checkov"
checkov --skip-framework dockerfile --quiet -d ./