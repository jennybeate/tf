# IaC Training — Terraform + Kubernetes on Azure

This repo is the starting point for Nimtech infrastructure consultants learning Infrastructure as Code. It provides a working sandbox environment, CI/CD pipelines, team coding standards, and AI-assisted tooling — covering both Terraform (Azure resource provisioning) and Kubernetes/Flux (in-cluster GitOps).

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
│       └── terraform-apply-sandbox.yml  # Sandbox merge trigger — calls _terraform-apply.yml
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
│   └── kubernetes/                      # In-cluster GitOps config (Flux CD)
│       ├── platform/                    # Cluster-wide shared services — owned by platform team
│       │   ├── cert-manager/
│       │   │   ├── helmrepository.yaml  # Flux: registers the Jetstack Helm chart repo
│       │   │   ├── helmrelease.yaml     # Flux: installs cert-manager with CRDs enabled
│       │   │   └── cluster-issuer.yaml  # cert-manager: ClusterIssuer for Let's Encrypt
│       │   ├── external-dns/
│       │   │   ├── helmrepository.yaml  # Flux: registers the ExternalDNS Helm chart repo
│       │   │   └── helmrelease.yaml     # Flux: installs ExternalDNS (Azure DNS provider)
│       │   ├── ingress-nginx/
│       │   │   ├── helmrepository.yaml  # Flux: registers the ingress-nginx Helm chart repo
│       │   │   └── helmrelease.yaml     # Flux: installs ingress-nginx controller
│       │   ├── monitoring/
│       │   │   ├── helmrepository.yaml  # Flux: registers the Prometheus Community repo
│       │   │   └── helmrelease.yaml     # Flux: installs kube-prometheus-stack (Prometheus + Grafana)
│       │   ├── logging/
│       │   │   ├── helmrepository.yaml  # Flux: registers the Grafana Helm chart repo
│       │   │   └── helmrelease.yaml     # Flux: installs Loki for log aggregation
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
│       ├── data-platform/               # Data-specific operators — owned by data engineering team
│       │   └── kafka/
│       │       ├── helmrepository.yaml  # Flux: registers the Strimzi Helm chart repo
│       │       ├── helmrelease.yaml     # Flux: installs Strimzi Kafka operator
│       │       └── namespace.yaml       # Namespace definition for kafka
│       ├── tenants/                     # Per-team namespace isolation and RBAC
│       │   └── team-analytics/
│       │       ├── namespace.yaml       # Namespace for the analytics team
│       │       └── rbac.yaml            # RoleBinding giving the team edit access to their namespace
│       ├── apps/                        # First-party application workloads (Kustomize)
│       │   └── (add per-service folders here — see "Adding an application" below)
│       └── charts/                      # First-party Helm charts (only if the team owns the chart)
│           └── (add per-chart folders here)
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

Running an application on Azure Kubernetes Service (AKS) requires two separate layers of configuration:

| Layer | Tooling | What it does | Where it lives |
|-------|---------|--------------|----------------|
| Azure infrastructure | Terraform | Creates the AKS cluster itself, Key Vault, networking, storage — the Azure resources that appear in the portal | `infra-as-code/terraform/` |
| What runs inside the cluster | Flux (GitOps) | Installs software into the cluster and deploys your applications | `infra-as-code/kubernetes/` |

Think of it like this: Terraform builds the building (the AKS cluster). Everything in `infra-as-code/kubernetes/` furnishes and operates the building (installs the software that runs inside it).

**Why GitOps?** The traditional way to deploy to Kubernetes is to run `kubectl apply` commands manually. GitOps flips this: instead of pushing changes to the cluster, you commit changes to Git, and a tool called **Flux** running inside the cluster pulls them in automatically. The Git repo becomes the single source of truth for what should be running. If someone manually changes something in the cluster, Flux detects the drift and corrects it.

**Terraform** runs on demand (triggered by a PR or pipeline) to create or update Azure resources. **Flux** runs continuously inside the cluster — it checks this repo every few minutes and applies anything that has changed.

---

## Understanding the Kubernetes directory

### Background: what is Kubernetes and Helm?

