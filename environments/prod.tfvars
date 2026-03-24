# Global Variables
project_name = "teleios-kadiri"
environment  = "prod"
region       = "eu-west-1"

# EC2 Instance Configurations
ec2_instances = {
  "web-server" = {
    ami_id                      = "ami-0d1b55a6d77a0c326" # Replace with your region's AMI
    instance_type               = "t3.medium"
    associate_public_ip_address = true
    user_data                   = "" # Leave empty to use the module's default script
    subnet_type                 = "public"
    subnet_index                = 0
  }
  #   ,
  # #   "worker-node" = {
  # #     ami_id                      = "ami-0c55b159cbfafe1f0"
  # #     instance_type               = "t3.small"
  # #     associate_public_ip_address = false
  # #     user_data                   = "#!/bin/bash\necho 'Worker node setup'"
  # #   }
}

vpc_cidr = "10.2.0.0/16"

# eks = {
#   "test" = {
#     cluster_version     = "1.34"
#     node_instance_types = ["t3.medium"] # EKS nodes usually need more RAM than t3.micro
#     node_desired_size   = 1
#     node_max_size       = 2
#     node_min_size       = 1
#   }
# }
cluster_version             = "1.34"
node_instance_types         = ["t3.medium"]
node_desired_size           = 2
node_max_size               = 4
node_min_size               = 2
cluster_name                = "teleios-cluster" # Add this if missing
ami_id                      = "ami-0d1b55a6d77a0c326"
instance_type               = "t3.medium"
associate_public_ip_address = true

##### For Helm config
enable_cert_manager       = true
enable_external_secrets   = true
enable_nginx_ingress      = true
enable_cluster_autoscaler = true
cert_manager_email = "khadreegeorge@gmail.com"

redis = {
  "main-cache" = {
    node_type       = "cache.t2.medium"
    num_cache_nodes = 4
    port = 6379
  }
}

rds = {
  "database" = {
    # RDS Configuration
    postgres_version      = "15.16"
    instance_class        = "db.t3.medium"
    allocated_storage     = 20
    max_allocated_storage = 100
    db_name               = "vprofiledb"
    db_username           = "dbadmin"
    db_password           = "" # Use a secret manager in prod
    db_port               = 5432
    multi_az              = false
    backup_retention_days = 7
    deletion_protection   = false
    skip_final_snapshot   = true

  }
}




s3_bucket = {
  "app-data" = {} # Uses default module values
  # "user-assets" = {}
}
