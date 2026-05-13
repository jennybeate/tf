variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster."
}

variable "cluster_resource_group" {
  type        = string
  description = "Resource group containing the AKS cluster."
}

variable "argocd_chart_version" {
  type        = string
  description = "Argo CD Helm chart version. Chart 7.x installs Argo CD 2.13.x."
  default     = "7.8.3"
}
