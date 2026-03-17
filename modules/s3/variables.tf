variable "environment"  { 
    description = "Environment name"
    type = string 
}
variable "project_name" {
    description = "Project name"
    type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "lifecycle_days" {
  description = "Days before objects expire"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags for the bucket"
  type        = map(string)
  default     = {}
}