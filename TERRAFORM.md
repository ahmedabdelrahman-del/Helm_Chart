# Terraform Infrastructure Setup

## Overview

This Terraform configuration creates a production-ready infrastructure for the Task API microservice on AWS with the following components:

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │     ALB     │ (Application Load Balancer)
                    │  (Port 80)  │
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
      ┌─────▼──┐      ┌────▼────┐   ┌───▼─────┐
      │  Task  │      │  Task   │   │  Task   │
      │ ECS #1 │      │ ECS #2  │   │ ECS #3  │
      └────┬───┘      └────┬────┘   └────┬────┘
           │               │             │
        ┌──▼───────────────▼─────────────▼──┐
        │      Private Subnet (Multi-AZ)    │
        │                                    │
        │    ┌──────────────────────────┐  │
        │    │   RDS PostgreSQL DB      │  │
        │    │   (Multi-AZ, Encrypted)  │  │
        │    └──────────────────────────┘  │
        └────────────────────────────────────┘
```

## Modules

### 1. Networking Module (`modules/networking/main.tf`)

Creates the foundational network infrastructure:

- **VPC**: Custom VPC with configurable CIDR block
- **Availability Zones**: Multi-AZ setup (default: 2 AZs for HA)
- **Subnets**:
  - Public subnets: For ALB (internet accessible)
  - Private subnets: For ECS and RDS (no direct internet access)
- **NAT Gateways**: For private subnet egress (one per AZ)
- **Internet Gateway**: For public subnet internet access
- **Security Groups**:
  - ALB Security Group: Allows inbound 80/443, outbound to ECS
  - ECS Security Group: Allows inbound from ALB, outbound to RDS/internet
  - RDS Security Group: Allows inbound only from ECS

**Output Variables**:
- `vpc_id`: VPC identifier
- `public_subnet_ids`: List of public subnet IDs
- `private_subnet_ids`: List of private subnet IDs
- `alb_security_group_id`: Security group for load balancer
- `ecs_security_group_id`: Security group for containers
- `rds_security_group_id`: Security group for database

### 2. ECS Module (`modules/ecs/main.tf`)

Deploys containerized application with auto-scaling:

- **ECS Cluster**: Fargate-based container orchestration
- **Task Definition**: Container image configuration with:
  - Health checks (HTTP endpoint check)
  - CloudWatch logging
  - Resource limits (256 CPU, 512 MB RAM)
  - Environment variables
- **ECS Service**: Manages container deployment and replacement
- **Application Load Balancer**: Distributes traffic across containers
- **Auto-scaling**: Target tracking policies for CPU and memory
  - CPU threshold: 70% (default, configurable)
  - Memory threshold: 80% (default, configurable)
  - Min capacity: 2 (default, prod: 3)
  - Max capacity: 10 (default)

**Output Variables**:
- `cluster_id`: ECS cluster identifier
- `service_name`: ECS service name
- `alb_dns_name`: Load balancer DNS (access point for application)
- `target_group_arn`: Target group for routing

### 3. RDS Module (`modules/rds/main.tf`)

Database with high availability and security:

- **Engine**: PostgreSQL 15.3
- **Instance Class**: db.t3.micro (staging) or db.t3.small+ (production)
- **Multi-AZ**: Automatic failover (production only)
- **Storage**:
  - Encrypted with KMS
  - Auto-scaling enabled
  - Type: gp3 (general purpose)
- **Backups**:
  - Retention: 30 days (production) or 7 days (staging)
  - Automated daily backups with point-in-time recovery
  - Cross-region replication for production
- **Security**:
  - VPC-only access (private subnets)
  - IAM database authentication enabled
  - Enhanced monitoring with 60-second granularity
  - Deletion protection (production only)
- **Performance**:
  - Performance Insights (production only)
  - CloudWatch log exports for PostgreSQL

**Output Variables**:
- `db_endpoint`: Database endpoint (host:port)
- `db_address`: Database hostname
- `db_port`: Database port (5432)
- `db_name`: Database name
- `db_username`: Master username
- `kms_key_id`: KMS key for encryption

### 4. Monitoring Module (`modules/monitoring/main.tf`)

Observability and alerting:

**CloudWatch Alarms**:
- ALB metrics:
  - Response time > 1 second
  - Unhealthy host count
  - 4XX errors > 50 in 5 min
  - 5XX errors > 5 in 1 min (critical)
- ECS metrics:
  - CPU utilization > threshold
  - Memory utilization > threshold
- RDS metrics:
  - CPU utilization > 80%
  - Free storage < 2GB
  - Database connections > 80

**CloudWatch Dashboard**: Comprehensive visualization of all metrics

**SNS Topic**: Email notifications for all alarms (configure email in tfvars)

## Deployment

### Prerequisites

1. AWS account with appropriate permissions
2. Terraform >= 1.0
3. AWS CLI configured with credentials
4. Docker image pushed to ECR or available
5. AWS Region: us-east-1 (Northern Virginia)

### Installation

1. **Initialize Terraform**:
   ```bash
   cd terraform
   terraform init -backend-config="bucket=task-api-state-${AWS_ACCOUNT_ID}" \
                  -backend-config="key=prod/terraform.tfstate" \
                  -backend-config="region=us-east-1" \
                  -backend-config="dynamodb_table=task-api-locks"
   ```

2. **Update Configuration**:
   - Edit `environments/prod/terraform.tfvars` with your values
   - Set `alert_email` for CloudWatch alarms
   - Update `db_password` (use AWS Secrets Manager for production)

3. **Plan Deployment**:
   ```bash
   terraform plan -var-file="environments/prod/terraform.tfvars"
   ```

4. **Apply Configuration**:
   ```bash
   terraform apply -var-file="environments/prod/terraform.tfvars"
   ```

### Environment Variables Required

Set before running Terraform:
```bash
export AWS_ACCOUNT_ID="647697752661"  # Your AWS Account ID
export AWS_REGION="us-east-1"
export TF_LOG=DEBUG  # Optional: for troubleshooting
```

## State Management

Terraform state is stored in S3 with state locking:

- **Backend**: S3 bucket (must exist before terraform init)
- **State Lock**: DynamoDB table (auto-created via terraform init)
- **Encryption**: Server-side encryption enabled
- **Versioning**: S3 versioning enabled

### Creating State Backend

```bash
aws s3 mb s3://task-api-state-${AWS_ACCOUNT_ID} --region us-east-1
aws s3api put-bucket-versioning \
  --bucket task-api-state-${AWS_ACCOUNT_ID} \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption \
  --bucket task-api-state-${AWS_ACCOUNT_ID} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

