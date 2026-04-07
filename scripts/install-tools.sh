#!/usr/bin/env bash
set -euo pipefail

TERRAFORM_VERSION="1.11.3"
TFLINT_VERSION="0.55.0"
TASK_VERSION="3.43.3"
TFSEC_VERSION="1.28.13"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
esac

BIN_DIR="${BIN_DIR:-/usr/local/bin}"

install_terraform() {
  echo "Installing Terraform ${TERRAFORM_VERSION}..."
  local url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"
  curl -fsSL "$url" -o /tmp/terraform.zip
  unzip -o /tmp/terraform.zip -d "$BIN_DIR"
  rm /tmp/terraform.zip
}

install_tflint() {
  echo "Installing tflint ${TFLINT_VERSION}..."
  local url="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip"
  curl -fsSL "$url" -o /tmp/tflint.zip
  unzip -o /tmp/tflint.zip -d "$BIN_DIR"
  rm /tmp/tflint.zip
}

install_task() {
  echo "Installing Task ${TASK_VERSION}..."
  local url="https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_${ARCH}.tar.gz"
  curl -fsSL "$url" | tar -xz -C "$BIN_DIR" task
}

install_tfsec() {
  echo "Installing tfsec ${TFSEC_VERSION}..."
  local url="https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-${ARCH}"
  curl -fsSL "$url" -o "$BIN_DIR/tfsec"
  chmod +x "$BIN_DIR/tfsec"
}

install_terraform
install_tflint
install_task
install_tfsec

echo ""
echo "Installed versions:"
terraform version | head -1
tflint --version
task --version
tfsec --version
