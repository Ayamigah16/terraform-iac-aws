# Network Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = module.network.public_subnet_id
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = module.network.sg_id
}

# Security Outputs
output "detected_ip_cidr" {
  description = "The IP address used for SSH access (auto-detected or manually set)"
  value       = local.detected_ip
}

output "key_pair_name" {
  description = "The name of the EC2 key pair being used"
  value       = local.key_name
}

# Compute Outputs
output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.compute.ec2_instance_id
}

output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = module.compute.ec2_public_ip
}

output "ec2_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = module.compute.ec2_public_dns
}
