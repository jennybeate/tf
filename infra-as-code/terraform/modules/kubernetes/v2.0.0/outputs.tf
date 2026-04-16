output "cluster_id" {
  description = "The ID of the AKS cluster."
  value       = module.aks.resource_id
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = module.aks.name
}

output "identity_client_id" {
  description = "The client ID of the user-assigned managed identity."
  value       = module.user_assigned_identity.client_id
}

output "identity_id" {
  description = "The resource ID of the user-assigned managed identity."
  value       = module.user_assigned_identity.resource_id
}

output "identity_principal_id" {
  description = "The principal ID of the user-assigned managed identity. Used for RBAC assignments."
  value       = module.user_assigned_identity.principal_id
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster. Use to configure kubectl."
  value       = module.aks.kube_config
  sensitive   = true
}
