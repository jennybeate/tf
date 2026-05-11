# IaC Training — Terraform + Kubernetes on Azure

This repo is the starting point for Nimtech infrastructure consultants learning Infrastructure as Code. It provides a working sandbox environment, CI/CD pipelines, team coding standards, and AI-assisted tooling for building applications on Azure with Terraform and Kubernetes.

---

## What's in here

```
.
├── .claude/                             # Claude Code project config (loaded automatically)
├── .devcontainer/                       # Dev container for VS Code / GitHub Codespaces
│   ├── devcontainer.json                # Container definition, tool versions, VS Code extensions
│   ├── Dockerfile                       # Base image + tool installs
│   ├── init-firewall.sh                 # Network rules applied on container start
│   └── setup-git-hooks.sh              # Installs pre-commit hooks inside the container
├── .github/
│   └── workflows/
│       ├── _terraform-plan.yml          # Reusable plan/validate workflow (parameterised)
│       ├── _terraform-apply.yml         # Reusable apply workflow (parameterised)
│       ├── terraform-plan-sandbox.yml   # Sandbox PR trigger — calls _terraform-plan.yml
│       ├── terraform-apply-sandbox.yml  # Sandbox merge trigger — calls _terraform-apply.yml
│       ├── _kubernetes-validate.yml     # Reusable K8s schema validation workflow
│       └── kubernetes-validate-sandbox.yml # K8s PR trigger — calls _kubernetes-validate.yml
├── infra-as-code/
│   ├── bicep/
│   │   └── bootstrap/                   # One-time Bicep deployment (run before Terraform)
│   │       ├── main.bicep               # Provisions Terraform remote state storage
│   │       └── config/parameters/
│   │           └── bootstrap.bicepparam # Subscription, location, naming params
│   ├── terraform/
│   │   ├── modules/                     # Reusable, versioned Terraform modules
│   │   │   ├── key-vault/v1.0.0/        # Azure Key Vault module 
│   │   │   ├── key-vault/v2.0.0/        # AVM Azure Key Vault 
│   │   │   ├── kubernetes/v1.0.0/       # AKS cluster module 
│   │   │   ├── kubernetes/v2.0.0/       # AVM AKS cluster module 
│   │   │   └── storage-account/         # Azure Storage Account module
│   │   └── solutions/
│   │       └── sandbox/                 # Sandbox deployment — calls modules, holds tfvars
│   │           ├── main.tf              # Module calls
│   │           ├── variables.tf         # Input declarations
│   │           ├── outputs.tf           # Output values
│   │           ├── terraform.tf         # Required providers and backend config
│   │           ├── providers.tf         # Provider configuration
│   │           ├── Taskfile.yml         # Local dev commands (validate, plan, apply, etc.)
│   │           └── environments/
│   │               └── sbx.tfvars       # Sandbox variable values
│   └── kubernetes/                      # In-cluster GitOps config (Argo CD)
│       ├── argocd/                      # Argo CD bootstrap and root application
│       │   └── root.yaml                # Root Application (app-of-apps) — syncs entire kubernetes/ directory
│       ├── platform/                    # Cluster-wide shared services — owned by platform team
│       │   ├── cert-manager/
│       │   │   ├── application.yaml     # Argo CD: installs cert-manager with CRDs enabled
│       │   │   └── cluster-issuer.yaml  # cert-manager: ClusterIssuer for Let's Encrypt
│       │   ├── external-dns/
│       │   │   ├── application.yaml     # Argo CD: installs ExternalDNS (Azure DNS provider)
│       │   │   └── values.yaml          # ExternalDNS config (resourceGroup, tenantId, subscriptionId)
│       │   ├── ingress-nginx/
│       │   │   └── application.yaml     # Argo CD: installs ingress-nginx controller
│       │   ├── monitoring/
│       │   │   └── application.yaml     # Argo CD: installs kube-prometheus-stack (Prometheus + Grafana)
│       │   ├── logging/
│       │   │   └── application.yaml     # Argo CD: installs Loki for log aggregation
│       │   ├── external-secrets/
│       │   │   └── application.yaml     # Argo CD: installs External Secrets Operator
│       │   ├── secret-management/
│       │   │   └── external-secret-store.yaml  # ESO: ClusterSecretStore pointing at Azure Key Vault
│       │   ├── namespaces/
│       │   │   ├── cert-manager.yaml    # Namespace definition for cert-manager
│       │   │   ├── external-dns.yaml    # Namespace definition for external-dns
│       │   │   ├── ingress-nginx.yaml   # Namespace definition for ingress-nginx
│       │   │   ├── monitoring.yaml      # Namespace definition for monitoring
│       │   │   └── kustomization.yaml   # Kustomize: lists all namespace files as resources
│       │   └── rbac/
│       │       ├── cluster-roles.yaml   # ClusterRole definitions (e.g. platform-reader)
│       │       ├── cluster-role-bindings.yaml  # Binds ClusterRoles to subjects
│       │       └── kustomization.yaml   # Kustomize: lists RBAC files as resources
│       ├── tenants/                     # Per-team namespace isolation and RBAC
│       │   └── team-analytics/
│       │       ├── namespace.yaml       # Namespace for the analytics team
│       │       └── rbac.yaml            # RoleBinding giving the team edit access to their namespace
│       └── apps/                        # First-party application workloads (Kustomize)
│           └── (add per-service folders here — see "Phase 4" below)
├── scripts/
│   └── install-tools.sh                 # Installs all required tools with pinned versions
├── skills/                              # Claude Code AI skills — invoked through Claude Code
│   ├── code-reviewer/                   # Review PowerShell, Bicep, or pipeline code
│   ├── devcontainer-builder/            # Build and configure dev containers
│   ├── github-actions-cicd/             # Design and generate GitHub Actions workflows
│   ├── naming-checker/                  # Validate Azure resource naming conventions
│   ├── repo-onboarding/                 # Understand the repo structure and working agreements
│   ├── tf-architect/                    # Scaffold new Terraform modules and deployments
│   └── tf-code-reviewer/                # Review .tf and .tfvars files against team standards
├── standards/
│   └── templates/                       # Authoring guides and review checklists
│       ├── terraform-authoring-guide.md
│       ├── terraform-standards.md
│       ├── github-actions-best-practices.md
│       ├── naming-conventions.md
│       ├── kubernetes-pod-best-practices.md
│       └── repo-working-agreement.md
├── CLAUDE.md                            # Claude Code context — loaded automatically on every session
└── README.md
```

