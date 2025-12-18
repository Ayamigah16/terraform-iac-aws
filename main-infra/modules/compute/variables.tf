variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the EC2 instance will be launched"
  type        = string
}

variable "sg_id" {
  description = "The ID of the security group to attach to the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type (e.g., t2.micro, t3.micro)"
  type        = string
  default     = "t3.micro"
}
