variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "gitops_repo_url" {
  description = "GitOps repository URL"
  type        = string
  default     = ""
}

variable "gitops_repo_branch" {
  description = "GitOps repository branch"
  type        = string
  default     = "main"
}

variable "gitops_repo_path" {
  description = "GitOps repository path"
  type        = string
  default     = "applications"
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
