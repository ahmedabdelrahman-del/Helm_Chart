# Complete DevOps Production Guide

## Table of Contents

1. [Infrastructure Overview](#infrastructure-overview)
2. [High Availability & Disaster Recovery](#high-availability--disaster-recovery)
3. [Security & Compliance](#security--compliance)
4. [Monitoring & Observability](#monitoring--observability)
5. [Scaling & Performance](#scaling--performance)
6. [Deployment Strategy](#deployment-strategy)
7. [Cost Management](#cost-management)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Production Checklist](#production-checklist)

---

## Infrastructure Overview

### Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                 Applications & CI/CD                        │
│  (Jenkins → Docker → ECR → ECS → CloudWatch)                │
├─────────────────────────────────────────────────────────────┤
│                  AWS Infrastructure                          │
│  ┌─ Compute: ECS Fargate (containerized)                   │
│  ├─ Storage: RDS PostgreSQL (managed DB)                   │
│  ├─ Network: VPC with Multi-AZ setup                       │
│  ├─ Load Balancer: ALB (traffic distribution)              │
│  └─ Monitoring: CloudWatch, SNS Alarms                     │
├─────────────────────────────────────────────────────────────┤
│              Cross-Cutting Concerns                          │
│  ├─ Security: IAM, KMS, Secrets Manager                    │
│  ├─ Networking: Security Groups, NACLs                     │
│  ├─ State: Terraform with S3 backend                       │
│  └─ Logging: CloudWatch Logs, VPC Flow Logs                │
└─────────────────────────────────────────────────────────────┘
```

### Key AWS Services Used

| Service | Purpose | Config |
|---------|---------|--------|
| **ECS Fargate** | Container orchestration | Serverless, fully managed |
| **RDS PostgreSQL** | Managed database | Multi-AZ, encrypted, backups |
| **Application Load Balancer** | Traffic distribution | Health checks, auto-scaling |
| **VPC** | Network isolation | Multi-AZ, public/private subnets |
| **CloudWatch** | Monitoring & logging | Alarms, dashboards, metrics |
| **ECR** | Container registry | Private, encrypted, scanning |
| **IAM** | Access control | Role-based, least privilege |
| **KMS** | Encryption | For RDS, ECR, Secrets |
| **Secrets Manager** | Credential management | Rotation, audit logging |

---

## High Availability & Disaster Recovery

### HA Implementation

#### Multi-AZ Deployment
- **Database**: RDS configured for Multi-AZ with automatic failover
  - Standby replica in different AZ
  - Automatic promotion on failure (<2 minute RTO)
  - Zero data loss (synchronous replication)

- **Application**: ECS service spread across multiple AZs
  - Default 3 tasks in production
  - Auto-scaling keeps minimum 3 running
  - Load balancer detects and removes failed tasks

- **Network**: NAT gateways in each AZ
  - Ensures private subnets have internet access
  - Independent failure domain per AZ

#### Health Checks
- **ALB**: TCP port check every 30 seconds
- **ECS**: HTTP endpoint check at `/health` every 30 seconds
- **RDS**: Database response monitoring
- **Auto-recovery**: Failed tasks replaced within 30-60 seconds

### Disaster Recovery

#### Backup Strategy

**Database Backups**:
```
Automated Daily Backups
├─ Retention: 30 days (production)
├─ Point-in-time recovery: Up to 30 days back
├─ Cross-region replication: Hourly to secondary region
└─ Manual snapshots: For major deployments
```

**Configuration & State**:
- Terraform state: S3 with versioning + DynamoDB locks
- Infrastructure as Code: Git-tracked
- Secrets: AWS Secrets Manager (audit logging)

#### Recovery Procedures

**RDS Point-in-Time Recovery (PITR)**:
```bash
# Restore to specific time (within 30 days)
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier task-api-db-prod \
  --target-db-instance-identifier task-api-db-restored \
  --restore-time "2024-01-15T15:30:00Z" \
  --copy-tags-to-snapshot
```

**Application Rollback**:
```bash
# Revert to previous container image in ECS
aws ecs update-service \
  --cluster task-api-cluster-prod \
  --service task-api-service-prod \
  --force-new-deployment
```

**Infrastructure Rollback**:
```bash
# Terraform automatically tracks previous state
terraform apply -var-file="environments/prod/terraform.tfvars"  # Reapply
# Or revert to previous state file from S3
aws s3 cp s3://task-api-state-${AWS_ACCOUNT_ID}/prod/terraform.tfstate.backup .
terraform apply -refresh=true
```

#### Recovery Targets

| Component | RTO | RPO | Method |
|-----------|-----|-----|--------|
| **Application** | 1-2 min | 0 min | ECS auto-recovery |
| **Database** | 2-5 min | 0 min | RDS Multi-AZ failover |
| **Complete Stack** | 10-15 min | 0 min | Terraform redeploy |
| **Cross-Region** | 30 min | 1 hour | Backup restore |

---

## Security & Compliance

### Network Security

#### VPC Architecture
```
Internet Gateway → ALB (Public Subnet)
                    ↓
                 NAT Gateway (Public Subnet)
                    ↓
            ECS Tasks (Private Subnet)
                    ↓
            RDS (Private Subnet)
                    ↓
            Only Outbound to Internet
```

#### Security Groups

**ALB Security Group**:
```
Inbound:
  - Port 80 (HTTP): 0.0.0.0/0
  - Port 443 (HTTPS): 0.0.0.0/0 [TODO]

Outbound:
  - All to ECS Security Group
```

**ECS Security Group**:
```
Inbound:
  - Port 8080: From ALB Security Group only
  
Outbound:
  - All to RDS Security Group (port 5432)
  - Port 443: To 0.0.0.0/0 (ECR, Secrets Manager)
```

**RDS Security Group**:
```
Inbound:
  - Port 5432: From ECS Security Group only

Outbound:
  - None (RDS doesn't initiate connections)
```

### Data Security

#### Encryption

**At Rest**:
- **RDS**: KMS encryption (customer-managed key)
- **ECR**: KMS encryption for container images
- **S3 (State)**: Server-side encryption (AES-256)
- **Secrets Manager**: KMS encryption

**In Transit**:
- **ECS to RDS**: VPC (no internet exposure)
- **ALB to ECS**: Within VPC
- **External Traffic**: HTTP (plan HTTPS upgrade)

#### Credential Management

**Database Credentials**:
```bash
# Stored in AWS Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id task-api/db/password

# Automatic rotation (configure for production)
aws secretsmanager rotate-secret \
  --secret-id task-api/db/password \
  --rotation-rules AutomaticallyAfterDays=30
```

**API Keys & Secrets**:
- Store in Secrets Manager, not in code
- Reference via IAM roles
- Audit all access

### IAM & Access Control

#### ECS Task Execution Role

Permissions for ECS to pull images and write logs:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": "arn:aws:ecr:*:*:repository/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/ecs/*"
    }
  ]
}
```

#### ECS Task Role

Permissions for application containers:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::task-api-*/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:task-api/*"
    }
  ]
}
```

### Compliance Considerations

#### Audit Logging
- ✅ CloudTrail: AWS API calls (enable for production)
- ✅ VPC Flow Logs: Network traffic (enable for security analysis)
- ✅ RDS Audit Plugin: Database query logging (optional)
- ✅ CloudWatch Logs: Application logs with retention

#### Compliance Frameworks

| Framework | Implementation |
|-----------|-----------------|
| **SOC 2** | Encryption, access controls, audit logging |
| **HIPAA** | BAA required, encryption mandatory |
| **PCI-DSS** | Network segmentation, encryption, IAM |
| **GDPR** | Data residency (EU), encryption, retention policies |

---

## Monitoring & Observability

### Metrics & Alarms

#### Key Performance Indicators (KPIs)

**Availability**:
```
Uptime = (Total Time - Downtime) / Total Time
Target: 99.9% (9 hours 45 minutes downtime/month)

Measured via: ALB health checks, ECS task replacement
```

**Performance**:
```
Response Time: p50, p95, p99
Target: p99 < 500ms

Measured via: ALB TargetResponseTime metric
```

**Error Rate**:
```
Error Rate = 5XX Errors / Total Requests
Target: < 0.1%

Measured via: ALB HTTPCode_Target_5XX_Count
```

**Scaling Efficiency**:
```
CPU Utilization: 70% target (scale out at 70%)
Memory Utilization: 80% target (scale out at 80%)
Cost per Request: Monitor with billing alerts
```

### CloudWatch Dashboards

Create custom dashboards showing:
1. **Application Health**: Error rates, response times
2. **Infrastructure**: CPU, memory, network
3. **Database**: Connections, replication lag, disk space
4. **Business Metrics**: Requests/sec, tasks completed, active users

### Logging Strategy

#### Log Levels

```
DEBUG   → Development/staging only
INFO    → Important business events, deployments
WARN    → Recoverable issues, degraded performance
ERROR   → Failed operations, exceptions
FATAL   → System-wide failures requiring immediate action
```

#### Log Retention

```
CloudWatch Logs: 30 days (production), 7 days (staging)
S3 Archive: 1 year (long-term retention)
```

#### Log Analysis

```bash
# Find all errors in the last hour
aws logs filter-log-events \
  --log-group-name /ecs/task-api-prod \
  --filter-pattern "[level = ERROR*]" \
  --start-time $(date -d '1 hour ago' +%s)000

# Get request latency percentiles
aws logs filter-log-events \
  --log-group-name /ecs/task-api-prod \
  --filter-pattern "[duration > 500]"
```

---

## Scaling & Performance

### Vertical Scaling (Compute Sizing)

#### ECS Task Sizing

| Environment | CPU | Memory | Use Case |
|-------------|-----|--------|----------|
| Staging | 256 | 512 MB | Low-traffic testing |
| Production | 256 | 512 MB | Starting point |
| Production+ | 512 | 1024 MB | High-load services |
| Production++ | 1024 | 2048 MB | CPU-intensive operations |

#### RDS Instance Classes

| Instance | vCPU | Memory | Use Case |
|----------|------|--------|----------|
| db.t3.micro | 2 | 1 GB | Staging, low-traffic dev |
| db.t3.small | 2 | 2 GB | Production entry-level |
| db.t3.medium | 2 | 4 GB | High-traffic production |
| db.r5.large | 2 | 16 GB | Memory-intensive workloads |

### Horizontal Scaling (Auto-scaling)

#### Current Configuration

```
Production:
  Desired: 3 tasks
  Min: 3 tasks
  Max: 10 tasks
  CPU Target: 70%
  Memory Target: 80%

Scaling Up: Takes ~2-3 minutes
Scaling Down: Takes ~5 minutes (grace period)
```

#### Scaling Policies

**Target Tracking (Recommended)**:
```
Scale when metric exceeds target
- CPU 70%: Add tasks until drops to 70%
- Memory 80%: Add tasks until drops to 80%
- Smooth, predictable scaling
```

**Step Scaling (Alternative)**:
```
Scale based on alarm thresholds
- CPU > 85%: Add 2 tasks
- CPU > 95%: Add 5 tasks (aggressive)
- Useful for sudden spikes
```

#### Scaling Limitations

⚠️ **Account Limits** (Request increase from AWS):
- Max ECS tasks per cluster: ~1000
- Max Fargate vCPUs per region: 1000
- Max RDS instances per account: 40

⚠️ **Cold Start**: New container takes 30-60 seconds
⚠️ **DB Connection Pool**: Grows with task count
⚠️ **ALB Warm-up**: Takes 1-2 minutes to reach full capacity

### Performance Optimization

#### Application Level

1. **Connection Pooling**: Database connections
   ```go
   // Reuse connections, don't create new ones per request
   db.SetMaxOpenConns(25)  // Per task
   db.SetMaxIdleConns(10)
   ```

2. **Caching**: Reduce database queries
   ```go
   // Cache frequently accessed data
   // Example: Task categories, user permissions
   ```

3. **Request Batching**: Combine multiple operations
   ```go
   // Instead of 10 separate DB calls, make 1 batch call
   ```

#### Infrastructure Level

1. **Compress Responses**: gzip compression for HTTP
   ```go
   router.Use(gzip.Gzip(gzip.DefaultCompression))
   ```

2. **Database Indexing**: Speed up queries
   ```sql
   CREATE INDEX idx_task_user_id ON tasks(user_id);
   CREATE INDEX idx_task_created_at ON tasks(created_at DESC);
   ```

3. **Query Optimization**: Write efficient SQL
   ```sql
   -- Bad: N+1 queries
   -- Good: JOIN or batch fetch
   ```

---

## Deployment Strategy

### Current: Rolling Deployment

```
Step 1: New task starts (3+1 running)
Step 2: Old task terminates when new is healthy
Step 3: Next old task replaces
Result: Zero-downtime, traffic switches gradually
Time: ~5-10 minutes
```

### Alternative: Blue-Green Deployment

```
Step 1: Deploy to "green" environment (separate)
Step 2: Smoke tests pass on green
Step 3: ALB switches all traffic green→blue
Step 4: Keep blue as rollback target
Result: Instant switchover, easy rollback
Risk: Runs 2x infrastructure temporarily
```

### Canary Deployment

```
Step 1: Send 10% traffic to new version
Step 2: Monitor metrics (errors, latency)
Step 3: If good, gradually increase (20%, 50%, 100%)
Step 4: If bad, rollback to 0%
Result: Reduces blast radius of bad deployments
Time: 5-30 minutes depending on metrics
```

### Implementation via Jenkins

Update Jenkinsfile `Deploy to Production` stage:

```groovy
stage('Deploy to Production') {
    steps {
        script {
            echo "Deploying to production..."
            
            // Option 1: Standard rolling deployment
            sh '''
              aws ecs update-service \
                --cluster task-api-cluster-prod \
                --service task-api-service-prod \
                --task-definition task-api:${BUILD_NUMBER} \
                --force-new-deployment
            '''
            
            // Wait for deployment to complete
            sh '''
              aws ecs wait services-stable \
                --cluster task-api-cluster-prod \
                --services task-api-service-prod
            '''
        }
    }
}
```

### Deployment Runbook

#### Before Deployment

- [ ] Code reviewed and approved
- [ ] All tests passing
- [ ] Security scan passed
- [ ] No critical alerts active
- [ ] Backup of current database taken
- [ ] Rollback plan documented
- [ ] Stakeholders notified

#### During Deployment

- [ ] Monitor CloudWatch dashboard
- [ ] Watch error rates and latency
- [ ] Have rollback command ready
- [ ] Communicate status to team
- [ ] Check application logs for issues

#### After Deployment

- [ ] Verify application responding correctly
- [ ] Check error rates (should be < 0.1%)
- [ ] Verify database connectivity
- [ ] Run smoke tests
- [ ] Update deployment log
- [ ] Notify team of success

### Rollback Procedure

```bash
# Immediate: Revert to previous task definition
PREVIOUS_TASK_DEF=$(aws ecs describe-services \
  --cluster task-api-cluster-prod \
  --services task-api-service-prod \
  --query 'services[0].deployments[1].taskDefinition' \
  --output text)

aws ecs update-service \
  --cluster task-api-cluster-prod \
  --service task-api-service-prod \
  --task-definition $PREVIOUS_TASK_DEF \
  --force-new-deployment

# Fast: Restore database from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier task-api-db-prod-restored \
  --db-snapshot-identifier <snapshot-id>
```

---

## Cost Management

### Budget & Alerts

```bash
# Set budget alert at 80% of monthly limit
aws budgets create-budget \
  --account-id ${AWS_ACCOUNT_ID} \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

Budget Template (`budget.json`):
```json
{
  "BudgetName": "task-api-monthly",
  "BudgetLimit": {
    "Amount": "300",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```

### Cost Breakdown

**Monthly Production Costs** (Estimated):

| Service | Quantity | Price | Monthly |
|---------|----------|-------|---------|
| RDS (db.t3.small, Multi-AZ) | 1 | $0.216/hr | ~$155 |
| ECS Fargate (3-10 tasks, 256 CPU) | Avg 5 | $0.04656/hr | ~$170 |
| Load Balancer | 1 | $16.20/mo | $16 |
| NAT Gateway | 2 | $32/mo | $32 |
| Data Transfer | 100GB out | $0.02/GB | $2 |
| **Total** | | | ~$375 |

### Cost Optimization

#### Quick Wins (No Risk)

1. **Reserved Instances** (40% discount)
   ```bash
   # RDS: Purchase 1-year db.t3.small reservation
   # Savings: ~$63/month
   ```

2. **Scheduled Scaling** (Staging only)
   ```bash
   # Scale down staging to 0 tasks after hours
   # Save: 50% compute cost on staging
   ```

3. **S3 Lifecycle Policies**
   ```bash
   # Move old CloudWatch logs to Glacier after 90 days
   # Save: ~$1-5/month
   ```

#### Moderate Effort (Some Risk)

1. **Spot Instances** (75% discount, but can be interrupted)
   ```bash
   # Run 50% of staging tasks on Spot
   # Downside: May be interrupted (acceptable for staging)
   ```

2. **Smaller DB Instance** (Staging)
   ```bash
   # Use db.t3.micro for staging instead of small
   # Save: ~$50/month, minimal performance impact
   ```

3. **Consolidate** Environments
   ```bash
   # Run staging and production in same VPC
   # Save: 1 NAT gateway (~$16/month)
   # Risk: Higher isolation complexity
   ```

#### High Impact (High Risk)

1. **Multi-region** Consolidation
   ```bash
   # Move everything to cheaper region
   # But: Not good for disaster recovery
   ```

2. **Right-sizing** RDS
   ```bash
   # Smaller instance if utilization is low
   # But: Risk if traffic spikes
   ```

### Cost Monitoring

```bash
# Daily cost breakdown
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-02 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Service-by-service breakdown
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

---

## Troubleshooting Guide

### Issue: Application Not Accessible

**Symptoms**: ALB DNS name returns connection timeout

**Diagnosis**:
```bash
# 1. Check ALB is running
aws elbv2 describe-load-balancers --names task-api-alb-prod

# 2. Check target group health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:...

# 3. Check ECS tasks are running
aws ecs describe-services \
  --cluster task-api-cluster-prod \
  --services task-api-service-prod
```

**Resolution**:
- If targets unhealthy: Check security groups, health check path
- If no tasks running: Check ECS service logs, IAM permissions
- If ALB missing: Check Terraform state (terraform import)

### Issue: High Error Rate (5XX Errors)

**Symptoms**: 5XX errors > 50 in 5 minutes

**Diagnosis**:
```bash
# 1. Check application logs
aws logs tail /ecs/task-api-prod --follow

# 2. Check error type
aws logs filter-log-events \
  --log-group-name /ecs/task-api-prod \
  --filter-pattern "[level = ERROR*]" \
  --start-time $(date -d '5 minutes ago' +%s)000

# 3. Check database connectivity
aws rds describe-db-instances \
  --db-instance-identifier task-api-db-prod
```

**Common Causes & Fixes**:
- Database unreachable: Check security group, RDS status
- Memory exhausted: Check memory usage, scale up tasks
- Resource exhausted: Check CPU, connection pools
- Code bug: Review recent deployment, rollback if necessary

### Issue: High Database Latency

**Symptoms**: Response times > 500ms, CPU usage normal

**Diagnosis**:
```bash
# 1. Check RDS metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=task-api-db-prod \
  --start-time $(date -d '1 hour ago' -Iseconds) \
  --end-time $(date -Iseconds) \
  --period 60 \
  --statistics Average

# 2. Check connection pool
psql -h <db-endpoint> -U taskadmin -d taskdb \
  -c "SELECT count(*) FROM pg_stat_activity;"

# 3. Check slow queries
psql -h <db-endpoint> -U taskadmin -d taskdb \
  -c "SELECT query, calls, total_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

**Common Causes & Fixes**:
- Too many connections: Reduce connection pool size per task, scale out
- Slow queries: Add indexes, optimize queries
- Disk I/O bottleneck: Check disk metrics, scale up RDS instance
- CPU saturation: Scale up RDS instance class

### Issue: Memory Leaks (Memory Growing Over Time)

**Symptoms**: Memory utilization increasing without reset

**Diagnosis**:
```bash
# 1. Check memory trends over time
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=task-api-service-prod \
  --start-time $(date -d '24 hours ago' -Iseconds) \
  --end-time $(date -Iseconds) \
  --period 3600 \
  --statistics Average

# 2. Monitor individual task memory
docker stats <container_id>

# 3. Check application logs for goroutine leaks
grep "goroutine" /var/log/...
```

**Common Causes & Fixes**:
- Application memory leak: Fix code, implement memory limits
- Container memory leak: Check Docker version, update
- Disk cache filling: Use tmpfs mount, clean up /tmp

### Issue: Deployments Failing

**Symptoms**: Terraform apply fails, deployment stuck

**Diagnosis**:
```bash
# 1. Check Terraform state lock
aws dynamodb scan --table-name task-api-locks

# 2. Check for stuck deployments
aws ecs describe-services \
  --cluster task-api-cluster-prod \
  --services task-api-service-prod \
  --query 'services[0].deployments'

# 3. Check task definition
aws ecs describe-task-definition \
  --task-definition task-api:<version>
```

**Resolution**:
- State lock stuck: Remove lock (careful!)
  ```bash
  aws dynamodb delete-item --table-name task-api-locks \
    --key '{"LockID":{"S":"prod/terraform.tfstate"}}'
  ```
- Deployment stuck: Stop and restart
  ```bash
  aws ecs update-service \
    --cluster task-api-cluster-prod \
    --service task-api-service-prod \
    --desired-count 0
  ```

### Performance Tuning Commands

```bash
# Top 10 slowest queries (requires pg_stat_statements extension)
psql -h $RDS_HOST -U taskadmin -d taskdb <<EOF
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
EOF

# Active connections
psql -h $RDS_HOST -U taskadmin -d taskdb <<EOF
SELECT datname, usename, count(*), state
FROM pg_stat_activity
GROUP BY datname, usename, state;
EOF

# Index usage statistics
psql -h $RDS_HOST -U taskadmin -d taskdb <<EOF
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
EOF
```

---

## Production Checklist

### Pre-Deployment

- [ ] Infrastructure provisioned with Terraform
- [ ] All tests passing (unit, integration, e2e)
- [ ] Code reviewed by 2+ engineers
- [ ] Security scan completed (no critical issues)
- [ ] Performance baselines established
- [ ] Database backups tested and confirmed
- [ ] Monitoring alarms configured and tested
- [ ] On-call engineer assigned
- [ ] Incident response plan reviewed
- [ ] Rollback procedure documented

### Deployment Day

- [ ] Communication channel active (Slack/PagerDuty)
- [ ] Team lead approved deployment
- [ ] CloudWatch dashboard open and monitoring
- [ ] Database backup taken pre-deployment
- [ ] Canary metrics reviewed (first 10% traffic)
- [ ] Error rate normal (< 0.1%)
- [ ] Response times acceptable (p99 < 500ms)
- [ ] Team notified of successful deployment
- [ ] Metrics baseline updated
- [ ] Deployment documented in wiki

### Post-Deployment (1 Hour)

- [ ] Error rate remains < 0.1%
- [ ] Database connections normal
- [ ] No memory leaks detected
- [ ] ALB target group all healthy
- [ ] Customer reports: No issues
- [ ] Team retrospective scheduled (if issues)
- [ ] Metrics/alerts updated if needed

### Weekly

- [ ] Review CloudWatch alarms effectiveness
- [ ] Check cost trends vs. budget
- [ ] Review slow query logs (RDS)
- [ ] Verify backups completing successfully
- [ ] Check for storage capacity issues
- [ ] Review security group rules
- [ ] Update runbooks if procedures changed

### Monthly

- [ ] Disaster recovery drill (restore from backup)
- [ ] Security audit (IAM, network rules)
- [ ] Capacity planning review
- [ ] Cost optimization analysis
- [ ] Performance baseline comparison
- [ ] Team training on new tools/procedures
- [ ] Update documentation

### Quarterly

- [ ] Full infrastructure audit
- [ ] Security penetration testing (if applicable)
- [ ] Disaster recovery cross-region test
- [ ] Load testing and capacity planning
- [ ] Compliance review
- [ ] Vendor review (AWS pricing, support tier)
- [ ] Architecture review for scalability

---

## Quick Reference Commands

```bash
# View logs
aws logs tail /ecs/task-api-prod --follow

# Check service health
aws ecs describe-services --cluster task-api-cluster-prod --services task-api-service-prod

# Scale service
aws ecs update-service --cluster task-api-cluster-prod --service task-api-service-prod --desired-count 5

# View alarms
aws cloudwatch describe-alarms --alarm-name-prefix task-api-prod

# Get ALB DNS
aws elbv2 describe-load-balancers --names task-api-alb-prod --query 'LoadBalancers[0].DNSName'

# Database connection
psql -h $(aws rds describe-db-instances --db-instance-identifier task-api-db-prod --query 'DBInstances[0].Endpoint.Address' --output text) -U taskadmin -d taskdb

# Deploy with Terraform
terraform plan -var-file="environments/prod/terraform.tfvars"
terraform apply -var-file="environments/prod/terraform.tfvars"
```

---

## Additional Resources

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [DevOps Handbook](https://itrevolution.com/the-devops-handbook/)
- [Site Reliability Engineering](https://sre.google/books/)
