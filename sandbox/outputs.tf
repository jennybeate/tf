output "resource_group_name" {
  description = "Name of the sandbox resource group."
  value       = azurerm_resource_group.sandbox.name
}

output "storage_account_id" {
  description = "Resource ID of the sandbox storage account."
  value       = module.storage_account.id
}

output "storage_account_name" {
  description = "Name of the sandbox storage account."
  value       = module.storage_account.name
}
