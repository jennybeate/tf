output "kubernetes_cluster_id" {
  description = "The ID of the AKS cluster."
  value       = module.kubernetes.cluster_id
}

output "kubernetes_cluster_name" {
  description = "The name of the AKS cluster."
  value       = module.kubernetes.cluster_name
}

output "kubernetes_identity_principal_id" {
  description = "The principal ID of the AKS user-assigned managed identity."
  value       = module.kubernetes.identity_principal_id
}

output "resource_group_id" {
  description = "The ID of the shared resource group."
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "The name of the shared resource group."
  value       = azurerm_resource_group.main.name
}

output "storage_account_id" {
  description = "The ID of the storage account."
  value       = module.storage_account.storage_account_id
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = module.storage_account.storage_account_name
}

output "storage_account_primary_connection_string" {
  description = "The primary connection string for the storage account."
  value       = module.storage_account.storage_account_primary_connection_string
  sensitive   = true
}
