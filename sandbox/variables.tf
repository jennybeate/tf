variable "environment" {
  type        = string
  description = "Deployment environment. Must be 'sbx' for the sandbox."
  default     = "sbx"
  nullable    = false

  validation {
    condition     = contains(["dev", "sbx", "can", "liv", "tst", "uat", "stg", "prd"], var.environment)
    error_message = "Must be one of: dev, sbx, can, liv, tst, uat, stg, prd."
  }
}

variable "location" {
  type        = string
  description = "Azure region for sandbox resources."
  default     = "uksouth"
  nullable    = false
}

variable "cost_center" {
  type        = string
  description = "Cost center identifier for billing and tagging."
  nullable    = false
}

variable "owner" {
  type        = string
  description = "Owner of sandbox resources, used for tagging."
  nullable    = false
}

variable "solution" {
  type        = string
  description = "Solution name used in resource naming and tagging."
  nullable    = false
}
