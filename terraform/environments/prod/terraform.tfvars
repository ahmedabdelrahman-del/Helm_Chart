# Production Environment Configuration

environment              = "prod"
app_name                 = "task-api"
alert_email              = "ops@example.com" # Change to your email

# VPC Configuration
vpc_cidr                 = "10.0.0.0/16"
availability_zones       = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs     = ["10.0.10.0/24", "10.0.11.0/24"]

# Database Configuration
db_name                  = "taskdb"
db_username              = "taskadmin"
db_password              = "ChangeMe!SecurePassword123" # Use AWS Secrets Manager in production
db_instance_class        = "db.t3.small"
db_allocated_storage     = 100
db_backup_retention_period = 30

# ECS Configuration
ecs_desired_count        = 3
ecs_min_capacity         = 3
ecs_max_capacity         = 10
ecs_cpu_threshold        = 70
ecs_memory_threshold     = 80

# Monitoring
log_retention_days       = 30
