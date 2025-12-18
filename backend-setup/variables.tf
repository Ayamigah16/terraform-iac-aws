variable "aws_region" {
  description = "Backend Region"
  type        = string
  default     = "eu-west-1"
}

variable "profile_name" {
  description = "The AWS CLI profile"
  type        = string
  default     = "default"
}

variable "dynamodb_table_name" {
  description = "DynamoDB Table for state locking"
  type        = string
  default     = "terraform-locks"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "terraform-iac-aws"
}