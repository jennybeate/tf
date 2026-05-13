moved {
  from = module.keyvault.module.this.azurerm_key_vault.this
  to   = module.keyvault.azurerm_key_vault.this
}

moved {
  from = module.dns_zone.module.dns_zone.azurerm_dns_zone.zone
  to   = module.dns_zone.azurerm_dns_zone.zone
}
