variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "aws_az" {
  description = "AWS Availability Zone for the subnet"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your IP address in CIDR notation for SSH access"
  type        = string
}
