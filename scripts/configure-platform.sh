#!/usr/bin/env bash

set -euo pipefail

# Configure Kubernetes platform services by patching YAML files
# Designed for automation — no interactive prompts.

usage() {
  cat <<EOF
Usage: $(basename "$0") \\
  --tenant-id        <uuid> \\
  --subscription-id  <uuid> \\
  --resource-group   <rg-name> \\
  --client-id        <uuid> \\
  --keyvault-uri     <https://kv-name.vault.azure.net> \\
  --email            <admin@example.com> \\
  --dns-zone         <k8s.example.com>

All flags are required.
EOF
  exit 1
}

# Initialize variables
TENANT_ID=""
SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
CLIENT_ID=""
KEYVAULT_URI=""
EMAIL=""
DNS_ZONE=""

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --tenant-id)
      TENANT_ID="$2"
      shift 2
      ;;
    --subscription-id)
      SUBSCRIPTION_ID="$2"
      shift 2
      ;;
    --resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    --client-id)
      CLIENT_ID="$2"
      shift 2
      ;;
    --keyvault-uri)
      KEYVAULT_URI="$2"
      shift 2
      ;;
    --email)
      EMAIL="$2"
      shift 2
      ;;
    --dns-zone)
      DNS_ZONE="$2"
      shift 2
      ;;
    *)
      echo "Unknown flag: $1"
      usage
      ;;
  esac
done

# Validate all flags are provided
MISSING=""
[[ -z "$TENANT_ID" ]] && MISSING="$MISSING --tenant-id"
[[ -z "$SUBSCRIPTION_ID" ]] && MISSING="$MISSING --subscription-id"
[[ -z "$RESOURCE_GROUP" ]] && MISSING="$MISSING --resource-group"
[[ -z "$CLIENT_ID" ]] && MISSING="$MISSING --client-id"
[[ -z "$KEYVAULT_URI" ]] && MISSING="$MISSING --keyvault-uri"
[[ -z "$EMAIL" ]] && MISSING="$MISSING --email"
[[ -z "$DNS_ZONE" ]] && MISSING="$MISSING --dns-zone"

if [[ -n "$MISSING" ]]; then
  echo "Error: missing required flags:$MISSING"
  usage
fi

# Resolve repo root
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# File paths (absolute)
EXTERNAL_DNS_VALUES="$REPO_ROOT/infra-as-code/gitops/platform/external-dns/values.yaml"
CERT_MANAGER_ISSUER="$REPO_ROOT/infra-as-code/gitops/platform/cert-manager/cluster-issuer.yaml"
ESO_SECRETSTORE="$REPO_ROOT/infra-as-code/gitops/platform/secret-management/external-secret-store.yaml"

# Verify files exist
for file in "$EXTERNAL_DNS_VALUES" "$CERT_MANAGER_ISSUER" "$ESO_SECRETSTORE"; do
  if [[ ! -f "$file" ]]; then
    echo "Error: file not found: $file"
    exit 1
  fi
done

echo "Configuring platform services..."
echo ""

# Patch external-dns/values.yaml
echo "Patching $EXTERNAL_DNS_VALUES..."
# Note: sed -i on Linux/Git Bash; macOS requires sed -i ''
sed -i "s|resourceGroup:.*|resourceGroup: \"$RESOURCE_GROUP\"|" "$EXTERNAL_DNS_VALUES"
sed -i "s|tenantId:.*|tenantId: \"$TENANT_ID\"|" "$EXTERNAL_DNS_VALUES"
sed -i "s|subscriptionId:.*|subscriptionId: \"$SUBSCRIPTION_ID\"|" "$EXTERNAL_DNS_VALUES"
sed -i "s|azure.workload.identity/client-id:.*|azure.workload.identity/client-id: \"$CLIENT_ID\"|" "$EXTERNAL_DNS_VALUES"

# Patch cert-manager/cluster-issuer.yaml
echo "Patching $CERT_MANAGER_ISSUER..."
sed -i "s|email:.*|email: $EMAIL|" "$CERT_MANAGER_ISSUER"

# Patch external-secret-store.yaml
echo "Patching $ESO_SECRETSTORE..."
sed -i "s|vaultUrl:.*|vaultUrl: \"$KEYVAULT_URI\"|" "$ESO_SECRETSTORE"

echo ""
echo "=== Changes made ==="
if command -v git &>/dev/null && git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$REPO_ROOT" diff --stat
else
  echo "✓ $EXTERNAL_DNS_VALUES"
  echo "✓ $CERT_MANAGER_ISSUER"
  echo "✓ $ESO_SECRETSTORE"
fi

echo ""
echo "=== Next steps ==="
echo "1. Review the changes: git diff"
echo "2. Commit and push: git add ... && git commit -m '...' && git push"
echo "3. Run: bash scripts/bootstrap-argocd.sh"
