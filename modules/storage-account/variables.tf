# Required variables

variable "cost_center" {
  type        = string
  description = "Cost center identifier for billing and tagging."
}

variable "environment" {
  type        = string
  description = "Deployment environment."

  validation {
    condition     = contains(["dev", "can", "liv", "sbx", "tst", "uat", "stg", "prd"], var.environment)
    error_message = "Must be one of: dev, can, liv, sbx, tst, uat, stg, prd."
  }
}

variable "location" {
  type        = string
  description = "Azure region in which to deploy all resources."
}

variable "owner" {
  type        = string
  description = "Owning team or individual, used for tagging."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the storage account."
}

variable "solution" {
  type        = string
  description = "Solution identifier used in resource names and tags. Must be lowercase alphanumeric."

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.solution))
    error_message = "solution must contain only lowercase letters and digits (storage account name constraint)."
  }
}

# Optional variables

variable "account_kind" {
  type        = string
  description = "Kind of storage account."
  default     = "StorageV2"
  nullable    = false

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Must be one of: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2."
  }
}

variable "account_replication_type" {
  type        = string
  description = "Storage replication strategy."
  default     = "LRS"
  nullable    = false

  validation {
    condition     = contains(["GRS", "GZRS", "LRS", "RAGRS", "RAGZRS", "ZRS"], var.account_replication_type)
    error_message = "Must be one of: GRS, GZRS, LRS, RAGRS, RAGZRS, ZRS."
  }
}

variable "account_tier" {
  type        = string
  description = "Performance tier for the storage account."
  default     = "Standard"
  nullable    = false

  validation {
    condition     = contains(["Premium", "Standard"], var.account_tier)
    error_message = "Must be one of: Premium, Standard."
  }
}

variable "blob_soft_delete_retention_days" {
  type        = number
  description = "Days to retain soft-deleted blobs (1–365). Set to 0 to disable."
  default     = 7
  nullable    = false

  validation {
    condition     = var.blob_soft_delete_retention_days == 0 || (var.blob_soft_delete_retention_days >= 1 && var.blob_soft_delete_retention_days <= 365)
    error_message = "Must be 0 (disabled) or between 1 and 365."
  }
}

variable "cmk_key_vault_key_id" {
  type        = string
  description = "Versioned Key Vault key ID for customer-managed encryption. Requires cmk_user_assigned_identity_id."
  default     = null
}

variable "cmk_user_assigned_identity_id" {
  type        = string
  description = "Resource ID of the user-assigned managed identity with Key Vault Crypto User rights. Required when cmk_key_vault_key_id is set."
  default     = null
}

variable "container_soft_delete_retention_days" {
  type        = number
  description = "Days to retain soft-deleted containers (1–365). Set to 0 to disable."
  default     = 7
  nullable    = false

  validation {
    condition     = var.container_soft_delete_retention_days == 0 || (var.container_soft_delete_retention_days >= 1 && var.container_soft_delete_retention_days <= 365)
    error_message = "Must be 0 (disabled) or between 1 and 365."
  }
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  description = "Enable double encryption at the infrastructure layer."
  default     = false
  nullable    = false
}

variable "network_rules" {
  type = object({
    bypass                     = optional(set(string), ["AzureServices"])
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(set(string), [])
    virtual_network_subnet_ids = optional(set(string), [])
  })
  description = "Network ACL configuration. When set, applies the given rules. When null, Azure defaults (allow all) apply."
  default     = null
}

variable "private_endpoint" {
  type = object({
    name                 = optional(string)
    private_dns_zone_ids = optional(list(string), [])
    subnet_id            = string
    subresource_names    = optional(list(string), ["blob"])
  })
  description = "Private endpoint configuration. When set, deploys a private endpoint for the storage account."
  default     = null
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow public network access. Should be set to false when a private endpoint is used."
  default     = true
  nullable    = false
}

variable "shared_access_key_enabled" {
  type        = bool
  description = "Allow shared-key (SAS) authentication. Disable to enforce Entra ID-only access."
  default     = true
  nullable    = false
}

variable "system_assigned_identity_enabled" {
  type        = bool
  description = "Enable a system-assigned managed identity on the storage account."
  default     = false
  nullable    = false
}
