#!/usr/bin/env bash
set -euo pipefail

TFLINT_VERSION="0.55.0"
TASK_VERSION="3.43.3"
CHECKOV_VERSION="3.2.528"
TERRAFORM_VERSION="1.14.0"
HELM_VERSION="3.17.0"
KUSTOMIZE_VERSION="5.5.0"
KUBECTL_VERSION="1.32.0"
ARGOCD_VERSION="2.13.0"

BIN_DIR="${BIN_DIR:-/usr/local/bin}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

download() {
  local url="$1" output="$2"
  curl --proto '=https' --tlsv1.2 -fsSL --retry 3 --connect-timeout 15 "$url" -o "$output"
}

download_stdout() {
  local url="$1"
  curl --proto '=https' --tlsv1.2 -fsSL --retry 3 --connect-timeout 15 "$url"
}

is_root() {
  [[ "$(id -u)" == "0" ]]
}

require_linux() {
  [[ "$(uname -s)" == "Linux" ]] || die "this installer currently supports Linux only"
}

detect_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64 | amd64) echo "amd64" ;;
    aarch64 | arm64) echo "arm64" ;;
    *) die "unsupported architecture: $arch" ;;
  esac
}

ARCH="$(detect_arch)"

checksum_from_file() {
  local checksum_file="$1" artifact="$2"
  awk -v artifact="$artifact" '$NF == artifact { print $1; found=1 } END { exit found ? 0 : 1 }' "$checksum_file"
}

