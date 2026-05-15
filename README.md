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
├── docs/
│   ├── sandbox/
│   │   └── README.md                    # Full sandbox setup and day-to-day guide
│   └── prod/
│       └── README.md                    # Production setup (approval gates, prod-specific concerns)
├── gitops/                              # GitOps config (Argo CD) — one folder per environment
│   └── sandbox/                         # Sandbox environment manifests
│       ├── argocd/                      # All Argo CD Application manifests
│       │   ├── root.yaml                # cluster-root definition — applied at bootstrap; excluded from its own sync
│       │   ├── cert-manager.yaml
│       │   ├── cluster-issuer.yaml
│       │   ├── external-dns.yaml
│       │   ├── external-secrets.yaml
│       │   ├── external-secret-store.yaml
│       │   ├── ingress-nginx.yaml
│       │   ├── logging.yaml
│       │   ├── monitoring.yaml
│       │   ├── namespaces.yaml
│       │   ├── rbac.yaml
│       │   ├── tenants.yaml
│       │   └── hello-world.yaml
│       ├── platform/                    # Cluster-wide shared services — owned by platform team
│       │   ├── cert-manager/
│       │   ├── external-dns/
│       │   ├── ingress-nginx/
│       │   ├── monitoring/
│       │   ├── logging/
│       │   ├── external-secrets/
│       │   ├── secret-management/
│       │   ├── namespaces/
│       │   └── rbac/
│       ├── tenants/                     # Per-team namespace isolation and RBAC
│       └── apps/                        # First-party application workloads (Kustomize)
├── infra-as-code/
│   ├── bicep/
│   │   └── bootstrap/                   # One-time Bicep deployment (run before Terraform)
│   │       ├── main.bicep               # Provisions Terraform remote state storage
│   │       └── config/parameters/
│   │           └── bootstrap.bicepparam
│   └── terraform/
│       ├── modules/                     # Reusable, versioned Terraform modules
│       │   ├── key-vault/v1.0.0/
│       │   ├── key-vault/v2.0.0/
│       │   ├── kubernetes/v1.0.0/
│       │   ├── kubernetes/v2.0.0/
│       │   └── storage-account/
│       └── solutions/
│           ├── sandbox/                 # AKS cluster, Key Vault, DNS zone, network resources
│           └── sandbox-bootstrap/       # Installs Argo CD into the cluster via Helm
├── scripts/
│   ├── install-tools.sh                 # Installs all required tools with pinned versions
│   ├── configure-platform.sh            # Patches platform YAML files for an environment
│   └── bootstrap-argocd.sh             # Manual Argo CD bootstrap (fallback — pipeline is preferred)
├── skills/                              # Claude Code AI skills — invoked through Claude Code
│   ├── code-reviewer/
│   ├── devcontainer-builder/
│   ├── github-actions-cicd/
│   ├── naming-checker/
│   ├── repo-onboarding/
│   ├── tf-architect/
│   └── tf-code-reviewer/
├── standards/
│   └── templates/
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
| Azure infrastructure | Terraform | Creates the AKS cluster itself, Key Vault, DNS zone, networking | `infra-as-code/terraform/` |
| What runs inside the cluster | Argo CD (GitOps) | Installs software into the cluster and deploys your applications | `gitops/sandbox/` |

**Why GitOps?** The traditional way to deploy to Kubernetes is to run `kubectl apply` commands manually. GitOps flips this: instead of pushing changes to the cluster, you commit changes to Git, and Argo CD running inside the cluster pulls them in automatically. The Git repo becomes the single source of truth for what should be running. If someone manually changes something in the cluster, Argo CD detects the drift and corrects it.

---

## Install tools

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

---

## Environment setup guides

| Environment | Guide |
|-------------|-------|
| Sandbox | [`docs/sandbox/README.md`](docs/sandbox/README.md) |
| Production | [`docs/prod/README.md`](docs/prod/README.md) |

---

## AI skills

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
| [`standards/templates/terraform-standards.md`](standards/templates/terraform-standards.md) | Review rules, formatting, naming, security, AVM, testing |
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

## External links

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [HashiCorp style guide](https://developer.hashicorp.com/terraform/language/style)
- [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/)
- [Argo CD app-of-apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [cert-manager documentation](https://cert-manager.io/docs/)
- [ExternalDNS on Azure](https://kubernetes-sigs.github.io/external-dns/latest/tutorials/azure/)
- [External Secrets Operator](https://external-secrets.io/latest/)
- [tflint azurerm ruleset](https://github.com/terraform-linters/tflint-ruleset-azurerm)
