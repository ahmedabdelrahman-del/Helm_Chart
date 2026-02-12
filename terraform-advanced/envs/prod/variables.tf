variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "vpc-test"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of AZs"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets"
  type        = list(string)
  default     = [
    "10.0.0.0/24",
    "10.0.1.0/24"
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets"
  type        = list(string)
  default     = [
    "10.0.10.0/24",
    "10.0.11.0/24"
  ]
}

variable "isolated_subnet_cidrs" {
  description = "CIDRs for isolated subnets"
  type        = list(string)
  default     = [
    "10.0.20.0/24",
    "10.0.21.0/24"
  ]
}

variable "enable_nat_gateway" {
  description = "Create NAT gateways"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use only one NAT gateway"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Enable all VPC endpoints"
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Enable S3 gateway endpoint"
  type        = bool
  default     = true
}

variable "enable_interface_endpoints" {
  description = "Enable interface endpoints"
  type        = bool
  default     = true
}

variable "interface_endpoint_services" {
  description = "Interface endpoint services"
  type        = list(string)
  default = [
    "ssm",
    "ec2messages",
    "ssmmessages",
    "ecr.api",
    "ecr.dkr",
    "logs"
  ]
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default = {
    Environment = "prod"
    Owner       = "cherki"
  }
}
################################
# Security Variables
################################
variable "app_port" {
  description = "Application port"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "enable_http_on_alb" {
  type    = bool
  default = true
}

variable "enable_https_on_alb" {
  type    = bool
  default = true
}
################################
# RDS Module
################################
variable "db_password" {
  type      = string
  sensitive = true
}
variable "backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 1
}
