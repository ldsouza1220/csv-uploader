variable "eks" {
  description = "EKS cluster configuration"
  type = object({
    cluster_name            = string
    cluster_endpoint        = string
    cluster_oidc_issuer_url = string
  })
}

variable "vpc_id" {
  description = "VPC ID for AWS Load Balancer Controller"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "karpenter" {
  description = "Karpenter configuration"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "aws_load_balancer_controller" {
  description = "AWS Load Balancer Controller configuration"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "external_dns" {
  description = "External DNS configuration"
  type = object({
    enabled         = bool
    create_iam_role = optional(bool, false) # Set to true for Route53, false for Cloudflare
  })
  default = {
    enabled         = false
    create_iam_role = false
  }
}

variable "cert_manager" {
  description = "cert-manager configuration"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "flux" {
  description = "Flux CD configuration"
  type = object({
    enabled            = bool
    version            = optional(string, "2.14.1")
    github_owner       = optional(string, "ldsouza1220")
    github_repository  = optional(string, "csv-uploader")
    git_branch         = optional(string, "main")
    kustomization_path = optional(string, "infra/prod/k8s/flux")
  })
  default = {
    enabled            = true
    version            = "2.14.1"
    github_owner       = "ldsouza1220"
    github_repository  = "csv-uploader"
    git_branch         = "main"
    kustomization_path = "infra/prod/k8s/flux"
  }
}

variable "flux_deploy_key_private" {
  description = "SSH private key for Flux GitHub deploy key (OpenSSH format)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "domain" {
  description = "Base domain for DNS records and TLS certificates"
  type        = string
  default     = "souzaxx.dev"
}
