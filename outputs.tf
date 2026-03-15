output "vpc_id"  { 
    description = "VPC ID used in the project for reference"
    value = module.vpc.vpc_id 
}

output "cluster_endpoint" { 
    description = "EKS cluster endpoint"
    value = module.eks.cluster_endpoint 
}
output "oidc_provider_arn"{ 
    description = "OIDC provider ARN"
    value = module.eks.oidc_provider_arn 
}
output "db_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.db_endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials"
  value       = module.rds.secret_arn
}
output "db_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.db_endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials"
  value       = module.rds.secret_arn
}

output "instance_public_ip" {
  value = module.web_server.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "redis_endpoint" {
  description = "Redis Enpoint"
  value = module.redis.redis_endpoint
}