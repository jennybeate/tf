# Sandbox environment setup

This guide walks through deploying the sandbox environment end to end. Everything runs through the pipeline — you edit files, open a PR, and the pipeline deploys. There are two manual steps that genuinely cannot be automated: one-time admin setup, and registering a private repo with Argo CD after first deploy.

---

## 1 — One-time platform admin setup

These steps run once per subscription. They are prerequisites for every pipeline run.

### Bootstrap Terraform state

The Bicep bootstrap template creates the storage account where Terraform keeps its state files.

```bash
az login
az account set --subscription <AZURE_SUBSCRIPTION_ID>

az deployment sub create \
  --location norwayeast \
  --template-file infra-as-code/bicep/bootstrap/main.bicep \
  --parameters infra-as-code/bicep/bootstrap/config/parameters/bootstrap.bicepparam
```

This creates:
- Resource group: `rg-sbx-platform-terraform-state`
- Storage account: `stsbxplatformtfstate`
- Container: `tfstate`
- RBAC: `Storage Blob Data Owner` for the app registration

### Create an App Registration and configure OIDC

1. Create an **App Registration** in Entra ID.
2. Under **Certificates and secrets → Federated credentials**, add two credentials:
   - Entity type: `Pull request` — used by the plan pipeline
   - Entity type: `Branch`, branch `main` — used by the apply pipeline
3. Grant the app **Owner** on the sandbox subscription.

See [`.github/docs/oidc.md`](../../.github/docs/oidc.md) for subject claim format details.

### Add GitHub Actions secrets and variables

Go to **Settings → Secrets and variables → Actions**.

**Secrets:**

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Sandbox subscription ID |

**Variables:**

| Variable | Value |
|----------|-------|
| `TF_BACKEND_RESOURCE_GROUP` | `rg-sbx-platform-terraform-state` |
| `TF_BACKEND_STORAGE_ACCOUNT` | `stsbxplatformtfstate` |

Backend config values are **variables**, not secrets — using `secrets.*` for non-secret values silently returns empty.

### Add Argo CD repo token (private repos only)

If this repository is private, Argo CD needs a fine-grained PAT to pull manifests from GitHub.

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Generate a new token scoped to this repository with **Contents: Read-only**
3. Add it as a GitHub Actions secret:

| Secret | Value |
|--------|-------|
| `ARGOCD_REPO_TOKEN` | Fine-grained PAT with Contents read-only |

---

## 2 — Deploy infrastructure

Fill in the deployment variables, then let the pipeline apply them.

Edit [`infra-as-code/terraform/solutions/sandbox/environments/sbx.tfvars`](../../infra-as-code/terraform/solutions/sandbox/environments/sbx.tfvars):

```hcl
cost_center      = "cc-0000"
dns_zone_name    = "k8s.example.com"
environment      = "sbx"
location         = "norwayeast"
node_count_min   = 1
node_count_max   = 3
node_vm_size     = "Standard_D2s_v3"
owner            = "platform-team"
replication_type = "LRS"
```

Open a PR. `terraform-plan-sandbox.yml` runs validate and plan automatically and posts the plan as a PR comment.

Merge to `main`. `terraform-apply-sandbox.yml` applies.

**What gets created:** AKS cluster, Key Vault, DNS zone, storage account, and role assignments granting the AKS managed identity access to Key Vault and DNS.

---

## 3 — Configure platform services

Platform services need environment-specific values patched into their YAML files before Argo CD deploys them. Run the configure script with all values from your infrastructure deployment:

```bash
bash scripts/configure-platform.sh \
  --tenant-id        <entra-id-tenant-uuid> \
  --subscription-id  <azure-subscription-uuid> \
  --resource-group   rg-sbx-dns \
  --client-id        <kubernetes_identity_client_id from terraform output> \
  --keyvault-uri     https://kv-sbx-application-1.vault.azure.net \
  --email            your-team@example.com \
  --dns-zone         k8s.example.com
```

The script patches:
- `gitops/sandbox/platform/external-dns/values.yaml` — Azure DNS resource group, tenant, subscription, workload identity client ID
- `gitops/sandbox/platform/cert-manager/cluster-issuer.yaml` — Let's Encrypt contact email
- `gitops/sandbox/platform/secret-management/external-secret-store.yaml` — Key Vault URI

