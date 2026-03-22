output "vpc_cni_role_arn" {
  description = "IAM role ARN for VPC CNI"
  value       = var.enable_vpc_cni ? aws_iam_role.vpc_cni[0].arn : null
}

output "ebs_csi_role_arn" {
  description = "IAM role ARN for EBS CSI driver"
  value       = var.enable_ebs_csi_driver ? aws_iam_role.ebs_csi[0].arn : null
}

