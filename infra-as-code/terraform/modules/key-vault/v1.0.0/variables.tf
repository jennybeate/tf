variable "cost_center" {
  type        = string
  description = "Cost center code for billing and tagging."
}

variable "environment" {
  type        = string
  description = "Deployment environment. Used in resource names and tags."
  validation {
    condition     = contains(["can", "liv", "dev", "sbx", "tst", "uat", "stg", "prd"], var.environment)
    error_message = "Must be one of: can, liv, dev, sbx, tst, uat, stg, prd."
  }
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment."
  default     = "norwayeast"
}

variable "owner" {
  type        = string
  description = "Team or individual responsible for the resources."
}

variable "sku_name" {
  type        = string
  description = "The SKU for the Key Vault. Use 'premium' if HSM-backed keys are required."
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "Must be one of: standard, premium."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Number of days soft-deleted objects are retained before permanent removal."
  default     = 7
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Must be between 7 and 90 days."
  }
}

variable "solution" {
  type        = string
  description = "Solution or workload name. Used in resource naming and tags."
}
