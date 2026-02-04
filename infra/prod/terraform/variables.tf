variable "flux_deploy_key_private" {
  description = "SSH private key for Flux GitHub deploy key (OpenSSH format)"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for cert-manager and external-dns"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Base domain for DNS records and TLS certificates (e.g., example.com)"
  type        = string
  default     = "souzaxx.dev"
}
