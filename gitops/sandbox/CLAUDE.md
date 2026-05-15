# Sandbox GitOps

This directory governs what runs inside the sandbox AKS cluster.

**Cluster:** `aks-sbx-application-1` — resource group `rg-sbx-application-1`

Argo CD reads `argocd/` on every sync cycle (default interval: 3 minutes). Any file committed and merged to `main` deploys automatically. Do not apply manifests directly with `kubectl` — commit and let Argo CD sync.

## Directory layout

| Directory | Purpose |
|-----------|---------|
| `argocd/` | Argo CD Application manifests — one file per platform service or app |
| `platform/` | Helm values and raw manifests for cluster-wide shared services |
| `tenants/` | Per-team namespace and RBAC definitions |
| `apps/` | First-party application workloads (Kustomize base + overlays) |

## Key behaviours

- `root.yaml` is excluded from `cluster-root`'s own sync. If you change it, re-apply manually: `kubectl apply -n argocd -f gitops/sandbox/argocd/root.yaml --server-side --force-conflicts`
- cert-manager ClusterIssuer points at Let's Encrypt **staging** — certificates issued here are not trusted by browsers. Switch to the production endpoint once DNS is confirmed working.
- On first bootstrap, `cluster-issuer` and `external-secret-store` will initially show `Failed` because their CRDs are not yet installed. Wait for `cert-manager` and `external-secrets` apps to reach `Healthy`, then run `argocd app sync cluster-root`.

## Adding a platform service

1. Create `platform/<service-name>/` with Helm values or manifests
2. Create `argocd/<service-name>.yaml` pointing to that path
3. Add a `namespace.yaml` to `platform/namespaces/` and reference it in `platform/namespaces/kustomization.yaml` if the service needs its own namespace
4. Open PR → pipeline validates → merge → Argo CD syncs

## Adding an application

1. Copy `apps/service` to `apps/<service-name>`
2. Fill in base manifests and create `overlays/sandbox/kustomization.yaml`
3. Create `argocd/<service-name>.yaml` pointing to `gitops/sandbox/apps/<service-name>/overlays/sandbox`
4. Open PR → pipeline validates → merge → Argo CD syncs
