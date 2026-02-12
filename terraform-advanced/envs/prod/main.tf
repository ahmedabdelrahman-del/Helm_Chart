module "vpc" {
  source = "../../modules/vpc"

  name     = var.name
  vpc_cidr = var.vpc_cidr
  az_count = var.az_count

  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  isolated_subnet_cidrs = var.isolated_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  enable_vpc_endpoints      = var.enable_vpc_endpoints
  enable_s3_endpoint        = var.enable_s3_endpoint
  enable_interface_endpoints = var.enable_interface_endpoints
  interface_endpoint_services = var.interface_endpoint_services

  tags = var.tags
}
################################
# Security Module
################################
module "security" {
  source = "../../modules/security"

  name     = var.name
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr

  app_port = var.app_port
  db_port  = var.db_port

  enable_http_on_alb  = var.enable_http_on_alb
  enable_https_on_alb = var.enable_https_on_alb

  tags = var.tags
}
################################
# ALB Module
################################
module "alb" {
  source = "../../modules/alb"

  name                 = var.name
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.sg_alb_id

  listener_port     = 80
  target_port       = var.app_port
  health_check_path = "/"

  target_type = "instance" # best for EC2/ASG

  tags = var.tags
}
################################
# EC2 Module
################################
module "ec2" {
  source = "../../modules/ec2"

  name                    = var.name
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  app_security_group_id   = module.security.sg_app_id
  target_group_arn        = module.alb.target_group_arn

  app_port = var.app_port

  tags = var.tags
}
################################
# RDS Module
################################
module "rds" {
  source = "../../modules/rds"

  name               = var.name
  vpc_id             = module.vpc.vpc_id
  isolated_subnet_ids = module.vpc.isolated_subnet_ids
  db_security_group_id = module.security.sg_db_id

  # Interview-friendly defaults:
  engine         = "postgres"
  instance_class = "db.t4g.micro"
  db_name        = "appdb"
  username       = "appadmin"
  db_password       = var.db_password

  multi_az            = true
  publicly_accessible = false

  tags = var.tags
}
