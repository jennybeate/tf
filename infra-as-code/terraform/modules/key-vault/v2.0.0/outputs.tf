output "name" {
  description = "The name of the Key Vault."
  value       = module.this.name
}

output "resource_id" {
  description = "The Azure resource ID of the Key Vault."
  value       = module.this.resource_id
}

output "uri" {
  description = "The URI of the Key Vault. Required by External Secrets Operator ClusterSecretStore."
  value       = module.this.uri
}
