resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.common_tags
}

module "user_assigned_identity" {
  source              = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version             = "0.5.0"
  name                = local.identity_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.5.3"

  name               = local.aks_name
  location           = azurerm_resource_group.main.location
  parent_id          = azurerm_resource_group.main.id
  kubernetes_version = var.kubernetes_version
  tags               = local.common_tags

  managed_identities = {
    user_assigned_resource_ids = [module.user_assigned_identity.resource_id]
  }

  default_agent_pool = {
    name                = "system"
    vm_size             = var.node_vm_size
    enable_auto_scaling = true
    min_count           = var.node_count_min
    max_count           = var.node_count_max
    os_disk_size_gb     = 128
  }

  oidc_issuer_profile = {
    enabled = true
  }

  security_profile = {
    workload_identity = {
      enabled = true
    }
  }
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
  principal_id         = module.user_assigned_identity.principal_id
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
  principal_id         = module.user_assigned_identity.principal_id
}

resource "azurerm_federated_identity_credential" "external_dns" {
  name                      = "external-dns"
  user_assigned_identity_id = module.user_assigned_identity.resource_id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = module.aks.oidc_issuer_profile_issuer_url
  subject                   = "system:serviceaccount:external-dns:external-dns"
}