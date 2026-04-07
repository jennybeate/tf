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

variable "replication_type" {
  type        = string
  description = "Storage account replication type."
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy resources."
}

variable "solution" {
  type        = string
  description = "Solution or workload name. Used in resource naming. Keep short — storage account names are capped at 24 characters."
}
