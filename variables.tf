variable "project_name" {
  description = "Project name"
  type        = string
}
variable "region" {
  description = "AWS region"
  type        = string
}

# variable "cluster_name" {
#   description = "EKS Cluster name"
#   type        = string
# }

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.medium"
}


variable "ami_id" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ec2_instances" {
  description = "Map of EC2 instances to create (keyed by instance id/name)."
  type        = map(any)
  default     = {}
}

variable "associate_public_ip_address" {
  description = "VPC ID"
  type        = bool
}

# variable "eks" {
#   description = "Map of EKS cluster to create (keyed by instance id/name)."
#    type = map(object({
#     cluster_version     = string
#     node_instance_types = list(string)
#     node_desired_size   = number
#     node_max_size       = number
#     node_min_size       = number
#   }))
# }

variable "node_instance_types" {
  description = "EKS Instance type"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Number of Instance"
  type        = number
}

variable "node_max_size" {
  description = "Number of max instance needed"
  type        = number
}

variable "node_min_size" {
  description = "Number of minimum Instance needed"
  type        = number
}


variable "redis" {
  description = "Map of EKS cluster to create (keyed by instance id/name)."
  type        = map(any)
  default     = {}
}

# variable "rds" {
#   description = "Map of EKS cluster to create (keyed by instance id/name)."
#   type        = map(any)
#   default     = {}
# }
variable "admin_ip" {
  type        = string
  description = "Public IP for DB maintenance"
  default     = "" # Empty by default so it's optional
}

variable "db_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}


variable "allocated_storage" {
  description = "Initial storage in GB"
  type        = number
  default     = 20

}

variable "max_allocated_storage" {
  description = "Max storage for autoscaling in GB"
  type        = number
  default     = 100
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}
variable "postgres_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "s3_bucket" {
  description = "Map of S3 bucket to create (keyed by instance id/name)."
  type        = map(any)
  default     = {}
}

variable "rds" {
  description = "Map of RDS instances to create"
  type = map(object({
    postgres_version      = string
    instance_class        = string
    allocated_storage     = number
    max_allocated_storage = number
    db_name               = string
    db_username           = string
    db_password           = string
    db_port               = number
    multi_az              = bool
    backup_retention_days = number
    deletion_protection   = bool
    skip_final_snapshot   = bool
  }))
}


variable "enable_cert_manager" {
  type    = bool
  default = true
}

variable "enable_external_secrets" {
  type    = bool
  default = true
}

variable "enable_nginx_ingress" {
  type    = bool
  default = true
}

variable "port" {
  description = "Redis port"
  type        = number
  default     = 6379
}


variable "cert_manager_version" { default = "v1.14.4" }
variable "external_secrets_version" { default = "0.14.2" }
variable "nginx_ingress_version" { default = "4.10.0" }
variable "nginx_replica_count" { default = 1 }
variable "nginx_internal" { default = false }


variable "cert_manager_email" {
  description = "Email for Let's Encrypt"
  type        = string
}

variable "enable_cluster_autoscaler" {
  description = "Install cluster autoscaler"
  type        = bool
  default     = true
}