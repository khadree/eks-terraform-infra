variable "project_name" {
    description = "Project name"
    type        = string
}
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}
variable "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL for IRSA"
  type        = string
}

# ─── Feature Flags ────────────────────────────────────────────────────────────

variable "enable_cert_manager" {
  description = "Install cert-manager"
  type        = bool
  default     = true
}

variable "enable_external_secrets" {
  description = "Install external-secrets operator"
  type        = bool
  default     = true
}

variable "enable_nginx_ingress" {
  description = "Install nginx ingress controller"
  type        = bool
  default     = true
}



# ─── Versions ─────────────────────────────────────────────────────────────────

variable "cert_manager_version" {
  description = "cert-manager helm chart version"
  type        = string
  default     = "v1.14.4"
}

variable "external_secrets_version" {
  description = "external-secrets helm chart version"
  type        = string
  default     = "0.14.2"
}

variable "nginx_ingress_version" {
  description = "nginx ingress helm chart version"
  type        = string
  default     = "4.10.0"
}


# ─── Nginx Config ─────────────────────────────────────────────────────────────

variable "nginx_replica_count" {
  description = "Number of nginx ingress controller replicas"
  type        = number
  default     = 1
}

variable "nginx_internal" {
  description = "Use internal (private) AWS load balancer for nginx"
  type        = bool
  default     = false
}


variable "cert_manager_email" {
  description = "Email for Let's Encrypt certificate notifications"
  type        = string
}