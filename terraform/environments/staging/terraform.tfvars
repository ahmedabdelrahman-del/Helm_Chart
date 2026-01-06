# Staging Environment Configuration

environment              = "staging"
app_name                 = "task-api"
alert_email              = "devops@example.com" # Change to your email

# VPC Configuration
vpc_cidr                 = "10.1.0.0/16"
availability_zones       = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs     = ["10.1.10.0/24", "10.1.11.0/24"]

# Database Configuration
db_name                  = "taskdb"
db_username              = "taskadmin"
db_password              = "ChangeMe!StagingPassword123" # Use AWS Secrets Manager in production
db_instance_class        = "db.t3.micro"
db_allocated_storage     = 20
db_backup_retention_period = 7

# ECS Configuration
ecs_desired_count        = 1
ecs_min_capacity         = 1
ecs_max_capacity         = 3
ecs_cpu_threshold        = 80
ecs_memory_threshold     = 85

# Monitoring
log_retention_days       = 7
