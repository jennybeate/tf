module "storage_account" {
  source = "../modules/storage-account"

  cost_center      = var.cost_center
  environment      = var.environment
  location         = var.location
  owner            = var.owner
  replication_type = var.replication_type
  solution         = var.solution
}
