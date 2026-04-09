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

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version. Set to null to use the latest supported version."
  default     = null
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment."
  default     = "norwayeast"
}

variable "node_count_max" {
  type        = number
  description = "Maximum number of nodes in the default node pool."
  default     = 3
}

variable "node_count_min" {
  type        = number
  description = "Minimum number of nodes in the default node pool."
  default     = 1
  validation {
    condition     = var.node_count_min >= 1
    error_message = "Minimum node count must be at least 1."
  }
}

variable "node_os_disk_size_gb" {
  type        = number
  description = "OS disk size in GB for each node in the default node pool."
  default     = 128
}

variable "node_vm_size" {
  type        = string
  description = "VM size for nodes in the default node pool."
  default     = "Standard_D2s_v3"
}

variable "owner" {
  type        = string
  description = "Team or individual responsible for the resources."
}

variable "solution" {
  type        = string
  description = "Solution or workload name. Used in resource naming and tags."
}

variable "user_assigned_identity_id" {
  type        = string
  description = "Resource ID of the user-assigned managed identity to attach to the AKS cluster."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy resources."
}