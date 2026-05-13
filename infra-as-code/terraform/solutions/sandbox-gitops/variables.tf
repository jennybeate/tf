variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster."
}

variable "cluster_resource_group" {
  type        = string
  description = "Resource group containing the AKS cluster."
}

variable "environment" {
  type        = string
  description = "Deployment environment code."
  validation {
    condition     = contains(["can", "liv", "dev", "sbx", "tst", "uat", "stg", "prod"], var.environment)
    error_message = "Must be one of: can, liv, dev, sbx, tst, uat, stg, prod."
  }
  default = "sbx"
}

variable "argocd_chart_version" {
  type        = string
  description = "Argo CD Helm chart version. Chart 7.x installs Argo CD 2.13.x."
  default     = "7.8.3"
}
