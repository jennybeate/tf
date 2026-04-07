# tf-architect skill test

## Invocation

```
use tf-architect — create a Terraform module for an Azure Storage Account for the dev environment
```

## Expected Q&A sequence

The skill must ask Q1–Q5 **one at a time** before generating any code. Expected answers for this test scenario:

| Question | Answer |
|---|---|
| Q1 — naming variables | A) Yes — `environment` and `solution` are sufficient |
| Q2 — environments | A) `dev` |
| Q3 — naming standards | A) Yes |
| Q4 — module versioning | A) Yes — scaffold inside `v1.0.0/` |
| Q5 — capabilities | E) None — basic storage account only |

## Expected output — module files

`modules/storage-account/v1.0.0/` must contain:

| File | Key requirements |
|---|---|
| `terraform.tf` | `required_version = "~> 1.9"`, `required_providers` with `hashicorp/azurerm ~> 4.0` — **no `provider {}` block, no backend block** |
| `main.tf` | `azurerm_storage_account.main` — name via `local.storage_account_name`, `tags = local.common_tags`, `min_tls_version = "TLS1_2"` |
| `variables.tf` | Variables for `cost_center`, `environment`, `location`, `owner`, `solution` — each with `type`, `description`, and `validation` where values are constrained — alphabetical order |
| `outputs.tf` | Discrete outputs (e.g. `id`, `primary_blob_endpoint`) — each with `description` — **not the full resource object** |
| `locals.tf` | `storage_account_name` constructed from vars (no dashes, lowercase, ≤24 chars), `common_tags` map — all locals alphabetical |
| `tests/storage_account.tftest.hcl` | At least one `run` block with `command = plan`, `variables {}` block, and an `assert` |
| `Makefile` | Targets: `validate`, `fmt`, `lint`, `security`, `test`, `all` |

## Expected output — deployment root files

`deployments/storage-account/` must contain:

| File | Key requirements |
|---|---|
| `terraform.tf` | `required_version`, `required_providers`, **and** `backend "azurerm" {}` |
| `providers.tf` | `provider "azurerm" { features {} }` — **only in the deployment root, never in the module** |
| `main.tf` | `module "storage_account"` block with `source = "../../modules/storage-account/v1.0.0"` |
| `variables.tf` | Mirrors module variables |
| `outputs.tf` | Re-exposes module outputs via `module.storage_account.<output>` |
| `environments/dev.tfvars` | Values for all required variables — no secrets |

## Pass criteria

- [ ] Questions asked one at a time — not all at once
- [ ] No `provider {}` block inside the module
- [ ] Storage account name in `locals.tf` contains no dashes and is lowercase
- [ ] `min_tls_version = "TLS1_2"` set on the storage account
- [ ] All variables have `type`, `description`; `environment` has a `validation` block
- [ ] Outputs expose discrete attributes, not the full resource object
- [ ] Test file includes at least one plan-mode `assert`
- [ ] Makefile includes `all` target
- [ ] `environments/dev.tfvars` is generated

## Fail indicators

- Provider block inside the module (`providers.tf` in `modules/`)
- Hardcoded resource names in `main.tf` (names not from locals)
- Missing `common_tags` or tags not applied to the storage account
- All five questions shown simultaneously
- `backend` block missing from deployment root `terraform.tf`
