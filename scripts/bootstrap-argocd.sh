#!/usr/bin/env bash

set -euo pipefail

# Bootstrap Argo CD on an AKS cluster
# Gets credentials, installs Argo CD, waits for readiness, prints initial password, applies root.yaml

usage() {
  cat <<EOF
Usage: $(basename "$0") [--resource-group <rg>] [--cluster-name <name>]

Defaults:
  --resource-group  rg-sbx-application-1
  --cluster-name    aks-sbx-application-1

Options:
  -h, --help  Show this help message
EOF
}

# Defaults
RESOURCE_GROUP="rg-sbx-application-1"
CLUSTER_NAME="aks-sbx-application-1"

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    --cluster-name)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown flag: $1"
      usage
      exit 1
      ;;
  esac
done

# Preflight checks
echo "=== Preflight checks ==="
for cmd in az kubectl argocd; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd not found in PATH. Install it and try again."
    exit 1
  fi
done
echo "✓ az CLI"
echo "✓ kubectl"
echo "✓ argocd CLI"
echo ""

# Get AKS credentials
echo "=== Getting AKS credentials ==="
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CLUSTER_NAME" \
  --overwrite-existing
echo ""

# Create argocd namespace (idempotent)
echo "=== Creating argocd namespace ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Namespace created/already exists"
echo ""

# Install Argo CD
echo "=== Installing Argo CD ==="
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "✓ Applied Argo CD manifests"
echo ""

# Wait for Argo CD components to be ready
echo "=== Waiting for Argo CD components to be ready ==="
echo "(This may take 1-2 minutes...)"
echo ""

echo "Waiting for argocd-server deployment..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
echo "✓ argocd-server ready"
echo ""

echo "Waiting for argocd-application-controller statefulset..."
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=300s
echo "✓ argocd-application-controller ready"
echo ""

# Print initial admin password
echo "=== Argo CD initial admin password ==="
INITIAL_PASSWORD=$(argocd admin initial-password -n argocd)
echo "$INITIAL_PASSWORD"
echo ""
echo "Save this password — you'll use it to log in to the web UI."
echo ""

# Apply root Application
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT_APP="$REPO_ROOT/gitops/sandbox/argocd/root.yaml"

if [[ ! -f "$ROOT_APP" ]]; then
  echo "Error: root.yaml not found at $ROOT_APP"
  exit 1
fi

echo "=== Applying Argo CD root Application ==="
kubectl apply -f "$ROOT_APP"
echo "✓ root Application applied"
echo ""

# Print next steps
echo "=== Next steps ==="
cat <<EOF
1. Port-forward to the Argo CD server (keep this terminal open):
   kubectl port-forward svc/argocd-server -n argocd 8080:443

2. Log in with the argocd CLI (in a new terminal):
   argocd login localhost:8080 --username admin --password '<initial-password>' --insecure

3. Register the Git repository (required — this repo is private):
   argocd repo add https://github.com/jennybeate/tf.git \\
     --username jennybeate \\
     --password <github-pat>

   The PAT needs repo scope (read access is sufficient).
   Create one at: https://github.com/settings/tokens

   root.yaml has already been applied. Argo CD will retry syncing
   automatically once credentials are registered.

4. Check app sync status:
   argocd app list

Note: On first sync, these apps may show as Failed (expected):
  - cluster-issuer (depends on cert-manager CRDs)
  - external-secret-store (depends on External Secrets Operator CRDs)

Wait for the cert-manager and external-secrets applications to reach Healthy,
then run:
  argocd app sync cluster-root

Everything should reach Synced/Healthy on the second pass.
EOF
