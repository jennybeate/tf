output "key_vault_uri" {
  description = "The URI of the Key Vault. Copy this value into platform/secret-management/external-secret-store.yaml vaultUrl."
  value       = module.keyvault.uri
}

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

