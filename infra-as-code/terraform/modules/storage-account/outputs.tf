output "storage_account_id" {
  description = "The ID of the storage account."
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_connection_string" {
  description = "The primary connection string for the storage account."
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}
