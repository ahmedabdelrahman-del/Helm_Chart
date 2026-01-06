# Production Infrastructure Quick Start

## One-Command Setup (from Terraform directory)

```bash
# Set environment variables
export AWS_ACCOUNT_ID="647697752661"
export AWS_REGION="us-east-1"
export ENVIRONMENT="prod"

# Initialize Terraform backend
terraform init \
  -backend-config="bucket=task-api-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=task-api-locks"

# Plan infrastructure
terraform plan -var-file="environments/${ENVIRONMENT}/terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="environments/${ENVIRONMENT}/terraform.tfvars"
```

## What Gets Created

After Terraform apply completes, you'll have:

### Networking (Multi-AZ)
- ✅ VPC (10.0.0.0/16 for prod, 10.1.0.0/16 for staging)
- ✅ 2 Public Subnets (for ALB)
- ✅ 2 Private Subnets (for ECS)
- ✅ 2 NAT Gateways (for HA)
- ✅ Internet Gateway
- ✅ Route tables with proper routing

### Application Layer
- ✅ Application Load Balancer (HTTP/80)
- ✅ ECS Fargate Cluster
- ✅ ECS Service with 3 tasks (prod) or 1 task (staging)
- ✅ Auto-scaling (2-10 tasks based on CPU/memory)
- ✅ CloudWatch logging for all containers

### Database
- ✅ RDS PostgreSQL 15.3 (Multi-AZ for prod)
- ✅ Automated daily backups (30-day retention)
- ✅ KMS encryption at rest
- ✅ Enhanced monitoring

### Security & Monitoring
- ✅ 3 Security Groups (ALB, ECS, RDS)
- ✅ IAM roles for ECS tasks
- ✅ CloudWatch alarms (6 critical + 1 dashboard)
- ✅ SNS topic for email notifications
- ✅ ECR repository with image scanning

### State Management
- ✅ S3 bucket for Terraform state
- ✅ DynamoDB table for state locking
- ✅ State versioning and encryption

## Accessing Your Infrastructure

```bash
# Get load balancer DNS
LOAD_BALANCER=$(terraform output -raw alb_dns_name)
echo "Application available at: http://${LOAD_BALANCER}"

# Test health check
curl http://${LOAD_BALANCER}/health

# Get database endpoint
DB_ENDPOINT=$(terraform output -raw rds_endpoint)
echo "Database: $DB_ENDPOINT"

# Get ECR repository URL
ECR_URL=$(terraform output -raw ecr_repository_url)
echo "Push images to: $ECR_URL"
```

## Next Steps

### 1. Set Up Monitoring (Optional but Recommended)

```bash
# View CloudWatch dashboard
DASHBOARD_URL=$(terraform output -raw cloudwatch_dashboard_url)
echo "Open: $DASHBOARD_URL"

# Confirm SNS subscription (check email)
aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn)
```

### 2. Configure Jenkins to Deploy

In Jenkins (in the Jenkinsfile `Deploy to Production` stage):

```groovy
stage('Deploy to Production') {
    steps {
        script {
            sh '''
              ECR_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/task-api:${BUILD_NUMBER}"
              
              # Update ECS service with new image
              aws ecs update-service \
                --cluster task-api-cluster-prod \
                --service task-api-service-prod \
                --force-new-deployment \
                --region us-east-1
            '''
        }
    }
}
```

### 3. Initialize Database

```bash
# Get database credentials from Secrets Manager
CREDS=$(aws secretsmanager get-secret-value --secret-id task-api/db/password)
DB_HOST=$(echo $CREDS | jq -r .SecretString | jq -r .host)
DB_USER=$(echo $CREDS | jq -r .SecretString | jq -r .username)

# Connect to database (from EC2 bastion or via AWS Session Manager)
psql -h $DB_HOST -U $DB_USER -d taskdb

# Create schema (if needed)
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4. Push Container Image

```bash
# Get ECR repository URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_URL

# Push image
docker tag task-api:latest $ECR_URL:latest
docker push $ECR_URL:latest

# Push with build number
docker tag task-api:latest $ECR_URL:${BUILD_NUMBER}
docker push $ECR_URL:${BUILD_NUMBER}
```

### 5. Scale Application

```bash
# Scale to 5 tasks
aws ecs update-service \
  --cluster task-api-cluster-prod \
  --service task-api-service-prod \
  --desired-count 5

