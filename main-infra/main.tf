# Fetch current public IP automatically
data "http" "my_public_ip" {
  url = "https://ifconfig.me/ip"
}

locals {
  # Use auto-detected IP if my_ip_cidr is not set, otherwise use provided value
  detected_ip = var.my_ip_cidr != "" ? var.my_ip_cidr : "${chomp(data.http.my_public_ip.response_body)}/32"
  
  # Use provided key_name or generate from project_name, or empty if not needed
  key_name = var.key_name != "" ? var.key_name : "${var.project_name}-key-pair"
}

# Network Module: VPC, Subnet, IGW, Route, SG
module "network" {
  source      = "./modules/network"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  subnet_cidr = var.subnet_cidr
  my_ip_cidr  = local.detected_ip
  aws_az      = var.aws_az
}

# Compute Module: EC2 instance
module "compute" {
  source        = "./modules/compute"
  environment   = var.environment
  subnet_id     = module.network.public_subnet_id
  sg_id         = module.network.sg_id
  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = local.key_name
}
