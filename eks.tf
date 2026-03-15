module "eks" {
  source             = "./modules/eks"
  project_name       = var.project_name
  environment  = var.environment
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
}
