variables {
  cost_center  = "cc-0000"
  environment  = "sbx"
  location     = "norwayeast"
  owner        = "platform-team"
  solution     = "test-aks"
}

run "aks_cluster_uses_user_assigned_identity" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.main.identity[0].type == "UserAssigned"
    error_message = "AKS cluster must use a UserAssigned managed identity."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].enable_auto_scaling == true
    error_message = "AKS default node pool must have autoscaling enabled."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].min_count >= 1
    error_message = "AKS default node pool minimum node count must be at least 1."
  }
}
