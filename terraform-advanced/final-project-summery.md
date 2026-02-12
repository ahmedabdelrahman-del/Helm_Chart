# AWS 3-Tier Architecture – Full Infrastructure Summary

This document describes a production-ready 3-tier architecture
implemented using Terraform on AWS.

The architecture includes:

- VPC Networking
- Security Layer
- Application Load Balancer
- Auto Scaling EC2 Application Tier
- RDS Database Tier
- Private connectivity and secure management

---

# 🏗 High-Level Architecture

Internet  
   ↓  
Application Load Balancer (Public Subnets)  
   ↓  
EC2 Application Tier (Private Subnets)  
   ↓  
RDS Database (Isolated Subnets)

---

# 1️⃣ Networking Layer (VPC Module)

## VPC Design

- Custom VPC with CIDR block (e.g., 10.0.0.0/16)
- Multi-AZ deployment (2 Availability Zones)
- Subnet segmentation:
  - Public subnets
  - Private subnets
  - Isolated subnets

## Routing

### Public Subnets
- Route: 0.0.0.0/0 → Internet Gateway
- Used for ALB and NAT Gateway

### Private Subnets
- Route: 0.0.0.0/0 → NAT Gateway
- Used for EC2 instances
- No public IPs assigned

### Isolated Subnets
- No default route to Internet
- Used for RDS only

---

# 2️⃣ Security Layer (Security Groups)

## ALB Security Group
- Inbound: 80/443 from 0.0.0.0/0
- Outbound: app_port to App SG

## App Security Group
- Inbound: app_port from ALB SG
- Outbound: db_port to DB SG

## DB Security Group
- Inbound: db_port from App SG only
- No public access allowed

## Security Model
- Least privilege networking
- Tier-to-tier access only
- No direct Internet → App
- No direct Internet → DB

---

# 3️⃣ Load Balancing Layer (ALB Module)

## Application Load Balancer
- Internet-facing
- Deployed in 2 public subnets (Multi-AZ)
- Protected by ALB security group

## Target Group
- Targets: EC2 instances (instance mode)
- Health checks enabled
- Automatic unhealthy target removal

## Listener
- HTTP (port 80)
- Forwards to target group

---

# 4️⃣ Compute Layer (EC2 + Auto Scaling)

## Launch Template
- Amazon Linux 2 AMI
- App security group attached
- IAM role for SSM
- User data to configure application

## Auto Scaling Group
- Deployed in private subnets
- Desired capacity (e.g., 2)
- ELB health checks enabled
- Multi-AZ high availability

## Secure Management
- No public IPs
- Managed via Systems Manager (SSM)
- No SSH exposure required

---

# 5️⃣ Database Layer (RDS Module)

## RDS Configuration
- Engine: PostgreSQL
- Multi-AZ enabled
- Encrypted storage
- Backup retention enabled
- Not publicly accessible

## Deployment
- Deployed in isolated subnets
- Attached to DB security group

## Access Control
- Only App SG allowed inbound on DB port
- SSL connectivity enforced

---

# 6️⃣ Connectivity Validation

The architecture was validated by:

1. Accessing ALB DNS from browser
2. Confirming healthy targets
3. Connecting to EC2 via SSM
4. Connecting from EC2 → RDS using SSL
5. Creating a test table and inserting data

This confirms:

- Routing is correct
- Security groups are correct
- Isolation between tiers is enforced
- Application can securely access database

---

# 🔒 Security Highlights

- No public EC2 instances
- No direct DB exposure
- Private subnet isolation
- NAT for controlled egress
- SSL database connections
- IAM roles instead of SSH keys
- Least privilege security groups

---

# 🚀 High Availability & Scalability

- Multi-AZ deployment
- Auto Scaling Group for horizontal scaling
- RDS Multi-AZ failover
- Load balancing across instances
- Self-healing instances

---

# 📈 Production-Ready Enhancements (Optional)

- HTTPS with ACM
- Route53 DNS
- WAF integration
- Secrets Manager for DB credentials
- Auto Scaling policies (CPU-based)
- CloudWatch alarms & monitoring
- RDS read replicas
- CI/CD integration

---

# 🎤 Interview Summary (Short Version)

“I implemented a production-ready 3-tier architecture using Terraform. The VPC is segmented into public, private, and isolated subnets across multiple AZs. The ALB is the only public entry point. Application servers run in private subnets behind an Auto Scaling Group and are managed securely via SSM. The RDS database runs in isolated subnets and is only accessible from the application tier. Security groups enforce least privilege between tiers, and connectivity was validated using SSL connections from the app tier to the database.”

---

# ✅ Architecture Outcome

The system is:

- Secure
- Highly available
- Horizontally scalable
- Production-aligned
- Fully infrastructure-as-code managed
- Fully validated end-to-end
