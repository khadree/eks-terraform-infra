module "redis" {
  for_each                = var.redis
  source                  = "./modules/redis"
  name                    = "${var.project_name}-${var.environment}-redis"
  environment             = var.environment
  project_name            = var.project_name
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnets
  allowed_security_groups = [for ec2 in module.ec2 : ec2.security_group_id]
}
