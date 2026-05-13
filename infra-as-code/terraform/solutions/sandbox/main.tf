data "azurerm_client_config" "current" {}

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

  aad_profile = {
    managed                = true
    enable_azure_rbac      = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  addon_profile_azure_policy = {
    enabled = true
  }

  api_server_access_profile = {
    disable_run_command = true
  }

  disable_local_accounts = true

  network_profile = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_dataplane   = "cilium"
    network_policy      = "cilium"
  }

  node_resource_group_profile = {
    restriction_level = "ReadOnly"
  }

  oidc_issuer_profile = {
    enabled = true
  }

  security_profile = {
    image_cleaner = {
      enabled        = true
      interval_hours = 168
    }
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
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                     = local.keyvault_name
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  enable_telemetry         = false
  network_acls             = null
  purge_protection_enabled = local.purge_protection_enabled
  tags                     = local.common_tags
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
  source  = "Azure/avm-res-network-dnszone/azurerm"
  version = "0.2.1"

  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.dns.name
  enable_telemetry    = false
  tags                = local.common_tags
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