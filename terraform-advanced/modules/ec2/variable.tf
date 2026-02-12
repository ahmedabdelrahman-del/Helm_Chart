variable "name" {
  type        = string
  description = "Name prefix"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for EC2 instances"
}

variable "app_security_group_id" {
  type        = string
  description = "Security group for app tier"
}

variable "target_group_arn" {
  type        = string
  description = "ALB target group ARN"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "app_port" {
  type    = number
  default = 80
}

variable "tags" {
  type    = map(string)
  default = {}
}
