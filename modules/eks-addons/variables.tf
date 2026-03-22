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

variable "cluster_version" {
  description = "EKS Kubernetes version"
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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# ─── Feature Flags ────────────────────────────────────────────────────────────

variable "enable_vpc_cni" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "enable_coredns" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = true
}

variable "enable_kube_proxy" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "enable_efs_csi_driver" {
  description = "Enable EFS CSI driver addon"
  type        = bool
  default     = false
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_observability" {
  description = "Enable CloudWatch observability addon"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty EKS runtime monitoring"
  type        = bool
  default     = false
}

variable "enable_snapshot_controller" {
  description = "Enable volume snapshot controller"
  type        = bool
  default     = false
}

# ─── Addon Versions ───────────────────────────────────────────────────────────
# Leave as null to always use the latest default version for your cluster version

variable "vpc_cni_version" {
  description = "VPC CNI addon version (null = latest)"
  type        = string
  default     = null
}

variable "coredns_version" {
  description = "CoreDNS addon version (null = latest)"
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "kube-proxy addon version (null = latest)"
  type        = string
  default     = null
}

variable "ebs_csi_driver_version" {
  description = "EBS CSI driver addon version (null = latest)"
  type        = string
  default     = null
}

variable "efs_csi_driver_version" {
  description = "EFS CSI driver addon version (null = latest)"
  type        = string
  default     = null
}

variable "cloudwatch_observability_version" {
  description = "CloudWatch observability addon version (null = latest)"
  type        = string
  default     = null
}

# ─── EFS Config ───────────────────────────────────────────────────────────────

variable "private_subnet_ids" {
  description = "Private subnet IDs (used for EFS mount targets)"
  type        = list(string)
  default     = []
}

variable "node_security_group_id" {
  description = "EKS node security group ID (used for EFS)"
  type        = string
  default     = ""
}

# ─── Resolve Conflicts ────────────────────────────────────────────────────────

variable "resolve_conflicts" {
  description = "How to handle conflicts when updating addons (OVERWRITE or PRESERVE)"
  type        = string
  default     = "OVERWRITE"
}