## Security Best Practices

### Implemented

✅ **Network Isolation**: Private subnets for ECS and RDS
✅ **Security Groups**: Least-privilege ingress/egress rules
✅ **Encryption**: KMS encryption for RDS and ECR
✅ **IAM Roles**: Task-specific IAM roles with minimal permissions
✅ **Secrets Management**: AWS Secrets Manager for database credentials
✅ **Health Checks**: Application and infrastructure health monitoring
✅ **Audit Logging**: CloudWatch logs for all components
✅ **Multi-AZ**: Automatic failover for high availability

### Additional Security Considerations

⚠️ **SSL/TLS**: Add ACM certificate and configure HTTPS listener on ALB
⚠️ **WAF**: Consider AWS WAF for web application firewall
⚠️ **VPN**: Set up AWS VPN for secure management access
⚠️ **Bastion Host**: Add EC2 bastion for database maintenance
⚠️ **Secrets Rotation**: Enable automatic rotation for database credentials
⚠️ **Network ACLs**: Add NACLs for additional network security

## Monitoring & Troubleshooting

### View Logs

```bash
# ECS container logs
aws logs tail /ecs/task-api-prod --follow

# RDS logs
aws rds describe-db-log-files --db-instance-identifier task-api-db-prod
```

### Check Alarms

