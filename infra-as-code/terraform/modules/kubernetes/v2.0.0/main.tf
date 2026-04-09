

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.5.3"

  name      = local.aks_name
  location  = var.location
  parent_id = data.azurerm_resource_group.existing.id
  
  kubernetes_version = var.kubernetes_version
  tags               = local.common_tags

  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.uai.id]
  }

  default_agent_pool = {
    name                 = "system"
    vm_size              = var.node_vm_size
    auto_scaling_enabled = true
    min_count            = var.node_count_min
    max_count            = var.node_count_max
    os_disk_size_gb      = var.node_os_disk_size_gb
  }
}
