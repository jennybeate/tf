locals {
  root_app = yamldecode(file("${path.module}/../../../gitops/argocd/root.yaml"))
  root_app_hooked = merge(local.root_app, {
    metadata = merge(local.root_app.metadata, {
      annotations = {
        "helm.sh/hook"               = "post-install,post-upgrade"
        "helm.sh/hook-delete-policy" = "before-hook-creation"
      }
    })
  })
}

data "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  resource_group_name = var.cluster_resource_group
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600
  wait             = true

  values = [
    yamlencode({
      extraObjects = [local.root_app_hooked]
    })
  ]
}
