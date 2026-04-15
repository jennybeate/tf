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
  source = "../../modules/storage-account"

  cost_center         = var.cost_center
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  owner               = var.owner
  replication_type    = var.replication_type
  resource_group_name = azurerm_resource_group.main.name
  solution            = local.solution
}
