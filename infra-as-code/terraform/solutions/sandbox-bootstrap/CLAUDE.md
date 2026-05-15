# Sandbox bootstrap Terraform solution

Installs Argo CD into the sandbox cluster via the Helm provider. This solution runs after `sandbox/` has been applied and the AKS cluster exists.

**State:** `sandbox-bootstrap/terraform.tfstate` in storage account `stsbxplatformtfstate`, container `tfstate`

## Dependency on the cluster

The Helm provider contacts the cluster API during both `plan` and `apply`. The sandbox AKS cluster must be running and reachable before this solution can plan successfully. If the cluster is unreachable, `terraform plan` fails with a kubelogin error — this is expected, not a code bug.

## What it does

1. Reads `gitops/sandbox/argocd/root.yaml` via `file()` at plan time
2. Installs the `argo-cd` Helm chart into the `argocd` namespace
3. Passes `root.yaml` as an `extraObjects` value so Argo CD creates the `cluster-root` Application immediately after installation

## Deployment

Changes deploy via PR → pipeline. The trigger workflow `terraform-plan-sandbox-bootstrap.yml` also runs when `terraform-apply-sandbox.yml` completes, so bootstrap re-plans automatically after infrastructure changes.

If the repo is private, Argo CD will fail to sync until the repository is registered. After the first bootstrap apply, run:

```bash
argocd login localhost:8080 --username admin --password <initial-admin-password> --insecure
argocd repo add https://github.com/jennybeate/tf.git --username jennybeate --password <ARGOCD_REPO_TOKEN>
```

## State blob migration note

If this solution's state backend key changes, copy the existing state blob in Azure Storage before the first apply against the new key — otherwise Terraform treats the existing cluster as a fresh deployment.
