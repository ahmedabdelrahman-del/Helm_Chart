variable "name" {
  description = "Name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (used for subnet group naming and future extensions)"
  type        = string
}

variable "isolated_subnet_ids" {
  description = "Isolated subnet IDs for DB subnet group"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group for the DB (allows inbound only from app tier)"
  type        = string
}

variable "engine" {
  description = "RDS engine"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version (optional, empty means AWS default)"
  type        = string
  default     = ""
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "appadmin"
}

variable "db_password" {
  description = "Master password (use tfvars or secrets manager in real prod)"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "multi_az" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = true
}

variable "publicly_accessible" {
  description = "Whether DB is publicly accessible (should be false for 3-tier)"
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Encrypt storage"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Prevent accidental deletion in production"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy (true for dev/test)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default     = {}
}
