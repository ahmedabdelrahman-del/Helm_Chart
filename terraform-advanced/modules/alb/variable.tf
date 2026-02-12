variable "name" {
  description = "Name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (ALB must be in public subnets)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "listener_port" {
  description = "ALB listener port (HTTP)"
  type        = number
  default     = 80
}

variable "target_port" {
  description = "Target group port (your app port)"
  type        = number
  default     = 80
}

variable "target_protocol" {
  description = "Target group protocol"
  type        = string
  default     = "HTTP"
}

variable "target_type" {
  description = "Target type: instance (EC2/ASG) or ip (ECS/EKS)"
  type        = string
  default     = "instance"

  validation {
    condition     = contains(["instance", "ip"], var.target_type)
    error_message = "target_type must be 'instance' or 'ip'."
  }
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "internal" {
  description = "Whether the ALB is internal (false means internet-facing)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default     = {}
}
