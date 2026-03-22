# module "rds" {
#   source                     = "./modules/rds"
#   project_name               = var.project_name
#   environment                = var.environment
#   postgres_version      = var.postgres_version
#   vpc_id                     = module.vpc.vpc_id
#   private_subnet_ids         = module.vpc.private_subnets
#   admin_ip = var.admin_ip
#   # eks_node_security_group_id = module.eks.node_security_group_id[0]
#   # Logic to grab the first EKS node security group ID found in the map
#   # eks_node_security_group_id = values(module.eks)[0].node_security_group_id
#   eks_node_security_group_id = module.eks.node_security_group_id
#   allocated_storage     = var.allocated_storage
#   max_allocated_storage = var.max_allocated_storage
#   db_name                    = var.db_name
#   db_username                = var.db_username
#   db_password                = var.db_password
#   db_port               =     var.db_port
#   instance_class             = var.db_instance_class
#   backup_retention_days = var.backup_retention_days
#   multi_az                   = var.environment == "prod" ? true : false
#   deletion_protection        = var.environment == "prod" ? true : false
#   skip_final_snapshot        = var.environment == "prod" ? false : true
# }

module "rds" {
  source   = "./modules/rds"
  for_each = var.rds

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  # Use each.value to grab data from your map
  postgres_version      = each.value.postgres_version
  instance_class        = each.value.instance_class
  allocated_storage     = each.value.allocated_storage
  max_allocated_storage = each.value.max_allocated_storage
  db_name               = each.value.db_name
  db_username           = each.value.db_username
  db_password           = each.value.db_password
  db_port               = each.value.db_port
  backup_retention_days = each.value.backup_retention_days
  multi_az              = var.environment == "prod" ? true : false
  # deletion_protection   = var.environment == "prod" ? true : false
  skip_final_snapshot   = var.environment == "prod" ? false : true
  deletion_protection   = each.value.deletion_protection
  # Keep your EKS link logic
  eks_node_security_group_id = module.eks.node_security_group_id
  admin_ip                   = var.admin_ip
}