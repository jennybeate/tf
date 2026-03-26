#!/bin/bash
set -e

# Install tflint
echo "Installing tflint..."
TFLINT_VERSION=$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -Lo /tmp/tflint.zip "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip"
unzip -o /tmp/tflint.zip -d /tmp/tflint
sudo mv /tmp/tflint/tflint /usr/local/bin/tflint
rm -rf /tmp/tflint /tmp/tflint.zip
echo "tflint ${TFLINT_VERSION} installed"

# Install tfsec
echo "Installing tfsec..."
TFSEC_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -Lo /tmp/tfsec "https://github.com/aquasecurity/tfsec/releases/download/${TFSEC_VERSION}/tfsec-linux-amd64"
chmod +x /tmp/tfsec
sudo mv /tmp/tfsec /usr/local/bin/tfsec
echo "tfsec ${TFSEC_VERSION} installed"

# Initialise tflint plugins (reads .tflint.hcl from repo root)
echo "Initialising tflint plugins..."
tflint --init

# Install Bicep CLI
echo "Installing Bicep..."
az bicep install
echo "Bicep $(az bicep version --query 'bicepVersion' -o tsv) installed"

echo "All tools installed successfully."
