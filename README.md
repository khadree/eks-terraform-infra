## **Teleios EKS Infrastructure**

A production-ready Infrastructure as Code (IaC) setup to deploy a fully featured Amazon EKS cluster on AWS using Terraform. Includes VPC networking, EKS cluster, RDS PostgreSQL, EKS managed addons, Helm chart dependencies, multi-environment support via Terraform Cloud, and remote state management.

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
* Troubleshooting

## **🏗 Architecture Overview**

**AWS Cloud**
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

Terraform Cloud Workspaces:
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  teleios-kadiri-dev  │  │teleios-kadiri-staging│  │ teleios-kadiri-prod  │
│  (auto-apply)        │  │  (manual approve)    │  │  (manual approve)    │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘

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
| Helm  | >= 3.0 |choco install kubernetes-helm / brew install helmGitAnychoco install git / brew install git |

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

teleios-infra-eks/
├── ec2.tf                        # For Ec2 — wires all modules together.
├── eks.tf                         # For EKS module
├── rds.tf                         # for RDS module
├── redis.tf                        # For redis module
├── helm-release.tf                 # For helm-release module
├── vpc.tf                          # For VPC module
├── s3.tf                           # For S3 module
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
    └── helm-release/                      # cert-manager, external-secrets, nginx, autoscaler, metrics-server
    |    ├── main.tf
    |    ├── variables.tf
    |    └── outputs.tf
    |
    ├── redis/                       # Redis Cluster aws_elasticache_replication_group
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── s3/                       # S3 buckets 
       ├── main.tf
        ├── variables.tf
        └── outputs.tf
    
## **🌍 Multi-Environment Setup**

**Three fully isolated environments, each with its own Terraform Cloud workspace, state file, AWS credentials, and variable set.**
| Setting | Dev | Stagging | Prod |
| ----------- | ----------- | ---------- |
| VPC CIDR |10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Node type | t3.medium | t3.large | t3.xlarge |
| Node count |  1–2 | 1–4 | 2–10 |
| Multi-AZ RDS | ❌| ❌ | ✅ |
| Node type | t3.medium | t3.large | t3.xlarge |
| Node count |  1–2 | 1–4 | 2–10 |


SettingDevStagingProdVPC CIDR10.0.0.0/1610.1.0.0/1610.2.0.0/16
Node typet3.medium t3.large t3.xlarge
Node count 1–2 1–4 2–10
RDS instance db.t3.medium db.t3.large db.r6g.large
Multi-AZ RDS  ❌ ✅
GuardDuty❌❌✅
EFS storage❌❌✅
Deletion protection❌✅✅
Auto-apply✅❌❌
Backup retention1 day3 days7 days