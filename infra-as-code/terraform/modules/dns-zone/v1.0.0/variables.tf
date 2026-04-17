variable "cost_center" {
  type        = string
  description = "Cost center code for billing and tagging."
}

variable "dns_zone_name" {
  type        = string
  description = "The DNS zone domain name (e.g. k8s.example.com)."
}

variable "environment" {
  type        = string
  description = "Deployment environment. Used in tags."
  validation {
    condition     = contains(["can", "liv", "dev", "sbx", "tst", "uat", "stg", "prod"], var.environment)
    error_message = "Must be one of: can, liv, dev, sbx, tst, uat, stg, prod."
  }
}

variable "owner" {
  type        = string
  description = "Team or individual responsible for the resources."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the DNS zone."
}

variable "solution" {
  type        = string
  description = "Solution name. Used in tags."
}
