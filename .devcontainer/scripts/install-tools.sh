#!/usr/bin/env bash
set -euo pipefail

TFLINT_VERSION="0.55.0"
TASK_VERSION="3.43.3"
TFSEC_VERSION="1.28.13"
TERRAFORM_VERSION="1.14.0"
HELM_VERSION="3.17.0"
KUSTOMIZE_VERSION="5.5.0"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
esac

BIN_DIR="${BIN_DIR:-/usr/local/bin}"

unzip_file_to() {
  local zip_file="$1" entry="$2" dest="$3"
  if command -v unzip &>/dev/null; then
    unzip -o "$zip_file" "$entry" -d "$dest"
  elif command -v python3 &>/dev/null; then
    python3 -c "import zipfile; zipfile.ZipFile('$zip_file').extract('$entry', '$dest')"
  else
    echo "ERROR: Neither unzip nor python3 found"
    exit 1
  fi
}

install_terraform() {
  echo "Installing Terraform ${TERRAFORM_VERSION}..."
  local url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"
  curl -fsSL "$url" -o /tmp/terraform.zip
  unzip_file_to /tmp/terraform.zip terraform "$BIN_DIR"
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

install_helm() {
  echo "Installing Helm ${HELM_VERSION}..."
  local url="https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz"
  curl -fsSL "$url" | tar -xz -C /tmp "linux-${ARCH}/helm"
  mv "/tmp/linux-${ARCH}/helm" "$BIN_DIR/helm"
  rm -rf "/tmp/linux-${ARCH}"
}

install_kustomize() {
  echo "Installing Kustomize ${KUSTOMIZE_VERSION}..."
  local url="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_${ARCH}.tar.gz"
  curl -fsSL "$url" | tar -xz -C "$BIN_DIR" kustomize
}

install_terraform
install_tflint
install_task
install_tfsec
install_helm
install_kustomize

echo ""
echo "Installed versions:"
terraform --version
tflint --version
task --version
tfsec --version
helm version --short
kustomize version
