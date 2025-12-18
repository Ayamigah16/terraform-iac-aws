 # Network Module: VPC, Subnet, IGW, Route, SG
module "network" {
  source     = "./modules/network"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  subnet_cidr = var.subnet_cidr
  my_ip_cidr  = var.my_ip_cidr
  aws_az      = var.aws_az
}

# Compute Module: EC2 instance
module "compute" {
  source     = "./modules/compute"
  environment = var.environment
  subnet_id   = module.network.public_subnet_id
  sg_id       = module.network.sg_id
  ami_id      = var.ami_id
}
