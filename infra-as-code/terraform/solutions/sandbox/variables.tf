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
  description = "Deployment environment. Used in resource names and tags."
  validation {
    condition     = contains(["can", "liv", "dev", "sbx", "tst", "uat", "stg", "prod"], var.environment)
    error_message = "Must be one of: can, liv, dev, sbx, test, uat, stage, prod."
  }
  default = "sbx"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the AKS cluster. Set to null to use the latest supported version."
  default     = null
}

variable "node_count_max" {
  type        = number
  description = "Maximum number of nodes in the AKS default node pool."
  default     = 3
}

variable "node_count_min" {
  type        = number
  description = "Minimum number of nodes in the AKS default node pool."
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "VM size for nodes in the AKS default node pool."
  default     = "Standard_D2s_v3"
}

variable "owner" {
  type        = string
  description = "Team or individual responsible for the resources."
}


variable "replication_type" {
  type = string
  default = "LRS"
}