# Auto-scaling does this automatically based on metrics
# No need to manually scale unless testing
```

## Monitoring

### CloudWatch Dashboard

The Terraform automatically creates a CloudWatch dashboard showing:
- ECS CPU & Memory Utilization
- ALB Response Time
- ALB Request Count
- Healthy/Unhealthy Host Count
- HTTP Error Rates

Access via:
```bash
aws cloudwatch get-dashboard --dashboard-name task-api-dashboard-prod
```

### Key Metrics to Watch

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| **CPU Utilization** | <50% | 50-70% | >70% |
| **Memory Utilization** | <60% | 60-80% | >80% |
| **Response Time (p99)** | <200ms | 200-500ms | >500ms |
| **Error Rate** | <0.01% | 0.01-0.1% | >0.1% |
| **Task Count** | Stable | ±1 task | Oscillating |

### CloudWatch Alarms

Alarms automatically notify ops@example.com when:
1. ALB response time > 1 second
2. Unhealthy hosts detected
3. 4XX errors > 50/5min
4. 5XX errors > 5/1min (immediate!)
5. ECS CPU > 70%
6. ECS Memory > 80%

**Update email address in `terraform.tfvars`**

## Troubleshooting

### "Terraform state locked"

```bash
# Remove stuck lock
aws dynamodb delete-item \
  --table-name task-api-locks \
  --key '{"LockID":{"S":"prod/terraform.tfstate"}}'
```

### "ALB targets unhealthy"

```bash
# Check CloudWatch logs
aws logs tail /ecs/task-api-prod --follow

# Check security group (ALB→ECS should be allowed)
aws ec2 describe-security-groups --group-ids sg-xxxxxxxx

# Check container health
aws ecs describe-tasks \
  --cluster task-api-cluster-prod \
  --tasks $(aws ecs list-tasks --cluster task-api-cluster-prod --output text)
```

### "RDS connection failed"

```bash
# Check RDS is in "available" state
aws rds describe-db-instances --db-instance-identifier task-api-db-prod

# Check security group allows ECS → RDS (port 5432)
aws ec2 describe-security-group-ingress-rules \
  --filters Name=group-id,Values=sg-xxxxx
```

### "ECS tasks not starting"

```bash
# Check task logs
aws logs tail /ecs/task-api-prod --follow

# Check if container image exists in ECR
aws ecr list-images --repository-name task-api

# Check IAM task execution role has ECR permissions
aws iam get-role-policy --role-name task-api-ecs-task-execution-role-prod --policy-name ...
```

## Cleanup

To completely remove all infrastructure:

```bash
# Remove infrastructure (careful - deletes database!)
terraform destroy -var-file="environments/prod/terraform.tfvars"

# Manually delete S3 state bucket (if not using anymore)
aws s3 rb s3://task-api-state-${AWS_ACCOUNT_ID} --force
```

⚠️ **WARNING**: This will:
- ✅ Delete ECS cluster, tasks, services
- ✅ Delete ALB and target groups
- ✅ Delete RDS database (final snapshot created)
- ✅ Delete VPC and all networking
- ⚠️ Keep S3 state bucket (must delete manually)

## Production Deployment Flow

```
1. Developer commits code → GitHub
2. Jenkins webhook triggered
3. Jenkins pulls code
4. Lint & format checks
5. Run unit tests
6. Security scanning
7. Build Docker image
8. Push to ECR
9. Update ECS task definition
10. ECS deploys new containers
11. ALB health checks new containers
12. Old containers gradually replaced
13. CloudWatch monitors metrics
14. Alerts sent if issues
15. Smoke tests verify functionality
```

**Total time**: ~5-10 minutes from commit to production

## Disaster Recovery

### Quick Database Restore

```bash
# Find recent snapshot
SNAPSHOT=$(aws rds describe-db-snapshots \
  --db-instance-identifier task-api-db-prod \
  --query 'DBSnapshots[0].DBSnapshotIdentifier' \
  --output text)

# Restore to point-in-time
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier task-api-db-prod \
  --target-db-instance-identifier task-api-db-restored \
  --restore-time "2024-01-15T15:30:00Z"
```

### Quick Application Rollback

```bash
# Get previous task definition
PREV_DEF=$(aws ecs describe-services \
  --cluster task-api-cluster-prod \
  --services task-api-service-prod \
  --query 'services[0].deployments[1].taskDefinition' \
  --output text)

# Revert to previous
aws ecs update-service \
  --cluster task-api-cluster-prod \
  --service task-api-service-prod \
  --task-definition $PREV_DEF \
  --force-new-deployment
```

## Cost Estimation

**Production (as configured)**:
- RDS Multi-AZ: ~$155/month
- ECS Fargate (3-10 tasks): ~$170/month
- ALB + NAT: ~$48/month
- **Total**: ~$373/month

**Staging**:
- RDS (small): ~$17/month
- ECS Fargate (1-3 tasks): ~$10/month
- ALB + NAT: ~$48/month
- **Total**: ~$75/month

**Combined monthly**: ~$450

To reduce costs:
- Use Reserved Instances (40% discount)
- Scale staging to 0 after hours
- Use spot instances for non-critical workloads
- See DEVOPS_GUIDE.md for more cost optimization strategies

---

## Getting Help

1. **Terraform Issues**: See TERRAFORM.md
2. **DevOps Best Practices**: See DEVOPS_GUIDE.md
3. **AWS Documentation**: https://docs.aws.amazon.com
4. **Common Issues**: See DEVOPS_GUIDE.md Troubleshooting section

Start with monitoring the CloudWatch dashboard and reading logs in CloudWatch to understand how your infrastructure behaves!
