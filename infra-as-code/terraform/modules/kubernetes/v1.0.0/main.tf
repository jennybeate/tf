resource "azurerm_user_assigned_identity" "main" {
  name                = local.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.aks_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.environment}-${var.solution}"
  kubernetes_version  = var.kubernetes_version
  tags                = local.common_tags

  default_node_pool {
    name                = "system"
    vm_size             = var.node_vm_size
    enable_auto_scaling = true
    min_count           = var.node_count_min
    max_count           = var.node_count_max
    os_disk_size_gb     = var.node_os_disk_size_gb
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version,
      default_node_pool[0].node_count,
    ]
  }
}
