module "dns_zone" {
  source  = "Azure/avm-res-network-dnszone/azurerm"
  version = "0.2.1"

  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
  enable_telemetry    = false
  tags                = local.common_tags
}