```bash
# List all alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix task-api-prod

# Get alarm history
aws cloudwatch describe-alarm-history \
  --alarm-name task-api-prod-alb-5xx-errors
```

### Auto-scaling Metrics

```bash
# View scaling history
aws application-autoscaling describe-scaling-activities \
  --service-namespace ecs \
  --resource-id service/task-api-cluster-prod/task-api-service-prod
```

### Database Connections

```bash
# Connect to RDS
psql -h <db-endpoint> -U taskadmin -d taskdb

# Inside psql - check connections
SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;
```

## Cost Optimization

### Current Configuration (Staging)

- 1x db.t3.micro (RDS): ~$17/month
- 1-3 ECS tasks (Fargate): ~$10/month
- ALB: ~$16/month
- **Total**: ~$43/month

### Production Configuration

- 1x db.t3.small (RDS) with Multi-AZ: ~$150/month
- 3-10 ECS tasks (Fargate): ~$50-150/month
- ALB: ~$16/month
- NAT Gateway: ~$32/month
- **Total**: ~$250-400/month

### Cost Reduction Strategies

1. **Use Reserved Instances**: Save 40-70% on compute
2. **Savings Plans**: Flexible pricing for ECS
3. **RDS Reserved Instances**: 40-60% discount
4. **Spot Tasks**: Run non-critical tasks on Spot (75% discount)
5. **Auto-scaling**: Don't over-provision

## Maintenance & Upgrades

### Database Upgrades

```bash
# Modify RDS instance
aws rds modify-db-instance \
  --db-instance-identifier task-api-db-prod \
  --engine-version 15.4 \
  --apply-immediately
```

### Container Image Updates

1. Build and push new image to ECR
2. Update task definition with new image tag
3. Update ECS service to use new task definition
4. ECS handles rolling deployment automatically

### Terraform Updates

```bash
# Update Terraform modules
terraform init -upgrade
terraform plan -var-file="environments/prod/terraform.tfvars"
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## Disaster Recovery

### RDS Backup & Recovery

```bash
# List available backups
aws rds describe-db-snapshots --db-instance-identifier task-api-db-prod

# Restore from backup
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier task-api-db-restored \
  --db-snapshot-identifier <snapshot-id>
```

### Cross-Region Replication (Production)

Automated via `aws_db_instance_automated_backups_replication` resource. Backups are copied to another region every hour.

## Cleanup

To destroy all infrastructure:

```bash
terraform destroy -var-file="environments/prod/terraform.tfvars"
```

⚠️ **WARNING**: This deletes all resources including RDS database (with final snapshot). Data will be lost!

## Troubleshooting

### Terraform Apply Fails

1. Check AWS credentials: `aws sts get-caller-identity`
2. Verify region: `echo $AWS_REGION`
3. Check IAM permissions
4. Review error message for specific resource
5. Check state lock: `aws dynamodb scan --table-name task-api-locks`

### ECS Tasks Not Starting

1. Check CloudWatch logs: `/ecs/task-api-prod`
2. Verify container image exists in ECR
3. Check IAM task execution role permissions
4. Review task definition for errors
5. Check security group allows egress to ECR

### Database Connection Issues

1. Verify security group allows ECS to RDS (port 5432)
2. Check RDS is in same VPC
3. Verify database is running (not in transition state)
4. Test from bastion host (if available)
5. Check CloudWatch RDS logs

### ALB Not Routing Traffic

1. Verify target group health: `aws elbv2 describe-target-health --target-group-arn <arn>`
2. Check security group allows ALB to ECS
3. Verify application health check path returns 200
4. Check listener configuration
5. Review ALB access logs in S3

## Further Reading

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-best-practices.html)
- [RDS Security & Compliance](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/security.html)
- [Terraform State Management](https://www.terraform.io/language/state)
