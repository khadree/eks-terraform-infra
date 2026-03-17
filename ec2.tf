module "ec2" {
  for_each                    = var.ec2_instances
  source                      = "./modules/ec2"
  instance_name               = "${var.project_name}-${var.environment}-ec2-${each.key}"
  project_name                = var.project_name
  environment                 = var.environment
  ami_id                      = each.value.ami_id
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_type == "public" ? module.vpc.public_subnets[each.value.subnet_index] : module.vpc.private_subnets[each.value.subnet_index]
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = each.value.associate_public_ip_address
}
