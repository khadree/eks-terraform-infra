variable "project_name" {
    description = "Project name"
    type        = string
}
variable "environment"  { 
    description = "Environment name"
    type = string 
}
variable "ami_id" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance"
  type        = string
}
variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string
}

variable "ec2_instances" {
  description = "Map of EC2 instances to create (keyed by instance id/name)."
  type        = map(any)
  default     = {}
}

variable "enable_ssm" {
  description = "Enable SSM agent for EC2 instance"
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = "Asssociate Public address"
  type        = bool
}


