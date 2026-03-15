variable "environment"  { 
    description = "Environment name"
    type = string 
}
variable "project_name" {
    description = "Project name"
    type        = string
}



variable "allowed_security_groups" {
  description = "Security groups allowed to access redis"
  type        = list(string)
}

variable "eks_node_security_group_id" {
  description = "EKS node security group ID to allow Redis access from pods"
  type        = string
  default     = ""
}


variable "name" {
  description = "Name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "allowed_security_groups" {
  description = "Security groups allowed to access Redis"
  type        = list(string)
}

variable "node_type" {
  description = "Redis instance type"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of Redis nodes"
  type        = number
  default     = 2
}