variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "How many AZs to use (typically 2)"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs (length must match az_count)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs (length must match az_count)"
  type        = list(string)
}

variable "isolated_subnet_cidrs" {
  description = "List of isolated subnet CIDRs (length must match az_count)"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateways"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "If true, create a single NAT Gateway instead of one per AZ"
  type        = bool
  default     = false
}
variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints (S3 gateway + interface endpoints)"
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Enable S3 gateway endpoint"
  type        = bool
  default     = true
}

variable "enable_interface_endpoints" {
  description = "Enable interface endpoints like SSM, ECR, CloudWatch Logs"
  type        = bool
  default     = true
}

variable "interface_endpoint_services" {
  description = "List of interface endpoint services to create"
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
  description = "Extra tags to apply"
  type        = map(string)
  default     = {}
}
