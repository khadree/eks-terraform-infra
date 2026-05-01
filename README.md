## **Teleios EKS Infrastructure**

A production-ready Infrastructure as Code (IaC) setup to deploy a fully featured Amazon EKS cluster on AWS using Terraform. Includes VPC networking, EKS cluster, RDS PostgreSQL, Redis, EKS managed addons, Helm chart dependencies, multi-environment support via Terraform Cloud, and remote state management.

## **📑 Table of Contents**

* Architecture Overview
* Prerequisites
* Project Structure
* Modules
* Multi-Environment Setup
* Terraform Cloud
* Getting Started
* Configuration
* Deployment Order
* Connecting to the Cluster
* Verify Everything Is Running
* Tear Down
* Security Considerations


## **🏗 Architecture Overview**

**AWS Cloud**

```
┌────────────────────────────────────────────────────────────────────┐
│                        VPC (per environment)                       │
│   dev: 10.0.0.0/16  |  staging: 10.1.0.0/16  |  prod: 10.2.0.0/16  │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                  3 Availability Zones                       │   │
│  │                                                             │   │
│  │   Public Subnets              Private Subnets               │   │
│  │   ┌─────────────┐             ┌──────────────────────────┐  │   │
│  │   │ NAT Gateway │────────────►│  EKS Managed Node Group  │  │   │
│  │   │  (per AZ)   │             │  (EC2 worker nodes)      │  │   │
│  │   └──────┬──────┘             └──────────────────────────┘  │   │
│  │          │                                                  │   │
│  │   ┌──────▼──────┐             ┌──────────────────────────┐  │   │
│  │   │  Internet   │             │     RDS PostgreSQL       │  │   │
│  │   │  Gateway    │             │  (private subnets only)  │  │   │
│  │   └─────────────┘             └──────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                    │
│   ┌──────────────────────────────────────────────────────────┐     │
│   │              EKS Control Plane (AWS Managed)             │     │
│   │   vpc-cni | coredns | kube-proxy | ebs-csi | efs-csi     │     │
│   │   cloudwatch-observability | aws-load-balancer-controller│     │
│   └──────────────────────────────────────────────────────────┘     │
│                                                                    │
│   ┌──────────────────────────────────────────────────────────┐     │
│   │                  Helm Releases                           │     │
│   │   cert-manager | external-secrets | ingress-nginx        │     │
│   │   cluster-autoscaler | metrics-server                    │     │
│   └──────────────────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────────────────┘
```

Terraform Cloud Workspaces:

```
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  teleios-kadiri-dev  │  │teleios-kadiri-staging│  │ teleios-kadiri-prod  │
│  (auto-apply)        │  │  (manual approve)    │  │  (manual approve)    │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘
```

## **What Gets Deployed**

| Resource| Details |
| ----------- | ----------- |
| VPC | Custom VPC with DNS support, per-environment CIDR blocks |
| Subnets  | 3 public + 3 private subnets across 3 Availability Zones |
| Internet Gateway | Outbound access for public subnets |
| NAT Gateways | One per AZ for high-availability private subnet egress |
| EKS Cluster  | Managed Kubernetes control plane with full audit logging |
| Managed Node Group | Auto-scaling EC2 worker nodes in private subnets |
| IAM Roles  |  Cluster role, node role, and IRSA roles for each addon |
| OIDC Provider | Enables fine-grained IAM Roles for Service Accounts |
| EKS Addons | vpc-cni, coredns, kube-proxy, ebs-csi, cloudwatch, LBC |
| RDS PostgreSQL | Encrypted, multi-AZ capable database in private subnets |
| Secrets Manager | Stores DB credentials securely with KMS encryption |
| Helm Charts  | Remote state and isolated workspace per environment |


 ## **Prerequisites**

| Tool | Version | Install |
| ----------- | ----------- | ---------- |
| Terraform | >= 1.5.0 | choco install terraform / brew install terraform |
| AWS CLI  | >= 2.0 | choco install awscli / brew install awscli |
| kubectl | >= 1.29 | choco install kubernetes-cli / brew install kubectl |
| Helm  | >= 3.0 | choco install kubernetes-helm / brew install helm |
|Git | Any | choco install git / brew install git |