verify_checksum() {
  local file="$1" expected="$2"
  local actual

  [[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || die "invalid or missing checksum for $(basename "$file")"
  actual="$(sha256sum "$file" | awk '{print $1}')"
  if [[ "${actual,,}" != "${expected,,}" ]]; then
    die "checksum mismatch for $file; expected $expected, actual $actual"
  fi
}

verify_gpg_fingerprint() {
  local keyring="$1" expected_fingerprint="$2"
  local actual gnupg_home

  gnupg_home="$TMP_DIR/gpg-show-$(basename "$keyring")"
  install -d -m 0700 "$gnupg_home"
  actual="$(GNUPGHOME="$gnupg_home" gpg --show-keys --with-colons "$keyring" 2>/dev/null | awk -F: '$1 == "fpr" { print $10; exit }')"
  [[ "$actual" == "$expected_fingerprint" ]] || die "unexpected GPG key fingerprint: ${actual:-none}"
}

verify_gpg_signature() {
  local key_file="$1" expected_fingerprint="$2" signature="$3" signed_file="$4"
  local gnupg_home
  gnupg_home="$TMP_DIR/gnupg-$(basename "$signed_file")"

  verify_gpg_fingerprint "$key_file" "$expected_fingerprint"
  install -d -m 0700 "$gnupg_home"
  GNUPGHOME="$gnupg_home" gpg --batch --import "$key_file" >/dev/null 2>&1
  GNUPGHOME="$gnupg_home" gpg --batch --verify "$signature" "$signed_file" >/dev/null 2>&1
}

install_file() {
  local source="$1" target="$2"
  mkdir -p "$BIN_DIR"
  if is_root; then
    install -o root -g root -m 0755 "$source" "$target"
  else
    install -m 0755 "$source" "$target"
  fi
}

extract_zip_entry() {
  local zip_file="$1" entry="$2" dest_file="$3"

  if command -v unzip >/dev/null 2>&1; then
    unzip -p "$zip_file" "$entry" > "$dest_file"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$zip_file" "$entry" "$dest_file" <<'PY'
import sys
import zipfile

zip_file, entry, dest_file = sys.argv[1], sys.argv[2], sys.argv[3]
with zipfile.ZipFile(zip_file) as archive:
    with archive.open(entry) as source, open(dest_file, "wb") as target:
        target.write(source.read())
PY
  else
    die "neither unzip nor python3 found"
  fi

  chmod 0755 "$dest_file"
}

extract_tar_entry() {
  local tarball="$1" entry="$2" dest_dir="$3"
  mkdir -p "$dest_dir"
  tar -xzf "$tarball" -C "$dest_dir" "$entry"
}

install_terraform() {
  echo "Installing Terraform ${TERRAFORM_VERSION}..."
  local zip="terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"
  local base="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}"
  local artifact="$TMP_DIR/$zip"
  local sums="$TMP_DIR/terraform_SHA256SUMS"
  local sig="$TMP_DIR/terraform_SHA256SUMS.sig"
  local key="$TMP_DIR/hashicorp.asc"
  local extracted="$TMP_DIR/terraform"
  local expected

  download "${base}/${zip}" "$artifact"
  download "${base}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" "$sums"
  if command -v gpg >/dev/null 2>&1; then
    download "${base}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" "$sig"
    download "https://www.hashicorp.com/.well-known/pgp-key.txt" "$key"
    verify_gpg_signature "$key" "C874011F0AB405110D02105534365D9472D7468F" "$sig" "$sums" \
      || die "Terraform checksum signature verification failed"
  else
    echo "WARNING: gpg not found; verifying Terraform checksum without signature validation" >&2
  fi
  expected="$(checksum_from_file "$sums" "$zip")"
  verify_checksum "$artifact" "$expected"
  extract_zip_entry "$artifact" terraform "$extracted"
  install_file "$extracted" "$BIN_DIR/terraform"
}

install_tflint() {
  echo "Installing tflint ${TFLINT_VERSION}..."
  local zip="tflint_linux_${ARCH}.zip"
  local base="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}"
  local artifact="$TMP_DIR/$zip"
  local sums="$TMP_DIR/tflint_checksums.txt"
  local extracted="$TMP_DIR/tflint"
  local expected

  download "${base}/${zip}" "$artifact"
  download "${base}/checksums.txt" "$sums"
  expected="$(checksum_from_file "$sums" "$zip")"
  verify_checksum "$artifact" "$expected"
  extract_zip_entry "$artifact" tflint "$extracted"
  install_file "$extracted" "$BIN_DIR/tflint"
}

install_task() {
  echo "Installing Task ${TASK_VERSION}..."
  local tarball="task_linux_${ARCH}.tar.gz"
  local base="https://github.com/go-task/task/releases/download/v${TASK_VERSION}"
  local artifact="$TMP_DIR/$tarball"
  local sums="$TMP_DIR/task_checksums.txt"
  local extract_dir="$TMP_DIR/task-extract"
  local expected

  download "${base}/${tarball}" "$artifact"
  download "${base}/task_checksums.txt" "$sums"
  expected="$(checksum_from_file "$sums" "$tarball")"
  verify_checksum "$artifact" "$expected"
  extract_tar_entry "$artifact" task "$extract_dir"
  install_file "$extract_dir/task" "$BIN_DIR/task"
}

install_checkov() {
  echo "Installing Checkov ${CHECKOV_VERSION}..."
  local req_file
  req_file="$(dirname "$(realpath "$0")")/checkov-requirements.txt"
  [[ -f "$req_file" ]] || die "checkov-requirements.txt not found alongside install-tools.sh"

  require_cmd python3
  local venv_dir="${CHECKOV_VENV_DIR:-/opt/checkov}"
  if [[ "$venv_dir" == /opt/* || "$venv_dir" == /usr/* ]]; then
    is_root || die "installing Checkov venv to $venv_dir requires root; set CHECKOV_VENV_DIR to a writable path"
  fi

  python3 -m venv "$venv_dir"
  "$venv_dir/bin/python" -m pip install --quiet --upgrade pip
  "$venv_dir/bin/python" -m pip install --quiet --require-hashes -r "$req_file"
  install_file "$venv_dir/bin/checkov" "$BIN_DIR/checkov"
}

install_helm() {
  echo "Installing Helm ${HELM_VERSION}..."
  local tarball="helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz"
  local artifact="$TMP_DIR/$tarball"
  local expected
  local extract_dir="$TMP_DIR/helm-extract"

  download "https://get.helm.sh/${tarball}" "$artifact"
  expected="$(download_stdout "https://get.helm.sh/${tarball}.sha256sum" | awk '{print $1}')"
  verify_checksum "$artifact" "$expected"
  extract_tar_entry "$artifact" "linux-${ARCH}/helm" "$extract_dir"
  install_file "$extract_dir/linux-${ARCH}/helm" "$BIN_DIR/helm"
}

install_kustomize() {
  echo "Installing Kustomize ${KUSTOMIZE_VERSION}..."
  local tarball="kustomize_v${KUSTOMIZE_VERSION}_linux_${ARCH}.tar.gz"
  local base="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}"
  local artifact="$TMP_DIR/$tarball"
  local sums="$TMP_DIR/kustomize_checksums.txt"
  local extract_dir="$TMP_DIR/kustomize-extract"
  local expected

  download "${base}/${tarball}" "$artifact"
  download "${base}/checksums.txt" "$sums"
  expected="$(checksum_from_file "$sums" "$tarball")"
  verify_checksum "$artifact" "$expected"
  extract_tar_entry "$artifact" kustomize "$extract_dir"
  install_file "$extract_dir/kustomize" "$BIN_DIR/kustomize"
}

install_kubectl() {
  echo "Installing kubectl v${KUBECTL_VERSION}..."
  local base="https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}"
  local artifact="$TMP_DIR/kubectl"
  local expected

  download "${base}/kubectl" "$artifact"
  expected="$(download_stdout "${base}/kubectl.sha256" | tr -d '[:space:]')"
  verify_checksum "$artifact" "$expected"
  install_file "$artifact" "$BIN_DIR/kubectl"
}

install_argocd() {
  echo "Installing Argo CD CLI v${ARGOCD_VERSION}..."
  local binary="argocd-linux-${ARCH}"
  local base="https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}"
  local artifact="$TMP_DIR/argocd"
  local sums="$TMP_DIR/argocd-checksums.txt"
  local expected

  download "${base}/${binary}" "$artifact"
  download "${base}/cli_checksums.txt" "$sums"
  expected="$(checksum_from_file "$sums" "$binary")"
  verify_checksum "$artifact" "$expected"
  install_file "$artifact" "$BIN_DIR/argocd"
}

install_az() {
  echo "Installing Azure CLI..."
  require_cmd apt-get
  require_cmd dpkg
  require_cmd gpg

  local codename key_ascii key_gpg expected_fingerprint
  # shellcheck source=/dev/null
  codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")"
  [[ -n "$codename" ]] || die "could not determine OS codename from /etc/os-release"

  key_ascii="$TMP_DIR/microsoft.asc"
  key_gpg="$TMP_DIR/microsoft.gpg"
  expected_fingerprint="BC528686B50D79E339D3721CEB3E94ADBE1229CF"

  download "https://packages.microsoft.com/keys/microsoft.asc" "$key_ascii"
  verify_gpg_fingerprint "$key_ascii" "$expected_fingerprint"
  gpg --dearmor < "$key_ascii" > "$key_gpg"

  install -d -m 0755 /etc/apt/keyrings
  install -o root -g root -m 0644 "$key_gpg" /etc/apt/keyrings/microsoft.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ ${codename} main" \
    > /etc/apt/sources.list.d/azure-cli.list

  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends azure-cli
}

main() {
  require_linux
  is_root || die "this installer requires root because it writes to $BIN_DIR and installs Azure CLI via apt"
  require_cmd curl
  require_cmd awk
  require_cmd sha256sum
  require_cmd tar
  require_cmd install

  install_terraform
  install_tflint
  install_task
  install_checkov
  install_helm
  install_kustomize
  install_kubectl
  install_argocd
  install_az

  echo ""
  echo "Installed versions:"
  terraform version
  tflint --version
  task --version
  checkov --version
  helm version --short
  kustomize version
  kubectl version --client
  argocd version --client
  az version
}

main "$@"