**Kubernetes** is a platform for running containerised applications (Docker images) at scale. It handles restarting crashed containers, scaling services up and down, and routing network traffic between services. You describe what you want (e.g. "run 3 copies of this container") in YAML files, and Kubernetes makes it happen.

**Helm** is the package manager for Kubernetes — think of it like `apt`, `brew`, or `npm` but for cluster software. A **chart** is a Helm package: a bundle of YAML templates that installs a piece of software (e.g. an ingress controller, a monitoring stack). Charts are published to **chart repositories**, which are like npm registries for Kubernetes software.

**Flux** is what connects this Git repo to the cluster. It reads the YAML files in `infra-as-code/kubernetes/` and applies them to the cluster, installing Helm charts and deploying applications automatically.

### File types explained

| File | What it does in plain English |
|------|-------------------------------|
| `helmrepository.yaml` | Tells Flux where to find a Helm chart registry on the internet (like adding a package source). Must exist before installing anything from that registry. |
| `helmrelease.yaml` | Tells Flux to install a specific Helm chart at a specific version with specific settings. If someone deletes the installed software, Flux reinstalls it automatically. |
| `namespace.yaml` | Creates a logical partition inside the cluster. Namespaces are like folders — they keep resources for different teams or services separated so they don't interfere with each other. |
| `cluster-issuer.yaml` | Tells cert-manager (the HTTPS certificate tool) how and where to request TLS certificates for your domains. |
| `external-secret-store.yaml` | Tells the External Secrets Operator where secrets are stored (Azure Key Vault) so it can copy them into the cluster as Kubernetes secrets. |
| `kustomization.yaml` | A list of YAML files to apply together as a group, used by the Kustomize tool. Think of it as an index or manifest file. |

### What each tool does and why it exists

**`platform/`** — Software that the whole cluster depends on. Installed and managed by the platform team. These tools handle cross-cutting concerns like HTTPS, DNS, and monitoring so that individual applications don't have to solve these problems themselves.