## **AWS Credentials**

aws configure
AWS Access Key ID:     <your-access-key>
AWS Secret Access Key: <your-secret-key>
Default region:        us-east-1
Default output format: json

## **Your IAM user/role needs these permissions:**

* AmazonEKSClusterPolicy
* AmazonVPCFullAccess
* IAMFullAccess
* AmazonEC2FullAccess
* AmazonRDSFullAccess
* AmazonS3FullAccess
* SecretsManagerReadWrite
* CloudWatchFullAccess

## **Download the AWS Load Balancer Controller IAM Policy (one-time)**

mkdir -p modules/eks-addons/policies

curl -o modules/eks-addons/policies/aws-load-balancer-controller-policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

## **📁 Project Structure**

```
teleios-infra-eks/
├── ec2.tf                        # For Ec2 — wires all modules together.
├── eks.tf                         # For EKS module
├── rds.tf                         # for RDS module
├── redis.tf                       # For redis module
├── helm-release.tf                # For helm-release module
├── vpc.tf                         # For VPC module
├── s3.tf                          # For S3 module
├── variables.tf                   # Root input variables
├── outputs.tf                     # Root outputs
├── versions.tf                    # Provider and Terraform version constraints
├── backend.tf                     # Terraform Cloud backend configuration
├── .gitignore                     # Excludes .terraform/, *.tfstate, *.tfvars
├── README.md                      # This file
│
├── environments/
│   ├── dev.tfvars                 # Dev environment variable values
│   ├── staging.tfvars             # Staging environment variable values
│   └── prod.tfvars                # Prod environment variable values
│
└── modules/
    ├── vpc/                       # VPC, subnets, IGW, NAT gateways, route tables
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── eks/                       # EKS cluster, node group, IAM roles, OIDC
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── rds/                       # RDS PostgreSQL, subnet group, secrets manager
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── eks-addons/                # EKS managed addons + AWS LBC helm chart
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── policies/
    │       └── aws-load-balancer-controller-policy.json
    │
    ├── helm-release/              # cert-manager, external-secrets, nginx, etc.
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── redis/                     # Redis Cluster
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── s3/                        # S3 buckets 
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

    
## **🌍 Multi-Environment Setup**

**Three fully isolated environments, each with its own Terraform Cloud workspace, state file, AWS credentials, and variable set.**

| Setting | Dev | Stagging | Prod |
| ----------- | ----------- | ---------- | ---------- |
| VPC CIDR |10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Node type | t3.medium | t3.large | t3.xlarge |
| Node count |  1–2 | 1–4 | 2–10 |
| Multi-AZ RDS | ❌| ❌ | ✅ |
| Node type | t3.medium | t3.large | t3.xlarge |
| Node count |  1–2 | 1–4 | 2–10 |
| GuardDuty | ❌ | ❌ | ✅ |
| Deletion protection | ❌ | ✅ | ✅ |
| Backup retention | 1 day |  3 days | 7 days |

## **☁️ Terraform Cloud**

**Workspace Setup**
**Three CLI-driven workspaces in the Teleios organization, all tagged with teleios-kadiri:**


| Workspace |Tags | Auto Apply |
| ----------- | ----------- | ---------- |
| teleios-kadiri-dev | teleios-kadiri, dev| ✅ Yes |
| teleios-kadiri-staging | teleios-kadiri, staging | ❌ No |
| teleios-kadiri-prod | teleios-kadiri, prod | ❌ No |

backend.tf

terraform {
  cloud {
    organization = "Teleios"
    workspaces {
      tags = ["teleios-kadiri"]   # Shared tag across all 3 workspaces
    }
  }
}

## **Workspace Variables (set in TFC UI per workspace)**
**Environment Variables (mark all Sensitive):**

AWS_ACCESS_KEY_ID       = <env-specific-key>
AWS_SECRET_ACCESS_KEY   = <env-specific-secret>
AWS_DEFAULT_REGION      = us-east-1

## **🚀 Getting Started**

1. Clone the Repository
git clone https://github.com/your-org/teleios-infra-eks.git
cd teleios-infra-eks

2. Download LBC IAM Policy (one-time setup)
mkdir -p modules/eks-addons/policies

curl -o modules/eks-addons/policies/aws-load-balancer-controller-policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

3. Login to Terraform Cloud
terraform login

4. Initialize Terraform
terraform init

# When prompted, select: teleios-kadiri-dev

5. Plan
terraform plan -var-file="environments/dev.tfvars"
6. Apply
terraform apply -var-file="environments/dev.tfvars"

## **⚙️ Configuration**
Environment tfvars Example
# environments/dev.tfvars

environment               = "dev"
region                    = "us-east-1"
cluster_name              = "teleios-kadiri-dev"
cluster_version           = "1.29"
vpc_cidr                  = "10.0.0.0/16"
node_instance_types       = ["t3.medium"]
node_desired_size         = 1
node_min_size             = 1
node_max_size             = 2
db_name                   = "appdb"
db_username               = "dbadmin"
db_instance_class         = "db.t3.medium"
multi_az                  = false
deletion_protection       = false
skip_final_snapshot       = true
backup_retention_days     = 1
enable_efs                = false
enable_cert_manager       = true
enable_external_secrets   = true
enable_nginx_ingress      = true
enable_cluster_autoscaler = true

## **Switching Environments**
# Dev
export TF_WORKSPACE="teleios-kadiri-dev"
terraform apply -var-file="environments/dev.tfvars"

# Staging
export TF_WORKSPACE="teleios-kadiri-staging"
terraform apply -var-file="environments/staging.tfvars"

# Prod
export TF_WORKSPACE="teleios-kadiri-prod"
terraform apply -var-file="environments/prod.tfvars"

## **Setting the DB Password Securely**

Never store the DB password in tfvars files. Use one of these approaches:

# Option A: environment variable
export TF_VAR_db_password="YourStr0ngP@ssword!"
terraform apply -var-file="environments/dev.tfvars"

# Option B: set as a sensitive Terraform variable in the TFC workspace UI

## **📦 Deployment Order**
Terraform handles depends_on automatically, but here is the logical flow:

```
1. VPC
       │  networking foundation
       ▼
