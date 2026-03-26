output "id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.main.name
}

output "primary_access_key" {
  description = "Primary access key for the storage account."
  sensitive   = true
  value       = azurerm_storage_account.main.primary_access_key
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint URL."
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_connection_string" {
  description = "Primary connection string for the storage account."
  sensitive   = true
  value       = azurerm_storage_account.main.primary_connection_string
}

output "primary_dfs_endpoint" {
  description = "Primary Data Lake Storage Gen2 endpoint URL."
  value       = azurerm_storage_account.main.primary_dfs_endpoint
}

output "primary_file_endpoint" {
  description = "Primary file service endpoint URL."
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "principal_id" {
  description = "Principal ID of the system-assigned managed identity. Null when system_assigned_identity_enabled is false."
  value       = var.system_assigned_identity_enabled ? azurerm_storage_account.main.identity[0].principal_id : null
}

output "private_endpoint_id" {
  description = "Resource ID of the private endpoint. Null when no private endpoint is configured."
  value       = var.private_endpoint != null ? azurerm_private_endpoint.main[0].id : null
}

output "private_endpoint_ip_address" {
  description = "Private IP address assigned to the private endpoint. Null when no private endpoint is configured."
  value       = var.private_endpoint != null ? azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address : null
}
