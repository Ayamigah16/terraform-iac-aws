variable "aws_region" {
  description = "AWS region for deploying resources"
  type        = string
  default     = "eu-west-1"
}

variable "profile_name" {
  description = "AWS CLI profile name to use"
  type        = string
  default     = "default"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "terraform-iac-aws"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "aws_az" {
  description = "AWS Availability Zone for the subnet"
  type        = string
  default     = "eu-west-1a"
}

variable "my_ip_cidr" {
  description = "Your IP address in CIDR notation for SSH access (e.g., 1.2.3.4/32). Leave empty to auto-detect."
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance (Ubuntu 22.04 LTS recommended)"
  type        = string
  # Example for eu-west-1: ami-0694d931cee176e7d
}

variable "instance_type" {
  description = "The EC2 instance type (e.g., t2.micro, t3.micro, t3.small)"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access. Defaults to '<project_name>-key-pair'. Leave empty to skip SSH access."
  type        = string
  default     = ""
}