output "cluster_id" {
  description = "The ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.name
}

output "identity_client_id" {
  description = "The client ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.main.client_id
}

output "identity_id" {
  description = "The resource ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.main.id
}

output "identity_principal_id" {
  description = "The principal ID of the user-assigned managed identity. Used for RBAC assignments."
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster. Use to configure kubectl."
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}
