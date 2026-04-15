variable "cost_center" {
  type        = string
  description = "Cost center code for billing and tagging."
}

variable "enable_telemetry" {
  type        = bool
  description = "Enable AVM telemetry. Set to false to opt out of usage data collection by the AVM module."
  default     = false
}

variable "environment" {
  type        = string
  description = "Deployment environment. Used in resource names and tags."
  validation {
    condition     = contains(["can", "liv", "dev", "sbx", "tst", "uat", "stg", "prod"], var.environment)
    error_message = "Must be one of: can, liv, dev, sbx, test, uat, stage, prod."
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

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the identity."
}

variable "solution" {
  type        = string
  description = "Solution or workload name. Used in resource naming and tags."
}
