output "name" {
  description = "The name (domain) of the DNS zone."
  value       = var.dns_zone_name
}

output "name_servers" {
  description = "The name servers for the DNS zone. Delegate these from your domain registrar."
  value       = module.dns_zone.name_servers
}

output "resource_id" {
  description = "The resource ID of the DNS zone."
  value       = module.dns_zone.resource_id
}
