module "rds" {
  source                     = "./modules/rds"
  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnets
  eks_node_security_group_id = module.eks.node_security_group_id
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
  instance_class             = var.db_instance_class
  multi_az                   = var.environment == "prod" ? true : false
  deletion_protection        = var.environment == "prod" ? true : false
  skip_final_snapshot        = var.environment == "prod" ? false : true
}