2. EKS Cluster + Node Group
       │  compute layer
       ▼
3. RDS PostgreSQL
       │  database layer
       ▼
4. EKS Core Addons (vpc-cni, coredns, kube-proxy)
       │  cluster cannot function without these
       ▼
5. EKS Storage Addons (ebs-csi, efs-csi)
       │  required before stateful workloads
       ▼
6. AWS Load Balancer Controller
       │  required before any Ingress works
       
7. Observability Addons (cloudwatch, guardduty)
       │
       ▼
8. Helm Charts (cert-manager, external-secrets, nginx, autoscaler, metrics-server)
       │  depend on healthy core addons
       ▼
9. Application Workloads

```
## **Connecting to the Cluster**

After a successful apply, configure kubectl:
aws eks update-kubeconfig \
  --region us-east-1 \
  --name teleios-kadiri-dev

## **Tear Down**

export TF_WORKSPACE="teleios-kadiri-dev"
terraform destroy -var-file="environments/dev.tfvars"

## **🔒 Security Considerations**

| Area| Implementation |
| ----------- | ----------- |
| Private nodes | Worker nodes in private subnets, never directly internet-accessible |
| Private RDS |  Database only reachable from EKS node security group |
| KMS encryption | RDS and Secrets Manager encrypted with rotating KMS keys |
| Secrets Manager | DB credentials never stored in Terraform state or tfvars |
| IRSA | Each addon uses its own scoped IAM role per service account |
| OIDC | Pod-level AWS permissions without node-level IAM sprawl |
| State security | State stored encrypted in Terraform Cloud |
| Audit logging | EKS control plane logs api, audit, authenticator, controller, scheduler |
| Container Insights | CloudWatch observability addon for metrics and log collection |
| GuardDuty | Runtime threat detection enabled in prod |
| TLS  | cert-manager auto-provisions Let's Encrypt certificates |
| NLB | Nginx ingress backed by AWS NLB for production traffic handling |
| Separate credentials | Each environment uses its own AWS IAM credentials |



**Author**: Kadiri George 
**Version**: 1.0.0  
**Last Updated**: May 2026