- **`cert-manager/`** — Automatically obtains and renews HTTPS/TLS certificates (the padlock in your browser's address bar) from Let's Encrypt. Without this, you would need to manually request, download, and rotate certificates for every domain your services use. With cert-manager, you add a single annotation to an Ingress resource and the certificate is handled for you.
  - `helmrepository.yaml` — Tells Flux to fetch the cert-manager chart from `https://charts.jetstack.io`
  - `helmrelease.yaml` — Installs cert-manager into the cluster
  - `cluster-issuer.yaml` — Configures cert-manager to use Let's Encrypt (currently staging/test — switch to production once DNS is working). Fill in your email address here; Let's Encrypt uses it to notify you about expiring certificates.

- **`external-dns/`** — Automatically creates and updates DNS records in Azure DNS when you deploy a service. Without this, every time you deploy a new service with a domain name, someone would need to manually log into Azure and create an `A` record pointing to the cluster's IP. ExternalDNS watches for Ingress resources and does this automatically.
  - `helmrelease.yaml` — **Requires configuration before use**: fill in `resourceGroup`, `tenantId`, and `subscriptionId` with the values for the Azure DNS zone you want it to manage.

- **`ingress-nginx/`** — The cluster's front door for web traffic. When a request arrives at the cluster's public IP address, ingress-nginx reads the URL and routes it to the correct service (e.g. requests to `api.mycompany.com` go to the API service, requests to `app.mycompany.com` go to the frontend). Without an ingress controller, every service would need its own public IP address, which is expensive and hard to manage.

- **`monitoring/`** — Installs the kube-prometheus-stack, which includes:
  - **Prometheus** — scrapes metrics (CPU, memory, request rates, error rates) from all services every few seconds and stores them
  - **Grafana** — provides a web dashboard for viewing those metrics as graphs and charts
  - **Alertmanager** — sends alerts (email, Slack, PagerDuty) when metrics cross thresholds you define

- **`logging/`** — Installs **Loki**, which collects log output from all running containers and makes it searchable. Without this, viewing logs requires connecting directly to individual pods with `kubectl logs`. With Loki, all logs are centralised and queryable through Grafana.

- **`secret-management/`** — Contains the configuration for **External Secrets Operator (ESO)**. The problem ESO solves: Kubernetes needs secrets (database passwords, API keys) available inside the cluster, but you should never store real secrets in Git. ESO bridges the gap — it reads secrets from Azure Key Vault (where they're stored securely) and makes them available inside the cluster as Kubernetes secrets, keeping them out of the repo entirely.
  - `external-secret-store.yaml` — **Requires configuration**: fill in the `vaultUrl` with the URI of your Azure Key Vault (found in the Azure portal under the Key Vault's overview page).

- **`namespaces/`** — Creates the Kubernetes namespaces that the platform services run in (`cert-manager`, `external-dns`, `ingress-nginx`, `monitoring`). These must be created before Helm installs software into them.

- **`rbac/`** — Role-Based Access Control. Defines who is allowed to do what inside the cluster. For example, an on-call engineer might have read access to see what's running but not permission to delete anything.

**`data-platform/`** — Software specific to the data platform. Owned by the data engineering team, not the platform team, so changes here don't require platform team review.

- **`kafka/`** — Installs the **Strimzi operator**, which manages Apache Kafka clusters on Kubernetes. Kafka is a message streaming platform used to move data between services at high throughput. Strimzi is an *operator* — a piece of software that knows how to install, configure, scale, and upgrade Kafka, handling the complexity that would otherwise require deep Kafka expertise to manage manually.
  - `helmrepository.yaml` — Registers the Strimzi chart registry with Flux
  - `helmrelease.yaml` — Installs the Strimzi operator into the `kafka` namespace. The `watchNamespaces` setting tells Strimzi to only manage Kafka resources in the `kafka` namespace (a security boundary — it won't touch other namespaces).
  - `namespace.yaml` — Creates the `kafka` namespace

**`tenants/`** — One folder per team. Each team gets their own namespace (a private area of the cluster) and a `RoleBinding` that gives team members permission to deploy into that namespace without needing platform team involvement. This is how you give teams self-service access without giving them access to the whole cluster.

**`apps/`** — Your organisation's own applications (not third-party software). Each application has:
  - `base/` — the core Kubernetes resources: Deployment (runs the container), Service (makes it reachable inside the cluster), HPA (auto-scaling), PDB (ensures availability during updates), and NetworkPolicy (firewall rules between services)
  - `overlays/{env}/` — environment-specific overrides using **Kustomize**, a tool for customising YAML without duplicating it. For example, sandbox might run 1 replica of the service and production might run 5 — the overlay patches just that value without copying the entire base.

**`charts/`** — Helm charts that your team has written and owns. Only add a chart here if your team maintains it. Software written by others (cert-manager, ingress-nginx, etc.) is consumed by referencing their published charts in `helmrelease.yaml` — you never copy third-party charts into this repo.

---

## Prerequisites

| Tool | Install |
|------|---------|
| Azure CLI | [learn.microsoft.com](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| Flux CLI | `curl -s https://fluxcd.io/install.sh | sudo bash` |
| Claude Code | [claude.ai/code](https://claude.ai/code) |

Terraform, tflint, tfsec, and Task are installed via script — versions are pinned in [`scripts/install-tools.sh`](scripts/install-tools.sh):

```bash
bash scripts/install-tools.sh
```

After installing tflint, run `tflint --init` in the repo root to install the azurerm ruleset.

---

## Step 1 — Bootstrap Terraform state (one-time, platform admin)

Terraform state is stored in an Azure Storage Account provisioned by the Bicep bootstrap template. This runs once per subscription before any Terraform deployments.

```bash
# Get your app registration Object ID
az ad sp show --id <AZURE_CLIENT_ID> --query id -o tsv

# Deploy the state backend
az deployment sub create \
  --location norwayeast \
  --template-file infra-as-code/bicep/bootstrap/main.bicep \
  --parameters infra-as-code/bicep/bootstrap/config/parameters/bootstrap.bicepparam \
  --parameters deploymentIdentityObjectId="<object-id>"
```

This creates:
- Resource group: `rg-sbx-platform-terraform-state`
- Storage account: `stsbxplatformtfstate`
- Container: `tfstate`
- RBAC: `Storage Blob Data Owner` for the app registration

---

## Step 2 — GitHub setup (one-time, platform admin)

### Azure OIDC — no long-lived secrets

1. Create an **App Registration** in Entra ID.
2. Under **Certificates & secrets → Federated credentials**, add:
   - Entity type: `Pull request` — used by the plan pipeline
   - Entity type: `Branch`, branch `main` — used by the apply pipeline
3. Grant the app **Contributor** on the sandbox subscription (or scoped resource group).

### Secrets (`Settings → Secrets and variables → Actions → Secrets`)

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Sandbox subscription ID |

### Variables (`Settings → Secrets and variables → Actions → Variables`)

| Variable | Value |
|----------|-------|
| `TF_BACKEND_RESOURCE_GROUP` | `rg-sbx-platform-terraform-state` |
| `TF_BACKEND_STORAGE_ACCOUNT` | `stsbxplatformtfstate` |

> Backend config values are **variables**, not secrets — using `secrets.*` for these silently returns empty.

---

## Step 3 — Authenticate locally

The `Taskfile.yml` constructs backend config from the `ENV` variable (default: `sbx`) — no `backend.hcl` file is needed. Log in with the Azure CLI before running any `task plan` or `task apply`:

```bash
az login
az account set --subscription <AZURE_SUBSCRIPTION_ID>
```

---

## Development workflow

### Creating a new Terraform module

Use the `tf-architect` skill in Claude Code. It walks you through module requirements and generates all files conforming to team standards:

```
use tf-architect to scaffold an Azure Key Vault module
```

The skill generates: `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `terraform.tf`, `providers.tf`, `Taskfile.yml`, and `environments/<env>.tfvars`.

Modules may also include a `tests/` directory with `.tftest.hcl` files — see `key-vault/v1.0.0/tests/` for an example. Run tests with `terraform test` from the module directory.

### Scaffolding a new deployment (e.g. sandbox)

Use `tf-architect` for deployments too — tell it which module to deploy and which environment:

```
use tf-architect to scaffold a sandbox deployment of the storage-account module
```

### Setting up CI/CD for a Terraform deployment

Use the `github-actions-cicd` skill. It asks for the module path, tfvars file, and whether you want an apply workflow, then generates fully standards-compliant workflow files:

```
use github-actions-cicd to set up a plan workflow for the sandbox deployment
```

The skill produces:
- `.github/workflows/_terraform-plan.yml` — reusable workflow (parameterised)
- `.github/workflows/terraform-plan.yml` — caller scoped to your deployment path

### Local development (Terraform)

Each deployment directory has a `Taskfile.yml` with these targets:

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
2. Add `helmrepository.yaml` with the chart source URL and `helmrelease.yaml` with the install config.
3. Add a `namespace.yaml` if the service needs its own namespace (and reference it in `platform/namespaces/kustomization.yaml`).
4. Commit and push. Flux detects the change and reconciles within its configured interval.

### Adding an application workload

1. Create `infra-as-code/kubernetes/apps/<service-name>/base/` with `deployment.yaml`, `service.yaml`, `hpa.yaml`, `pdb.yaml`, `networkpolicy.yaml`, and `kustomization.yaml`.
2. Create `overlays/sandbox/kustomization.yaml` with patches for the sandbox image tag and replica count.
3. Reference the `ClusterIssuer` by name in the `Ingress` annotation — do not add cert-manager config to the app folder.
4. Commit and push.

---

## CI/CD pipeline (Terraform — active)

### `terraform-plan-sandbox.yml` (PR trigger)

Triggers on pull requests to `main` that change files under `infra-as-code/terraform/solutions/sandbox/**`.

| Job | Steps |
|-----|-------|
| `validate` | install tools, fmt check, tflint, `terraform init -backend=false`, `terraform validate`, tfsec |
| `plan` | OIDC init (inline backend config), `terraform plan`, plan comment on PR, artifact upload |

Uses the reusable workflow `_terraform-plan.yml`, which accepts inputs, secrets, and produces outputs — call it from any environment-specific caller workflow.

### `terraform-apply-sandbox.yml` (merge trigger)

Triggers on pushes to `main` that change files under `infra-as-code/terraform/solutions/sandbox/**`.

| Job | Steps |
|-----|-------|
| `apply` | OIDC init (inline backend config), `terraform apply` using the plan artifact from the PR |

Uses the reusable workflow `_terraform-apply.yml`. To add CI/CD for a new deployment, run:

```
use github-actions-cicd to set up plan and apply workflows for <your deployment path>
```

---

## TODO — Kubernetes deployment (not yet active)

The `infra-as-code/kubernetes/` directory is scaffolded but not yet connected to a live cluster. Work through these steps in order — each phase depends on the previous one being complete.

### Phase 1 — Provision Azure infrastructure via Terraform

Before anything can run in Kubernetes, the Azure resources that support it must exist.

- [ ] **Provision the AKS cluster** — confirm the `kubernetes/v2.0.0` Terraform module is wired into `terraform/solutions/sandbox/main.tf` and run `task apply`. AKS is the managed Kubernetes service on Azure — it is the cluster that everything else runs inside.

- [ ] **Deploy Azure Key Vault** — wire the `key-vault/v2.0.0` Terraform module into the sandbox solution and apply it. Key Vault is Azure's secret store — it holds passwords, API keys, and certificates securely. The cluster will read secrets from here via External Secrets Operator rather than storing them in Git.

- [ ] **Grant the cluster permission to read from Key Vault** — AKS creates a managed identity (a system account with no password) for the node pool. After the cluster exists, grant that identity the **Key Vault Secrets User** role on the Key Vault. This is what allows pods in the cluster to read secrets from Key Vault without any credentials hardcoded anywhere.

- [ ] **Grant the cluster permission to manage DNS** — grant the AKS managed identity the **DNS Zone Contributor** role on the resource group containing your Azure DNS zone. This is what allows ExternalDNS to automatically create DNS records when you deploy a service.

  > **DNS zones are almost always centrally managed.** In most enterprise setups, the DNS zone (e.g. `platform.company.com`) lives in a shared/hub subscription — not in the sandbox subscription — and is owned by a central networking or platform team. This has a few practical implications:
  >
  > - The role assignment (`DNS Zone Contributor`) must be created in the **hub subscription**, not the sandbox subscription. A platform admin typically needs to do this, as sandbox engineers rarely have permissions there.
  > - The `resourceGroup` value in `platform/external-dns/helmrelease.yaml` should be the resource group **in the hub subscription** where the DNS zone lives, not the sandbox resource group.
  > - If cross-subscription DNS management is not possible (e.g. permissions are locked down), an alternative is to create a **delegated subdomain** for each environment. The central team creates an NS record in the root zone that delegates `sbx.platform.company.com` to a DNS zone in the sandbox subscription. ExternalDNS then manages only that delegated zone, within the sandbox subscription, without needing hub access.
  > - For initial sandbox testing only, it is acceptable to create a throwaway DNS zone (`sbx.platform.company.com`) directly in the sandbox subscription and point ExternalDNS at that.

### Phase 2 — Install Flux into the cluster (bootstrap)

Flux is the GitOps engine — the software running inside the cluster that watches this repo and applies changes automatically. "Bootstrapping" means installing Flux for the first time.

- [ ] **Get cluster credentials** — download the kubeconfig file that lets your terminal talk to the AKS cluster:
  ```bash
  az aks get-credentials --resource-group rg-sbx-platform --name aks-sbx-platform
  ```

- [ ] **Create a GitHub personal access token (PAT)** — go to GitHub → Settings → Developer settings → Personal access tokens → Generate new token (classic). Give it the `repo` scope. Flux needs this token to read the repo and to write its own bootstrap files back to it.

- [ ] **Run `flux bootstrap`** — this installs the Flux controllers into the cluster and tells Flux where to find its config (this repo, `infra-as-code/kubernetes/` path):
  ```bash
  flux bootstrap github \
    --owner=<your-github-org-or-user> \
    --repository=<this-repo-name> \
    --branch=main \
    --path=infra-as-code/kubernetes \
    --personal
  ```
  After this command runs, Flux commits a small `flux-system/` folder back to the repo (don't delete it — it's how Flux manages itself) and begins reconciling the `kubernetes/` directory.

- [ ] **Verify Flux is working** — run `flux get all`. Every row should eventually show `Ready: True`. If something shows `False`, run `flux logs` to see what went wrong.

### Phase 3 — Fill in the blanks in platform config

The platform service config files have placeholder values that must be filled in before those services will work correctly.

- [ ] **ExternalDNS — add your Azure DNS details** — open [`infra-as-code/kubernetes/platform/external-dns/helmrelease.yaml`](infra-as-code/kubernetes/platform/external-dns/helmrelease.yaml) and fill in:
  - `resourceGroup` — the Azure resource group that contains your DNS zone (find it in the Azure portal under DNS Zones)
  - `tenantId` — your Entra ID tenant ID (`az account show --query tenantId`)
  - `subscriptionId` — your Azure subscription ID (`az account show --query id`)

- [ ] **cert-manager — add your email address** — open [`infra-as-code/kubernetes/platform/cert-manager/cluster-issuer.yaml`](infra-as-code/kubernetes/platform/cert-manager/cluster-issuer.yaml) and replace `jenny@nimtech.no` with the correct contact email. Let's Encrypt uses this to notify you before certificates expire. The file currently points at the Let's Encrypt **staging** environment, which issues test certificates that browsers don't trust — this is intentional for initial testing. Once you confirm DNS and cert-manager are working end-to-end, change the `server` URL to the production Let's Encrypt endpoint (`https://acme-v02.api.letsencrypt.org/directory`).

- [ ] **Install External Secrets Operator** — ESO is not yet in the `platform/` directory. Add it: create `platform/external-secrets/helmrepository.yaml` (source: `https://charts.external-secrets.io`) and `platform/external-secrets/helmrelease.yaml`. ESO must be installed before the `ClusterSecretStore` in `secret-management/` becomes active.

- [ ] **External Secrets — add your Key Vault URI** — open [`infra-as-code/kubernetes/platform/secret-management/external-secret-store.yaml`](infra-as-code/kubernetes/platform/secret-management/external-secret-store.yaml) and fill in `vaultUrl` with the URI of the Key Vault created in Phase 1. You can find it in the Azure portal on the Key Vault overview page (it looks like `https://kv-sbx-platform.vault.azure.net`).

- [ ] **Verify the full chain** — deploy a test service with a public domain name and confirm: ExternalDNS created a DNS record → cert-manager issued a certificate → the service is reachable over HTTPS in a browser.

### Phase 4 — Add GitHub Actions validation for Kubernetes changes

Currently there are no automated checks on the `kubernetes/` directory. A typo in a YAML file merges silently and Flux will fail when it tries to apply it. Add a validation pipeline to catch errors on PRs before they reach `main`.

Note: unlike Terraform (where `terraform plan` shows exactly what will change), Kubernetes validation is mostly schema checking — confirming YAML is structurally valid. Deeper "what will this actually do" checking requires cluster credentials.

- [ ] **Create `_kubernetes-validate.yml`** — a reusable validation workflow (following the same pattern as `_terraform-plan.yml`) that:
  - Runs `kubeconform` to check all YAML files against official Kubernetes API schemas — catches typos in field names, wrong types, missing required fields
  - Runs `helm lint` on any charts in `charts/` — checks chart structure and template syntax
  - Optionally runs `flux diff` to show what the cluster would change (requires cluster credentials via OIDC)

- [ ] **Create `kubernetes-validate-sandbox.yml`** — a PR trigger that calls `_kubernetes-validate.yml` on any change under `infra-as-code/kubernetes/**`. Without this, bad YAML merges silently.

- [ ] **Add cluster credentials to GitHub Actions** — for `flux diff` to work in CI, add a step that runs `az aks get-credentials` using the existing OIDC identity (the same one Terraform uses). No new secrets needed if the existing app registration has AKS read access.

- [ ] **(Optional) Force immediate reconciliation on merge** — by default Flux checks the repo every 1–10 minutes. To apply changes immediately after merge, add a step to your apply pipeline: `flux reconcile source git flux-system`. This is a nice-to-have for fast feedback but not required.

### Phase 5 — Harden for production

These steps are not needed for a working sandbox but are required before running production workloads.

- [ ] **Encrypt secrets in Git with SOPS** — if you ever need to commit a secret value to the repo (e.g. a bootstrap token), encrypt it first using SOPS and an Azure Key Vault key. Flux supports SOPS natively and will decrypt on the fly. Never commit plaintext secrets.
- [ ] **Add NetworkPolicy to every namespace** — by default, all pods in a Kubernetes cluster can talk to each other freely. NetworkPolicy lets you define firewall rules between namespaces and services, so a compromised service can't reach everything else.
- [ ] **Enable Pod Security Standards** — enforce the `restricted` security policy on all non-system namespaces. This prevents pods from running as root, mounting host paths, or using privileged containers.
- [ ] **Configure Alertmanager** — open `platform/monitoring/helmrelease.yaml` and configure the `alertmanager` values section to route alerts to your team's Slack channel or on-call tool (PagerDuty, OpsGenie, etc.).
- [ ] **Set Flux reconciliation order** — add `dependsOn` fields to the Flux `Kustomization` objects so that `data-platform` and `apps` wait for `platform` to be fully healthy before reconciling. This prevents failures during cold-start when platform services aren't ready yet.

---

## AI skills (Claude Code)

All skills are invoked through Claude Code. In VS Code, use the chat panel. In the terminal, run `claude` from the repo root.

| Skill | When to use | How to invoke |
|-------|-------------|---------------|
| `tf-architect` | Scaffold a new module or deployment | `use tf-architect to scaffold...` |
| `github-actions-cicd` | Generate plan/apply workflows | `use github-actions-cicd to set up CI/CD for...` |
| `tf-code-reviewer` | Review .tf files against standards | `use tf-code-reviewer to review...` |
| `naming-checker` | Validate Azure resource naming | `use naming-checker to check...` |

`CLAUDE.md` is loaded automatically and configures all skills — no manual setup required.

---

## Standards

All code is written and reviewed against:

| File | Purpose |
|------|---------|
| [`standards/templates/terraform-authoring-guide.md`](standards/templates/terraform-authoring-guide.md) | Module structure, naming, variables, outputs, tagging |
| [`standards/templates/terraform-standards.md`](standards/templates/terraform-standards.md) | Single source of truth — review rules, formatting, naming, security, AVM, testing |
| [`standards/templates/github-actions-best-practices.md`](standards/templates/github-actions-best-practices.md) | Workflow structure, OIDC, SHA pinning |
| [`standards/templates/naming-conventions.md`](standards/templates/naming-conventions.md) | Azure resource naming rules |
| [`standards/templates/kubernetes-pod-best-practices.md`](standards/templates/kubernetes-pod-best-practices.md) | Pod spec conventions, resource limits, probes |

### Required tags on every Terraform resource

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

### Naming pattern

```
{type}-{environment}-{solution}   # resource groups, vnets, AKS clusters, etc.
st{environment}{solution}          # storage accounts (no hyphens, max 24 chars)
```

---

## References

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [HashiCorp style guide](https://developer.hashicorp.com/terraform/language/style)
- [Flux CD documentation](https://fluxcd.io/flux/)
- [Flux multi-tenancy guide](https://fluxcd.io/flux/guides/multi-tenancy/)
- [cert-manager documentation](https://cert-manager.io/docs/)
- [ExternalDNS on Azure](https://kubernetes-sigs.github.io/external-dns/latest/tutorials/azure/)
- [External Secrets Operator](https://external-secrets.io/latest/)
- [tflint azurerm ruleset](https://github.com/terraform-linters/tflint-ruleset-azurerm)
- [tfsec rules](https://aquasecurity.github.io/tfsec/)
