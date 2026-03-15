module "redis" {
  source = "./modules/redis"
  name = "${var.project_name}-redis"
  environment = var.environment
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  allowed_security_groups = [module.ec2.security_group_id, module.eks.node_security_group_id]
}
