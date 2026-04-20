variable "cost_center" {
  type        = string
  description = "Cost center code applied as a billing tag."
}

variable "environment" {
  type        = string
  description = "Deployment environment token used in resource naming and tags."

  validation {
    condition     = contains(["can", "liv", "dev", "sbx", "tst", "uat", "stg", "prod"], var.environment)
    error_message = "Must be one of: can, liv, dev, sbx, tst, uat, stg, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region in which to deploy the Key Vault."
}

variable "owner" {
  type        = string
  description = "Owning team or individual applied as a billing tag."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the Key Vault into. Created by the deployment root — modules never create their own resource group."
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = "RBAC role assignments on the Key Vault. Use to grant managed identities Key Vault Secrets User or Key Vault Reader access."
  nullable    = false
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "SKU of the Key Vault. Possible values are standard and premium."

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  default     = 90
  description = "Number of days soft-deleted objects are retained. Must be between 7 and 90."

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "solution" {
  type        = string
  description = "Solution name used in resource naming and tags."
}
