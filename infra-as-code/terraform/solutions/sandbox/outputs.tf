output "key_vault_uri" {
  description = "The URI of the Key Vault. Copy this value into platform/secret-management/external-secret-store.yaml vaultUrl."
  value       = module.keyvault.uri
}

output "kubernetes_cluster_id" {
  description = "The ID of the AKS cluster."
  value       = module.aks.resource_id
}

output "kubernetes_cluster_name" {
  description = "The name of the AKS cluster."
  value       = module.aks.name
}

output "kubernetes_identity_principal_id" {
  description = "The principal ID of the AKS user-assigned managed identity."
  value       = module.user_assigned_identity.principal_id
}

output "kubernetes_identity_client_id" {
  description = "The client ID of the AKS user-assigned managed identity. Pass to configure-platform.sh --client-id."
  value       = module.user_assigned_identity.client_id
}

output "kubernetes_oidc_issuer_url" {
  description = "The OIDC issuer URL of the AKS cluster."
  value       = module.aks.oidc_issuer_profile_issuer_url
}

output "dns_resource_group_name" {
  description = "The name of the DNS resource group."
  value       = azurerm_resource_group.dns.name
}

output "dns_zone_name" {
  description = "The name of the DNS zone."
  value       = module.dns_zone.name
}

output "dns_zone_name_servers" {
  description = "The name servers for the DNS zone. Delegate these from your domain registrar."
  value       = module.dns_zone.name_servers
}

output "resource_group_id" {
  description = "The ID of the shared resource group."
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "The name of the shared resource group."
  value       = azurerm_resource_group.main.name
}

