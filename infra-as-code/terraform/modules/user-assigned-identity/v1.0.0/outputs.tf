output "identity_client_id" {
  description = "The client ID of the user-assigned managed identity."
  value       = module.user_assigned_identity.client_id
}

output "identity_id" {
  description = "The resource ID of the user-assigned managed identity."
  value       = module.user_assigned_identity.resource_id
}

output "identity_name" {
  description = "The name of the user-assigned managed identity."
  value       = module.user_assigned_identity.resource_name
}

output "identity_principal_id" {
  description = "The principal ID of the user-assigned managed identity. Used for RBAC assignments."
  value       = module.user_assigned_identity.principal_id
}