---

## How the two halves fit together

Running an application on Azure Kubernetes Service (AKS) requires two separate layers:

| Layer | Tooling | What it does | Where it lives |
|-------|---------|--------------|----------------|
| Azure infrastructure | Terraform | Creates the AKS cluster itself, Key Vault, DNS zone, networking — the Azure resources that appear in the portal | `infra-as-code/terraform/` |
| What runs inside the cluster | Argo CD (GitOps) | Installs software into the cluster (cert-manager, monitoring, DNS, etc.) and deploys your applications | `infra-as-code/kubernetes/` |

**Why GitOps?** The traditional way to deploy to Kubernetes is to run `kubectl apply` commands manually. GitOps flips this: instead of pushing changes to the cluster, you commit changes to Git, and a tool called **Argo CD** running inside the cluster pulls them in automatically. The Git repo becomes the single source of truth for what should be running. If someone manually changes something in the cluster, Argo CD detects the drift and corrects it. Argo CD also provides a web UI for visualizing and managing applications.

---

## Before you begin

### Install tools

| Tool | Install |
|------|---------|
| Azure CLI | [learn.microsoft.com](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| Argo CD CLI | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/en/stable/cli_installation/) |
| Claude Code | [claude.ai/code](https://claude.ai/code) |

Terraform, tflint, tfsec, and Task are installed via script — versions are pinned in [`scripts/install-tools.sh`](scripts/install-tools.sh):

```bash
bash scripts/install-tools.sh
```

After installing tflint, run `tflint --init` in the repo root to install the azurerm ruleset.

### Optional bootstrap scripts

The 4-phase setup guide can be run entirely manually, or you can use two optional automation scripts to skip repetitive steps. Both are located in `scripts/`:

**`scripts/configure-platform.sh`** — Patches Phase 2 YAML files automatically.

Instead of manually editing three separate files (external-dns values, cert-manager email, ESO Key Vault URI), this script patches them all at once using `sed`:

```bash
bash scripts/configure-platform.sh \
  --tenant-id        <your-entra-id-tenant-uuid> \
  --subscription-id  <your-azure-subscription-uuid> \
  --resource-group   rg-sbx-dns \
  --keyvault-uri     https://kv-sbx-application-1.vault.azure.net \
  --email            your-team@example.com \
  --dns-zone         k8s.example.com
```

All six flags are required. The script:
- Validates that all flags are provided
- Patches `platform/external-dns/values.yaml` (resourceGroup, tenantId, subscriptionId)
- Patches `platform/cert-manager/cluster-issuer.yaml` (email)
- Patches `platform/secret-management/external-secret-store.yaml` (vaultUrl)
- Prints a `git diff` summary
- Reminds you to commit and push before continuing

**`scripts/bootstrap-argocd.sh`** — Runs all Phase 3 steps in one command.

Instead of running eight manual steps (get credentials, create namespace, install Argo CD, wait, get password, apply root.yaml), this script does them all:

```bash
bash scripts/bootstrap-argocd.sh \
  [--resource-group rg-sbx-application-1] \
  [--cluster-name   aks-sbx-application-1]
```

Both flags are optional and default to the sandbox environment. The script:
- Checks that `az`, `kubectl`, and `argocd` are installed
- Gets AKS credentials
- Creates the `argocd` namespace
- Installs Argo CD from the stable manifest
- Waits for the server and controller to be ready (300s timeout)
- Prints the initial admin password
- Applies `infra-as-code/kubernetes/argocd/root.yaml`
- Prints port-forward and `argocd app list` commands

You still need to manually port-forward and log in — those steps are left intentional so you see the UI and understand the platform.

**When to use them:**
- Use `configure-platform.sh` if you have all platform values (Azure IDs, Key Vault URI, email, DNS zone) ready and want to skip manual YAML editing.
- Use `bootstrap-argocd.sh` if you want to skip the tedious sequence of kubectl and argocd CLI commands.
- Both scripts are safe to run multiple times (they validate or are idempotent).
- Both are designed for CI/CD use — no interactive prompts or passwords.

The 4-phase manual guide below remains the reference. These scripts are optional shortcuts.

### Bootstrap Terraform state (one-time, platform admin)

Terraform state is stored in an Azure Storage Account provisioned by the Bicep bootstrap template. This runs once per subscription before any Terraform deployments.

```bash
# Get your app registration Object ID
az ad sp show --id <AZURE_CLIENT_ID> --query id -o tsv

# Get your user Object ID (if you want to grant yourself access in the same step)
az ad user show --id <your-email-address> --query id -o tsv 
# Store it in the .env file (make sure this is gitignored) and load it using .\Load-Environment.ps1 before running the deployment command

# Deploy the state backend
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

### Configure GitHub (one-time, platform admin)

#### Azure OIDC — no long-lived secrets

1. Create an **App Registration** in Entra ID.
2. Under **Certificates & secrets → Federated credentials**, add:
   - Entity type: `Pull request` — used by the plan pipeline
   - Entity type: `Branch`, branch `main` — used by the apply pipeline
3. Grant the app **Owner** on the sandbox subscription. (Owner grants all permissions needed: Terraform management, AKS access, Key Vault access, DNS management.)

#### Secrets (`Settings → Secrets and variables → Actions → Secrets`)

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Sandbox subscription ID |

#### Variables (`Settings → Secrets and variables → Actions → Variables`)

| Variable | Value |
|----------|-------|
| `TF_BACKEND_RESOURCE_GROUP` | `rg-sbx-platform-terraform-state` |
| `TF_BACKEND_STORAGE_ACCOUNT` | `stsbxplatformtfstate` |

> Backend config values are **variables**, not secrets — using `secrets.*` for these silently returns empty.

---

## Setup guide

### Phase 1 — Deploy the Kubernetes cluster (Terraform)

#### Authenticate locally

Log in with the Azure CLI:

```bash
az login
az account set --subscription <AZURE_SUBSCRIPTION_ID>
```

#### Fill in the deployment variables

Edit [`infra-as-code/terraform/solutions/sandbox/environments/sbx.tfvars`](infra-as-code/terraform/solutions/sandbox/environments/sbx.tfvars):

```hcl
cost_center      = "cc-0000"              # Your cost center code
dns_zone_name    = "k8s.example.com"      # Domain for ExternalDNS to manage
environment      = "sbx"                  # Sandbox environment
location         = "norwayeast"           # Azure region
node_count_min   = 1                      # Min AKS nodes
node_count_max   = 3                      # Max AKS nodes
node_vm_size     = "Standard_D2s_v3"      # Node VM type
owner            = "platform-team"        # Team name for tagging
replication_type = "LRS"                  # Storage replication (LRS = locally redundant)
```

#### Plan and apply

```bash
cd infra-as-code/terraform/solutions/sandbox

task plan    # review what will be created
task apply   # create the resources
```

#### What gets created

- **AKS cluster** — the Kubernetes cluster itself (managed by Azure)
- **Key Vault** — secret store for database passwords, API keys, etc.
- **DNS zone** — domain for ingress-nginx to manage
- **Storage account** — for persistent storage if needed
- **Role assignments** — grant the AKS managed identity access to Key Vault and the DNS zone

#### Important note: DNS zones in enterprise setups

In most enterprise environments, the DNS zone (e.g. `platform.company.com`) lives in a centrally managed hub subscription and is owned by the networking team. If that's the case:

- You cannot create a role assignment for the AKS managed identity in the hub subscription from the sandbox
- Instead, ask the hub team to: grant the AKS managed identity `DNS Zone Contributor` on the DNS zone in the hub
- OR: create a delegated subdomain (e.g. `sbx.platform.company.com`) that points to a throwaway zone in your sandbox

For sandbox testing, it's acceptable to use a domain like `sbx.example.com` in your own subscription.

---

### Phase 2 — Configure platform services

Platform services need some environment-specific configuration before Argo CD deploys them. These aren't credentials (secrets), just IDs and URLs.

> **Optional automation:** If you have all values ready, run [`scripts/configure-platform.sh`](scripts/configure-platform.sh) to patch all three files at once:
>
> ```bash
> bash scripts/configure-platform.sh \
>   --tenant-id        <your-tenant-id> \
>   --subscription-id  <your-subscription-id> \
>   --resource-group   rg-sbx-dns \
>   --keyvault-uri     https://kv-sbx-application-1.vault.azure.net \
>   --email            your@email.com \
>   --dns-zone         k8s.example.com
> ```
>
> Commit and push the changes before continuing to Phase 3. The manual steps below explain what each value controls.

#### ExternalDNS — Azure DNS details

Edit [`infra-as-code/kubernetes/platform/external-dns/values.yaml`](infra-as-code/kubernetes/platform/external-dns/values.yaml):

```yaml
provider:
  name: azure
azure:
  resourceGroup: "rg-sbx-dns"                      # Resource group containing your DNS zone
  tenantId: "ecabee7b-8606-4ae2-9f69-d63203bc23d5"       # Your Entra ID tenant ID (az account show --query tenantId)
  subscriptionId: "4c85663d-30f6-45c6-9850-e84fbe731e43" # Your Azure subscription ID
  useManagedIdentityExtension: true                      # Use AKS managed identity (no secrets needed)
```

#### cert-manager — Let's Encrypt contact

Edit [`infra-as-code/kubernetes/platform/cert-manager/cluster-issuer.yaml`](infra-as-code/kubernetes/platform/cert-manager/cluster-issuer.yaml):

Replace `jenny@nimtech.no` with your team's contact email. Let's Encrypt uses this to notify you before certificates expire.

**Note:** The file currently points at Let's Encrypt **staging**, which issues test certificates that browsers don't trust. This is intentional for testing. Once you confirm DNS and cert-manager are working end-to-end, change the `server` URL to production:

```yaml
server: https://acme-v02.api.letsencrypt.org/directory
```

#### External Secrets — Azure Key Vault

Edit [`infra-as-code/kubernetes/platform/secret-management/external-secret-store.yaml`](infra-as-code/kubernetes/platform/secret-management/external-secret-store.yaml):

Find the `vaultUrl` and set it to your Key Vault's URI (from Phase 1). You can find it in the Azure portal under Key Vault → Overview, or run:

```bash
az keyvault show --resource-group rg-sbx-application-1 --name kv-sbx-application-1 --query properties.vaultUri
```

#### Commit and push

Push all three changes to git. When you bootstrap Argo CD in Phase 3, it will deploy the platform with these values already set.

---

### Phase 3 — Install Argo CD and deploy the platform

> **Optional automation:** To run all Phase 3 steps in one go:
>
> ```bash
> bash scripts/bootstrap-argocd.sh \
>   --resource-group rg-sbx-application-1 \
>   --cluster-name   aks-sbx-application-1
> ```
>
> The script gets credentials, installs Argo CD, waits for readiness, prints the initial admin password, and applies `root.yaml`. You still need to manually port-forward and log in. The manual steps below remain the definitive reference.

#### Get cluster credentials

Download the kubeconfig file so your terminal can talk to the AKS cluster:

```bash
az aks get-credentials --resource-group rg-sbx-application-1 --name aks-sbx-application-1
```

#### Install Argo CD

Create the `argocd` namespace and deploy the stable Argo CD manifest:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### Wait for Argo CD to be ready

```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd
```

#### Get the initial admin password

```bash
argocd admin initial-password -n argocd
```

Save this password — you'll use it to log in to the web UI.

#### Access the Argo CD web UI

Port-forward to the server:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open `https://localhost:8080` in your browser. Log in as `admin` with the password from above.

(Your browser will warn about an untrusted certificate — that's expected for bootstrap. In production, add an Ingress resource with cert-manager once everything is working.)

#### Register the repository (if private)

If your GitHub repository is private, Argo CD needs credentials to read it:

```bash
argocd repo add https://github.com/<org>/<repo> --username <github-user> --password <personal-access-token>
```

For a public repo, skip this step.

#### Bootstrap everything

Apply the root Application, which will recursively deploy all platform services:

```bash
kubectl apply -f infra-as-code/kubernetes/argocd/root.yaml
```

Argo CD immediately starts syncing the entire `infra-as-code/kubernetes/` directory. It will create Applications for each platform service (cert-manager, ingress-nginx, external-dns, monitoring, logging, external-secrets) and deploy them to the cluster.

#### Verify Argo CD is working

```bash
argocd app list
```

All apps should eventually show `Synced` in the Sync Status column and `Healthy` in the Health Status column.

**Note on initial sync:** On first bootstrap, Argo CD syncs all Applications simultaneously. Two resources depend on an operator being ready before they become valid:
- `cluster-issuer.yaml` requires cert-manager CRDs
- `external-secret-store.yaml` requires ESO CRDs

These will initially show as `Failed` — that's expected. Wait for the `cert-manager` and `external-secrets` Applications to reach `Healthy`, then run:

```bash
argocd app sync cluster-root
```

Everything should reach `Synced`/`Healthy` on the second pass.

---

### Phase 4 — Deploy your first application

Now the platform is ready. Deploy a real containerised application.

#### Create your application folder

Copy the template and rename it to your service:

```bash
cp -r infra-as-code/kubernetes/apps/service infra-as-code/kubernetes/apps/<your-service-name>
cd infra-as-code/kubernetes/apps/<your-service-name>
```

#### Configure the Argo CD Application

Edit `application.yaml`:

```yaml
metadata:
  name: <your-service-name>           # Change to your service name
spec:
  source:
    path: infra-as-code/kubernetes/apps/<your-service-name>/overlays/sandbox  # Update path
  destination:
    namespace: <target-namespace>     # Change to your team namespace (e.g. team-analytics)
```

#### Fill in the Kubernetes manifests

Edit `base/deployment.yaml`:

```yaml
spec:
  containers:
    - name: app
      image: <your-container-image>    # Your Docker image
      ports:
        - containerPort: 8080           # Port your app listens on
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "500m"
          memory: "512Mi"
```

Edit `base/service.yaml` to expose the deployment as a ClusterIP service.

Edit `base/kustomization.yaml` to list all the base resources:

```yaml
resources:
  - deployment.yaml
  - service.yaml
  - hpa.yaml
  - pdb.yaml
  - networkpolicy.yaml
```

#### Create the Kustomize overlay

Create `overlays/sandbox/kustomization.yaml` to patch the image tag and replica count for the sandbox environment:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

images:
  - name: app
    newTag: "v1.0.0"  # Tag of your image in the sandbox

replicas:
  - name: app
    count: 1  # Run 1 replica in sandbox
```

#### Add an Ingress (for public access)

If your service needs a public URL, add an Ingress resource to `base/`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <your-service-name>
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    # ^ Tells cert-manager to auto-issue a certificate for this domain
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - <your-service-name>.k8s.example.com
      secretName: <your-service-name>-tls
  rules:
    - host: <your-service-name>.k8s.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <your-service-name>
                port:
                  number: 8080
```

#### Deploy

Commit and push your changes:

```bash
git add infra-as-code/kubernetes/apps/<your-service-name>
git commit -m "Add <your-service-name> application"
git push
```

Argo CD will detect the new Application within ~3 minutes and deploy it. To sync immediately:

```bash
argocd app sync cluster-root
```

Verify the deployment:

```bash
argocd app get <your-service-name>
```

Once it shows `Synced`/`Healthy`, access your application at:

```
https://<your-service-name>.k8s.example.com
```

---

## Day-to-day workflows

### Creating a new Terraform module

Use the `tf-architect` skill in Claude Code:

```
use tf-architect to scaffold an Azure Key Vault module
```

The skill generates: `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `terraform.tf`, `providers.tf`, `Taskfile.yml`, and `environments/<env>.tfvars`.

Modules may also include a `tests/` directory with `.tftest.hcl` files. Run tests with `terraform test` from the module directory.

### Scaffolding a new deployment

Use `tf-architect`:

```
use tf-architect to scaffold a sandbox deployment of the storage-account module
```

### Setting up CI/CD for a Terraform deployment

Use the `github-actions-cicd` skill:

```
use github-actions-cicd to set up a plan workflow for the sandbox deployment
```

The skill produces:
- `.github/workflows/_terraform-plan.yml` — reusable workflow
- `.github/workflows/terraform-plan.yml` — caller scoped to your deployment path

### Local development (Terraform)

Each deployment directory has a `Taskfile.yml`:

```bash
cd infra-as-code/terraform/solutions/sandbox

task validate   # terraform init (no backend) + validate
task fmt        # terraform fmt -recursive
task lint       # tflint --recursive
task security   # tfsec security scan
task plan       # terraform init (inline backend config) + plan
task apply      # terraform init (inline backend config) + apply
task all        # runs fmt → validate → lint
```

Override the environment with `ENV=<env>` (default: `sbx`):

```bash
ENV=can task plan
```

### Adding a platform service (Kubernetes)

1. Create a folder under `infra-as-code/kubernetes/platform/<service-name>/`.
2. Add `application.yaml` with the Argo CD Application manifest (specifying the Helm chart repo URL, chart name, version, and values).
3. Add a `namespace.yaml` if the service needs its own namespace (and reference it in `platform/namespaces/kustomization.yaml`).
4. Commit and push. The root Argo CD Application detects the new `application.yaml` within its sync interval (default 3 minutes) and deploys the service. To sync immediately: `argocd app sync cluster-root`.

### Adding an application workload

1. Copy `infra-as-code/kubernetes/apps/service` to `apps/<service-name>`.
2. Fill in `application.yaml` — set the service name, namespace, and overlay path.
3. Fill in the base manifests (deployment, service, etc.) with your container image and config.
4. Create `overlays/sandbox/kustomization.yaml` with patches for the image tag and replica count.
5. Add an Ingress resource if the service needs a public URL (reference the `ClusterIssuer` by name in the annotation).
6. Commit and push. Argo CD detects the new Application within ~3 minutes and deploys it. To sync immediately: `argocd app sync cluster-root`.

---

## Cleanup / teardown

When you are done with the sandbox, tear down resources in this order.

### 1 — Destroy Terraform-managed resources

```bash
cd infra-as-code/terraform/solutions/sandbox
task destroy
```

This runs `terraform destroy` with the same backend config used by `task plan` and `task apply`. Confirm the plan when prompted.

### 2 — Delete the Terraform state backend

Once all managed resources are gone, delete the state storage account:

```bash
az group delete --name rg-sbx-platform-terraform-state --yes
```

This removes the resource group, storage account, and `tfstate` container.

> **Order matters.** Always destroy Terraform resources before deleting the state backend. Deleting the backend first loses the state file.

---

## CI/CD pipelines

### Terraform validation (active)

#### `terraform-plan-sandbox.yml` (PR trigger)

Triggers on pull requests to `main` that change files under `infra-as-code/terraform/solutions/sandbox/**`.

| Job | Steps |
|-----|-------|
| `validate` | install tools, fmt check, tflint, `terraform init -backend=false`, `terraform validate`, tfsec |
| `plan` | OIDC init (inline backend config), `terraform plan`, plan comment on PR, artifact upload |

#### `terraform-apply-sandbox.yml` (merge trigger)

Triggers on pushes to `main` that change files under `infra-as-code/terraform/solutions/sandbox/**`.

| Job | Steps |
|-----|-------|
| `apply` | OIDC init (inline backend config), `terraform apply` using the plan artifact from the PR |

To add CI/CD for a new deployment:

```
use github-actions-cicd to set up plan and apply workflows for <your deployment path>
```

### Kubernetes validation (active)

#### `kubernetes-validate-sandbox.yml` (PR trigger)

Triggers on pull requests to `main` that change files under `infra-as-code/kubernetes/**`.

Runs schema validation with `kubeconform` (catches typos in field names, wrong types, missing required fields) and `helm lint` on any charts in `charts/`.

---

## Next steps

This setup is complete enough to bootstrap a working cluster, but these enhancements are useful for production use:

- **Argo CD Ingress** — The Argo CD web UI is currently only accessible via port-forward. Create an Ingress resource (once cert-manager is working) for persistent access.
- **Production hardening** — Enable SOPS secret encryption, add NetworkPolicy rules, enforce Pod Security Standards, configure Alertmanager routing, and set Argo CD sync waves for controlled deployment order.
- **Extend the platform** — Add additional platform services (service mesh, real-time logging, advanced monitoring) as your team's needs grow.

---

## Reference

### Understanding the Kubernetes directory

#### Background: what is Kubernetes and Helm?

**Kubernetes** is a platform for running containerised applications (Docker images) at scale. It handles restarting crashed containers, scaling services up and down, and routing network traffic between services. You describe what you want (e.g. "run 3 copies of this container") in YAML files, and Kubernetes makes it happen.

**Helm** is the package manager for Kubernetes — think of it like `apt`, `brew`, or `npm` but for cluster software. A **chart** is a Helm package: a bundle of YAML templates that installs a piece of software (e.g. an ingress controller, a monitoring stack). Charts are published to **chart repositories**, which are like npm registries for Kubernetes software.

**Argo CD** is what connects this Git repo to the cluster. It reads the YAML files in `infra-as-code/kubernetes/` and applies them to the cluster, installing Helm charts and deploying applications automatically.

#### File types explained

| File | What it does in plain English |
|------|-------------------------------|
| `application.yaml` | An Argo CD Application manifest. Tells Argo CD which Helm chart (or Kustomize overlay) to install, at which version, and with which values. |
| `namespace.yaml` | Creates a logical partition inside the cluster. Namespaces are like folders — they keep resources for different teams or services separated so they don't interfere with each other. |
| `cluster-issuer.yaml` | Tells cert-manager (the HTTPS certificate tool) how and where to request TLS certificates for your domains. |
| `external-secret-store.yaml` | Tells the External Secrets Operator where secrets are stored (Azure Key Vault) so it can copy them into the cluster as Kubernetes secrets. |
| `kustomization.yaml` | A list of YAML files to apply together as a group, used by the Kustomize tool. Think of it as an index or manifest file. |

#### What each tool does and why it exists

**`platform/`** — Software that the whole cluster depends on. Installed and managed by the platform team. These tools handle cross-cutting concerns like HTTPS, DNS, and monitoring so that individual applications don't have to solve these problems themselves.

- **`cert-manager/`** — Automatically obtains and renews HTTPS/TLS certificates (the padlock in your browser's address bar) from Let's Encrypt. Without this, you would need to manually request, download, and rotate certificates for every domain your services use. With cert-manager, you add a single annotation to an Ingress resource and the certificate is handled for you.
  - `application.yaml` — Argo CD Application manifest that installs cert-manager into the cluster
  - `cluster-issuer.yaml` — Configures cert-manager to use Let's Encrypt (currently staging/test — switch to production once DNS is working). Fill in your email address here; Let's Encrypt uses it to notify you about expiring certificates.

- **`external-dns/`** — Automatically creates and updates DNS records in Azure DNS when you deploy a service. Without this, every time you deploy a new service with a domain name, someone would need to manually log into Azure and create an `A` record pointing to the cluster's IP. ExternalDNS watches for Ingress resources and does this automatically.
  - `application.yaml` — Argo CD Application manifest that installs ExternalDNS
  - `values.yaml` — Configuration for Azure DNS access (resourceGroup, tenantId, subscriptionId)

- **`ingress-nginx/`** — The cluster's front door for web traffic. When a request arrives at the cluster's public IP address, ingress-nginx reads the URL and routes it to the correct service (e.g. requests to `api.mycompany.com` go to the API service, requests to `app.mycompany.com` go to the frontend). Without an ingress controller, every service would need its own public IP address, which is expensive and hard to manage.

- **`monitoring/`** — Installs the kube-prometheus-stack, which includes:
  - **Prometheus** — scrapes metrics (CPU, memory, request rates, error rates) from all services every few seconds and stores them
  - **Grafana** — provides a web dashboard for viewing those metrics as graphs and charts
  - **Alertmanager** — sends alerts (email, Slack, PagerDuty) when metrics cross thresholds you define

- **`logging/`** — Installs **Loki**, which collects log output from all running containers and makes it searchable. Without this, viewing logs requires connecting directly to individual pods with `kubectl logs`. With Loki, all logs are centralised and queryable through Grafana.

- **`external-secrets/`** — Installs the **External Secrets Operator (ESO)**. ESO reads secrets from Azure Key Vault (where they're stored securely) and makes them available inside the cluster as Kubernetes secrets, keeping them out of Git entirely.

- **`secret-management/`** — Contains the configuration for ESO. Tells ESO where to find your Key Vault and how to map secrets into the cluster.
  - `external-secret-store.yaml` — ClusterSecretStore pointing at your Azure Key Vault

- **`namespaces/`** — Creates the Kubernetes namespaces that the platform services run in. These must be created before Helm installs software into them.

- **`rbac/`** — Role-Based Access Control. Defines who is allowed to do what inside the cluster. For example, an on-call engineer might have read access to see what's running but not permission to delete anything.

**`tenants/`** — One folder per team. Each team gets their own namespace (a private area of the cluster) and a `RoleBinding` that gives team members permission to deploy into that namespace without needing platform team involvement. This is how you give teams self-service access without giving them access to the whole cluster.

**`apps/`** — Your organisation's own applications (not third-party software). Each application has:
  - `base/` — the core Kubernetes resources: Deployment (runs the container), Service (makes it reachable inside the cluster), HPA (auto-scaling), PDB (ensures availability during updates), and NetworkPolicy (firewall rules between services)
  - `overlays/{env}/` — environment-specific overrides using **Kustomize**, a tool for customising YAML without duplicating it. For example, sandbox might run 1 replica of the service and production might run 5 — the overlay patches just that value without copying the entire base.

**`charts/`** — Helm charts that your team has written and owns. Only add a chart here if your team maintains it. Software written by others (cert-manager, ingress-nginx, etc.) is consumed by referencing their published charts in Application manifests — you never copy third-party charts into this repo.

### AI skills

All skills are invoked through Claude Code. In VS Code, use the chat panel. In the terminal, run `claude` from the repo root.

| Skill | When to use | How to invoke |
|-------|-------------|---------------|
| `tf-architect` | Scaffold a new module or deployment | `use tf-architect to scaffold...` |
| `github-actions-cicd` | Generate plan/apply workflows | `use github-actions-cicd to set up CI/CD for...` |
| `tf-code-reviewer` | Review .tf files against standards | `use tf-code-reviewer to review...` |
| `naming-checker` | Validate Azure resource naming | `use naming-checker to check...` |

`CLAUDE.md` is loaded automatically and configures all skills — no manual setup required.

### Standards

All code is written and reviewed against:

| File | Purpose |
|------|---------|
| [`standards/templates/terraform-authoring-guide.md`](standards/templates/terraform-authoring-guide.md) | Module structure, naming, variables, outputs, tagging |
| [`standards/templates/terraform-standards.md`](standards/templates/terraform-standards.md) | Single source of truth — review rules, formatting, naming, security, AVM, testing |
| [`standards/templates/github-actions-best-practices.md`](standards/templates/github-actions-best-practices.md) | Workflow structure, OIDC, SHA pinning |
| [`standards/templates/naming-conventions.md`](standards/templates/naming-conventions.md) | Azure resource naming rules |
| [`standards/templates/kubernetes-pod-best-practices.md`](standards/templates/kubernetes-pod-best-practices.md) | Pod spec conventions, resource limits, probes |

#### Required tags on every Terraform resource

```hcl
tags = local.common_tags   # defined in locals.tf

locals {
  common_tags = {
    costCenter  = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = var.solution
  }
}
```

#### Naming pattern

```
{type}-{environment}-{solution}   # resource groups, vnets, AKS clusters, etc.
st{environment}{solution}          # storage accounts (no hyphens, max 24 chars)
```

### External links

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [HashiCorp style guide](https://developer.hashicorp.com/terraform/language/style)
- [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/)
- [Argo CD app-of-apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Argo CD Helm integration](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
- [cert-manager documentation](https://cert-manager.io/docs/)
- [ExternalDNS on Azure](https://kubernetes-sigs.github.io/external-dns/latest/tutorials/azure/)
- [External Secrets Operator](https://external-secrets.io/latest/)
- [tflint azurerm ruleset](https://github.com/terraform-linters/tflint-ruleset-azurerm)
- [tfsec rules](https://aquasecurity.github.io/tfsec/)
