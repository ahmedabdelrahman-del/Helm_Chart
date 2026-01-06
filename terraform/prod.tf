# Root Terraform Configuration - Production Infrastructure

locals {
  common_tags = {
    Project     = "task-api"
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  environment         = var.environment
  app_name            = var.app_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-alerts-${var.environment}"

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ECR Repository
resource "aws_ecr_repository" "main" {
  name                 = var.app_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  tags = local.common_tags
}

# KMS Key for ECR Encryption
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${var.app_name}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Secrets Manager for Database Credentials
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.app_name}/db/password"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.ecr.id

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = module.rds.db_address
    port     = module.rds.db_port
    dbname   = module.rds.db_name
  })
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  environment           = var.environment
  app_name              = var.app_name
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  rds_security_group_id = module.networking.rds_security_group_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  instance_class           = var.db_instance_class
  allocated_storage        = var.db_allocated_storage
  backup_retention_period  = var.db_backup_retention_period
  enable_encryption        = true
  enable_iam_auth          = true
  enable_enhanced_monitoring = true
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  environment            = var.environment
  app_name               = var.app_name
  vpc_id                 = module.networking.vpc_id
  private_subnet_ids     = module.networking.private_subnet_ids
  public_subnet_ids      = module.networking.public_subnet_ids
  alb_security_group_id  = module.networking.alb_security_group_id
  ecs_security_group_id  = module.networking.ecs_security_group_id
  container_image        = "${aws_ecr_repository.main.repository_url}:latest"
  container_port         = 8080

  desired_count   = var.ecs_desired_count
  min_capacity    = var.ecs_min_capacity
  max_capacity    = var.ecs_max_capacity
  cpu_threshold   = var.ecs_cpu_threshold
  memory_threshold = var.ecs_memory_threshold
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  environment         = var.environment
  app_name            = var.app_name
  alb_arn_suffix      = module.ecs.alb_arn_suffix
  target_group_arn_suffix = module.ecs.target_group_arn_suffix
  ecs_cluster_name    = module.ecs.cluster_id
  ecs_service_name    = module.ecs.service_name
  sns_topic_arn       = aws_sns_topic.alerts.arn
  cpu_threshold       = var.ecs_cpu_threshold
  memory_threshold    = var.ecs_memory_threshold
}

# CloudWatch Log Group for Application
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/${var.app_name}/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

# Output values for deployment
output "alb_dns_name" {
  value       = module.ecs.alb_dns_name
  description = "DNS name of the application load balancer"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.main.repository_url
  description = "URL of the ECR repository for pushing container images"
}

output "rds_endpoint" {
  value       = module.rds.db_endpoint
  description = "RDS database endpoint"
}

output "database_secret_arn" {
  value       = aws_secretsmanager_secret.db_password.arn
  description = "ARN of the Secrets Manager secret containing database credentials"
}

output "cloudwatch_dashboard_url" {
  value       = module.monitoring.dashboard_url
  description = "URL to CloudWatch dashboard for monitoring"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.alerts.arn
  description = "SNS topic ARN for alerts"
}
