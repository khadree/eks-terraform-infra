module "eks_addons" {
  source            = "./modules/eks-addons"
  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = "${var.project_name}-${var.environment}-cluster"
  cluster_version   = var.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  vpc_id            = module.vpc.vpc_id

  # Feature flags
  enable_vpc_cni        = true
  enable_coredns        = true
  enable_kube_proxy     = true
  enable_ebs_csi_driver = true
  #   enable_aws_load_balancer_controller = true
  #   enable_cloudwatch_observability     = true
  #   enable_guardduty                    = var.environment == "prod" ? true : false
  enable_snapshot_controller = false
  #   # EFS (only needed if enabled)
  #   private_subnet_ids     = module.vpc.private_subnets
  #   node_security_group_id = module.eks.node_security_group_id

  # Must come after EKS cluster and node group are ready
  depends_on = [module.eks]
}