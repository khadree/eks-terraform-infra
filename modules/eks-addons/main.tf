data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ─── Helper: Lookup latest addon version ──────────────────────────────────────

data "aws_eks_addon_version" "vpc_cni" {
  count              = var.enable_vpc_cni ? 1 : 0
  addon_name         = "vpc-cni"
  kubernetes_version = var.cluster_version
  most_recent        = var.vpc_cni_version == null ? true : false
}

data "aws_eks_addon_version" "coredns" {
  count              = var.enable_coredns ? 1 : 0
  addon_name         = "coredns"
  kubernetes_version = var.cluster_version
  most_recent        = var.coredns_version == null ? true : false
}

data "aws_eks_addon_version" "kube_proxy" {
  count              = var.enable_kube_proxy ? 1 : 0
  addon_name         = "kube-proxy"
  kubernetes_version = var.cluster_version
  most_recent        = var.kube_proxy_version == null ? true : false
}

data "aws_eks_addon_version" "ebs_csi_driver" {
  count              = var.enable_ebs_csi_driver ? 1 : 0
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = var.cluster_version
  most_recent        = var.ebs_csi_driver_version == null ? true : false
}



# ═══════════════════════════════════════════════════════════════════════════════
# VPC CNI
# Manages pod networking — assigns VPC IPs directly to pods
# ═══════════════════════════════════════════════════════════════════════════════

data "aws_iam_policy_document" "vpc_cni_assume" {
  count = var.enable_vpc_cni ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_cni" {
  count              = var.enable_vpc_cni ? 1 : 0
  name               = "${var.cluster_name}-vpc-cni-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume[0].json

  tags = { Name = "${var.project_name}-${var.environment}-vpc-cni-role" }
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  count      = var.enable_vpc_cni ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni[0].name
}

resource "aws_eks_addon" "vpc_cni" {
  count                    = var.enable_vpc_cni ? 1 : 0
  cluster_name             = var.cluster_name
  addon_name               = "vpc-cni"
  addon_version            = coalesce(var.vpc_cni_version, data.aws_eks_addon_version.vpc_cni[0].version)
  resolve_conflicts_on_update = var.resolve_conflicts
  service_account_role_arn = aws_iam_role.vpc_cni[0].arn

  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"    # More IPs per node
      WARM_PREFIX_TARGET       = "1"
    }
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc-cni"
    Environment = var.environment
  }

  depends_on = [aws_iam_role_policy_attachment.vpc_cni]
}

# ═══════════════════════════════════════════════════════════════════════════════
# CoreDNS
# In-cluster DNS resolution for service discovery
# ═══════════════════════════════════════════════════════════════════════════════

resource "aws_eks_addon" "coredns" {
  count                       = var.enable_coredns ? 1 : 0
  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  addon_version               = coalesce(var.coredns_version, data.aws_eks_addon_version.coredns[0].version)
  resolve_conflicts_on_update = var.resolve_conflicts

  configuration_values = jsonencode({
    replicaCount = var.environment == "prod" ? 3 : 2
    resources = {
      limits   = { cpu = "100m", memory = "150Mi" }
      requests = { cpu = "100m", memory = "70Mi" }
    }
  })

  tags = {
    Name        = "${var.cluster_name}-coredns"
    Environment = var.environment
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# kube-proxy
# Maintains network rules for pod-to-pod and pod-to-service communication
# ═══════════════════════════════════════════════════════════════════════════════

resource "aws_eks_addon" "kube_proxy" {
  count                       = var.enable_kube_proxy ? 1 : 0
  cluster_name                = var.cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = coalesce(var.kube_proxy_version, data.aws_eks_addon_version.kube_proxy[0].version)
  resolve_conflicts_on_update = var.resolve_conflicts

  tags = {
    Name        = "${var.project_name}-${var.environment}-kube-proxy"
    Environment = var.environment
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EBS CSI Driver
# Enables dynamic provisioning of EBS volumes as PersistentVolumes
# ═══════════════════════════════════════════════════════════════════════════════

data "aws_iam_policy_document" "ebs_csi_assume" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  count              = var.enable_ebs_csi_driver ? 1 : 0
  name               = "${var.project_name}-${var.environment}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume[0].json

  tags = { Name = "${var.project_name}-${var.environment}-ebs-csi-role" }
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count      = var.enable_ebs_csi_driver ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi[0].name
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count                       = var.enable_ebs_csi_driver ? 1 : 0
  cluster_name                = var.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = coalesce(var.ebs_csi_driver_version, data.aws_eks_addon_version.ebs_csi_driver[0].version)
  resolve_conflicts_on_update = var.resolve_conflicts
  service_account_role_arn    = aws_iam_role.ebs_csi[0].arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-ebs-csi"
    Environment = var.environment
  }

  depends_on = [aws_iam_role_policy_attachment.ebs_csi]
}

# StorageClass — gp3 as default storage class
resource "kubernetes_storage_class" "gp3" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"   # Only provision when pod is scheduled
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}

# # Remove old gp2 as default so gp3 takes over
# resource "kubernetes_annotations" "gp2_not_default" {
#   count       = var.enable_ebs_csi_driver ? 1 : 0
#   api_version = "storage.k8s.io/v1"
#   kind        = "StorageClass"
#   metadata { name = "gp2" }
#   annotations = {
#     "storageclass.kubernetes.io/is-default-class" = "false"
#   }

#   depends_on = [kubernetes_storage_class.gp3]
# }


data "aws_iam_policy_document" "aws_lbc_assume" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "aws_lbc" {
  count              = var.enable_aws_load_balancer_controller ? 1 : 0
  name               = "${var.cluster_name}-aws-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc_assume[0].json
}


resource "aws_eks_addon" "snapshot_controller" {
  count                       = var.enable_snapshot_controller ? 1 : 0
  cluster_name                = var.cluster_name
  addon_name                  = "snapshot-controller"
  resolve_conflicts_on_update = var.resolve_conflicts

  tags = {
    Name        = "${var.project_name}-${var.environment}-snapshot-controller"
    Environment = var.environment
  }
}