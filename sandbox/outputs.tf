output "resource_group_id" {
  description = "The ID of the resource group."
  value       = module.storage_account.resource_group_id
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = module.storage_account.resource_group_name
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
