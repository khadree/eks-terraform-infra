# ─── Namespaces ───────────────────────────────────────────────────────────────

resource "kubernetes_namespace" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0
  metadata {
    name = "cert-manager"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_namespace" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0
  metadata {
    name = "external-secrets"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  count = var.enable_nginx_ingress ? 1 : 0
  metadata {
    name = "ingress-nginx"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# ─── METRICS SERVER ───────────────────────────────────────────────────────────
# Required for HPA (Horizontal Pod Autoscaler) to read CPU and memory metrics

resource "kubernetes_namespace" "metrics_server" {
  metadata {
    name = "metrics-server"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"
  namespace  = kubernetes_namespace.metrics_server.metadata[0].name

  values = [
    yamlencode({
      args = [
        "--cert-dir=/tmp",
        "--secure-port=10250",
        "--kubelet-preferred-address-types=InternalIP",   # Required for EKS
        "--kubelet-use-node-status-port",
        "--metric-resolution=15s"
      ]
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }
      # Ensure it spreads across nodes for HA
      replicas = var.environment == "prod" ? 2 : 1
    })
  ]

  depends_on = [kubernetes_namespace.metrics_server]
}


# ─── CERT-MANAGER ─────────────────────────────────────────────────────────────

# IAM Role for cert-manager (IRSA) — needed if using Route53 DNS validation
data "aws_iam_policy_document" "cert_manager_assume" {
  count = var.enable_cert_manager ? 1 : 0

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
      values   = ["system:serviceaccount:cert-manager:cert-manager"]
    }
  }
}

resource "aws_iam_role" "cert_manager" {
  count              = var.enable_cert_manager ? 1 : 0
  name               = "${var.project_name}-${var.environment}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume[0].json
}

resource "aws_iam_role_policy" "cert_manager_route53" {
  count = var.enable_cert_manager ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cert-manager-route53"
  role  = aws_iam_role.cert_manager[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:GetChange"]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZonesByName"]
        Resource = "*"
      }
    ]
  })
}

resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = kubernetes_namespace.cert_manager[0].metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"    # Installs cert-manager CRDs automatically
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cert_manager[0].arn
  }

  set {
    name  = "securityContext.fsGroup"
    value = "1001"
  }

  values = [
    yamlencode({
      resources = {
        requests = { cpu = "10m", memory = "32Mi" }
        limits   = { cpu = "100m", memory = "128Mi" }
      }
      prometheus = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_namespace.cert_manager]
}

#  ClusterIssuer — must be created AFTER cert-manager is installed
resource "kubectl_manifest" "letsencrypt_prod" {
  count = var.enable_cert_manager ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.cert_manager_email   # ← add this variable
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  })

  # Must wait for cert-manager CRDs and webhook to be ready
  depends_on = [helm_release.cert_manager]
}

# ─── EXTERNAL SECRETS ─────────────────────────────────────────────────────────

# IAM Role for external-secrets (IRSA) — allows reading from Secrets Manager
data "aws_iam_policy_document" "external_secrets_assume" {
  count = var.enable_external_secrets ? 1 : 0

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
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  count              = var.enable_external_secrets ? 1 : 0
  name               = "${var.project_name}-${var.environment}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume[0].json
}

resource "aws_iam_role_policy" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0
  name  = "${var.cluster_name}-external-secrets-policy"
  role  = aws_iam_role.external_secrets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:rideshare/*",
          "arn:aws:secretsmanager:*:*:secret:${var.project_name}-${var.environment}/*"
        ] 
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${var.project_name}-${var.environment}/*"
      }
    ]
  })
}

resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.external_secrets_version
  namespace  = kubernetes_namespace.external_secrets[0].metadata[0].name
  timeout    = 600
  set {
    name  = "crds.create"
    value = "true"
  }
  set {
    name  = "crds.keep"
    value = "true"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_secrets[0].arn
  }

  values = [
    yamlencode({
      resources = {
        requests = { cpu = "10m", memory = "32Mi" }
        limits   = { cpu = "100m", memory = "128Mi" }
      }
    })
  ]

  depends_on = [kubernetes_namespace.external_secrets]
}

# ClusterSecretStore — connects external-secrets to AWS Secrets Manager
resource "kubectl_manifest" "cluster_secret_store" {
  count = var.enable_external_secrets ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secrets-manager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = data.aws_region.current.id
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = "external-secrets"
              }
            }
          }
        }
      }
    }
  })

  depends_on = [helm_release.external_secrets]
}

data "aws_region" "current" {}

# ─── NGINX INGRESS ────────────────────────────────────────────────────────────

resource "helm_release" "nginx_ingress" {
  count = var.enable_nginx_ingress ? 1 : 0
  timeout = 600
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.nginx_ingress_version
  namespace  = kubernetes_namespace.ingress_nginx[0].metadata[0].name

  values = [
    yamlencode({
      controller = {
        replicaCount = var.nginx_replica_count

        # AWS NLB annotations
        service = {
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
            "service.beta.kubernetes.io/aws-load-balancer-internal"                          = tostring(var.nginx_internal)
          }
        }

        # Resource limits
        resources = {
          requests = { cpu = "100m", memory = "128Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }

        # Spread replicas across AZs
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [{
              weight = 100
              podAffinityTerm = {
                labelSelector = {
                  matchExpressions = [{
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["ingress-nginx"]
                  }]
                }
                topologyKey = "topology.kubernetes.io/zone"
              }
            }]
          }
        }

        # Enable Prometheus metrics
        metrics = {
          enabled = true
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.ingress_nginx]
}