Review the diff, then open a PR. `kubernetes-validate-sandbox.yml` runs schema validation automatically.

Merge to `main`. Argo CD will pick up these values on first sync after bootstrap.

**Note on cert-manager:** The cluster issuer points at Let's Encrypt **staging** by default. Staging issues untrusted test certificates. Once DNS and cert-manager are confirmed working, change the `server` URL in `cluster-issuer.yaml` to the production endpoint:

```yaml
server: https://acme-v02.api.letsencrypt.org/directory
```

---

## 4 — Bootstrap Argo CD

When the `terraform-apply-sandbox.yml` pipeline completes, it automatically triggers `terraform-apply-sandbox-bootstrap.yml`. This installs Argo CD into the cluster via Helm and applies `gitops/sandbox/argocd/root.yaml` as an `extraObjects` value, so Argo CD creates the `cluster-root` Application immediately after installation.

No action required. Watch the pipeline run in the Actions tab.

After bootstrap completes, Argo CD reads `gitops/sandbox/argocd/` on every sync cycle (default: 3 minutes) and deploys the platform services configured in Step 3.

---

## 5 — Register the repository with Argo CD (private repos only)

If the repository is private, Argo CD cannot pull manifests until you register it with the PAT from Step 1. This is a one-time manual step.

Port-forward to the Argo CD server:

```bash
az aks get-credentials --resource-group rg-sbx-application-1 --name aks-sbx-application-1
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

In a second terminal:

```bash
INITIAL_PASSWORD=$(argocd admin initial-password -n argocd | head -1)
argocd login localhost:8080 --username admin --password "$INITIAL_PASSWORD" --insecure

argocd repo add https://github.com/jennybeate/tf.git \
  --username jennybeate \
  --password <ARGOCD_REPO_TOKEN>
```

After registration, trigger a sync:

```bash
argocd app sync cluster-root
```

**Note on initial sync:** On first bootstrap, `cluster-issuer` and `external-secret-store` will initially show `Failed` — this is expected. cert-manager and the External Secrets Operator install their CRDs asynchronously. Wait for the `cert-manager` and `external-secrets` Applications to reach `Healthy`, then run `argocd app sync cluster-root` again. Everything should reach `Synced`/`Healthy` on the second pass.

---

## 6 — Deploy an application

Add the Argo CD Application manifest and the Kustomize app structure, then let the pipeline and Argo CD do the rest.

### Create the application manifest

Create `gitops/sandbox/argocd/<service-name>.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <service-name>
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/jennybeate/tf.git
    targetRevision: main
    path: gitops/sandbox/apps/<service-name>/overlays/sandbox
  destination:
    server: https://kubernetes.default.svc
    namespace: <target-namespace>
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Create the Kustomize structure

Copy the template:

```bash
cp -r gitops/sandbox/apps/service gitops/sandbox/apps/<service-name>
```

Fill in `base/deployment.yaml` with your container image and port. Fill in `base/service.yaml`. Edit `base/kustomization.yaml` to list all base resources.

Create `overlays/sandbox/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

images:
  - name: app
    newTag: "v1.0.0"

replicas:
  - name: app
    count: 1
```

### Add an Ingress (for public access)

Add `base/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <service-name>
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - <service-name>.k8s.example.com
      secretName: <service-name>-tls
  rules:
    - host: <service-name>.k8s.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <service-name>
                port:
                  number: 8080
```

### Deploy

Open a PR. `kubernetes-validate-sandbox.yml` validates the manifests. Merge to `main`. Argo CD detects the new Application within 3 minutes and deploys it.

---

## 7 — Teardown

Tear down resources in this order.

### Destroy Terraform-managed resources

Trigger `workflow_dispatch` on `terraform-apply-sandbox.yml` if a destroy target is configured, or run locally:

```bash
cd infra-as-code/terraform/solutions/sandbox
task destroy
```

### Purge the soft-deleted Key Vault

Azure soft-deletes Key Vaults on destroy and reserves the name for 90 days. Purge protection is disabled in the sandbox (`sbx`) environment, so purge it immediately so the name is free for re-deployment:

```bash
task purge
```

### Delete the Terraform state backend

Once all managed resources are gone:

```bash
az group delete --name rg-sbx-platform-terraform-state --yes
```

Delete the state backend last — deleting it before destroying managed resources loses the state file.
