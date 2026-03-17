output "vpc_id" {
  description = "VPC ID used in the project for reference"
  value       = module.vpc.vpc_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}
output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}
# ─── Dynamic Redis Outputs ────────────────────────────────────────────────────
output "redis_endpoints" {
  description = "Endpoints for all Redis replication groups"
  value       = { for name, redis in module.redis : name => redis.redis_endpoint }
}
output "rds_secret_arns" {
  description = "Secret ARNs for all RDS instances"
  value       = { for name, rds in module.rds : name => rds.secret_arn }
}
output "all_public_ips" {
  value = {
    for name, instance in module.ec2 : name => instance.public_ip
  }
}
output "ec2_instance_ids" {
  value = { for name, instance in module.ec2 : name => instance.instance_id }
}
# ─── Dynamic RDS Outputs ──────────────────────────────────────────────────────
output "rds_endpoints" {
  description = "Endpoints for all RDS instances"
  value       = { for name, rds in module.rds : name => rds.db_endpoint }
}
output "bucket_ids" {
  value = { for k, v in module.s3 : k => v.bucket_id }
}
