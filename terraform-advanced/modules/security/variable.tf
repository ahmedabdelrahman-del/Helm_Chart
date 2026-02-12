variable "name" {
  description = "Name prefix for security resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR used for internal-only rules (e.g., VPC endpoints access)"
  type        = string
}

variable "app_port" {
  description = "Port your application listens on (from ALB to app)"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Database port (from app to DB)"
  type        = number
  default     = 5432
}

variable "enable_https_on_alb" {
  description = "Whether to open 443 on ALB SG"
  type        = bool
  default     = true
}

variable "enable_http_on_alb" {
  description = "Whether to open 80 on ALB SG"
  type        = bool
  default     = true
}

variable "allow_app_egress_to_internet" {
  description = "Allow app instances to egress to the internet (through NAT). Commonly true."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags to apply"
  type        = map(string)
  default     = {}
}
