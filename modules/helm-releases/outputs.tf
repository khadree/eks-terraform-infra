output "nginx_ingress_hostname" {
  description = "External hostname of the nginx ingress load balancer"
  value       = var.enable_nginx_ingress ? helm_release.nginx_ingress[0].status : null
}

output "cert_manager_role_arn" {
  description = "IAM role ARN for cert-manager"
  value       = var.enable_cert_manager ? aws_iam_role.cert_manager[0].arn : null
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for external-secrets"
  value       = var.enable_external_secrets ? aws_iam_role.external_secrets[0].arn : null
}
