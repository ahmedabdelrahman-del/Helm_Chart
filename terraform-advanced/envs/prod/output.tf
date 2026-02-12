output "vpc_id" {
  value = module.vpc.vpc_id
}

output "azs" {
  value = module.vpc.azs
}

output "public_subnets" {
  value = module.vpc.public_subnet_ids
}

output "private_subnets" {
  value = module.vpc.private_subnet_ids
}

output "isolated_subnets" {
  value = module.vpc.isolated_subnet_ids
}

output "s3_endpoint_id" {
  value = module.vpc.vpc_endpoint_s3_id
}

output "interface_endpoints" {
  value = module.vpc.vpc_interface_endpoints
}
################################
# Security Outputs
################################

output "alb_security_group_id" {
  value = module.security.sg_alb_id
}

output "app_security_group_id" {
  value = module.security.sg_app_id
}

output "db_security_group_id" {
  value = module.security.sg_db_id
}
################################
# ALB Outputs
################################
output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "target_group_arn" {
  value = module.alb.target_group_arn
}
################################
# RDS Outputs
################################
output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "db_port" {
  value = module.rds.db_port
}
