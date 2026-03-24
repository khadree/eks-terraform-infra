module "helm_releases" {
  source            = "./modules/helm-releases"
  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = "${var.project_name}-${var.environment}-cluster"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  # Feature flags
  enable_cert_manager     = var.enable_cert_manager
  cert_manager_email      = var.cert_manager_email
  enable_external_secrets = var.enable_external_secrets
  enable_nginx_ingress    = var.enable_nginx_ingress
  # Chart versions
  cert_manager_version     = var.cert_manager_version
  external_secrets_version = var.external_secrets_version
  nginx_ingress_version    = var.nginx_ingress_version

  # Nginx config
  nginx_replica_count = 1
  nginx_internal      = false

  depends_on = [module.eks, module.eks_addons]
}