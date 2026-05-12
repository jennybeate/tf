resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.common_tags
}

module "kubernetes" {
  source = "../../modules/kubernetes/v2.0.0"

  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  cost_center         = var.cost_center
  environment         = var.environment
  kubernetes_version  = var.kubernetes_version
  location            = azurerm_resource_group.main.location
  node_count_max      = var.node_count_max
  node_count_min      = var.node_count_min
  node_vm_size        = var.node_vm_size
  owner               = var.owner
  solution            = local.solution
}

module "storage_account" {
  source              = "../../modules/storage-account"
  cost_center         = var.cost_center
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  owner               = var.owner
  replication_type    = var.replication_type
  resource_group_name = azurerm_resource_group.main.name
  solution            = local.solution
}

module "keyvault" {
  source              = "../../modules/key-vault/v2.0.0"
  cost_center         = var.cost_center
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  owner               = var.owner
  resource_group_name = azurerm_resource_group.main.name
  solution            = local.solution
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = module.keyvault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.kubernetes.identity_principal_id
}

resource "azurerm_resource_group" "dns" {
  name     = "rg-${var.environment}-dns"
  location = local.location
  tags     = local.common_tags
}

module "dns_zone" {
  source = "../../modules/dns-zone/v1.0.0"

  cost_center         = var.cost_center
  dns_zone_name       = var.dns_zone_name
  environment         = var.environment
  owner               = var.owner
  resource_group_name = azurerm_resource_group.dns.name
  solution            = local.solution
}

resource "azurerm_role_assignment" "aks_dns_contributor" {
  scope                = azurerm_resource_group.dns.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = module.kubernetes.identity_principal_id
}

resource "azurerm_federated_identity_credential" "external_dns" {
  name                      = "external-dns"
  user_assigned_identity_id = module.kubernetes.identity_id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = module.kubernetes.oidc_issuer_url
  subject                   = "system:serviceaccount:external-dns:external-dns"
}