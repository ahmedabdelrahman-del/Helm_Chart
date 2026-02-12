# Compute Module – EC2 + Auto Scaling Group (3-Tier Architecture)

This module provisions the Application tier
in a production-ready 3-tier architecture.

It launches EC2 instances inside private subnets,
attaches the correct security group,
and automatically registers them with the ALB target group.

---

# 🎯 Purpose

The Compute module provides:

- EC2 instances in private subnets
- Launch Template for instance configuration
- Auto Scaling Group (ASG)
- IAM role for secure instance management
- Integration with ALB target group
- Horizontal scaling capability

---

# 🧱 Architecture Role

In the 3-tier design:

Internet → ALB → EC2 (App Tier) → Database

The Compute module represents the **Application layer**.
It is never directly exposed to the Internet.

---

# 🏗 Resources Created

## 1️⃣ Launch Template (`aws_launch_template`)

Defines:

- AMI (Amazon Linux 2)
- Instance type (default: t3.micro)
- App Security Group
- IAM Instance Profile
- User data script (installs Apache for demo)

Purpose:
- Standardized configuration for EC2 instances
- Reusable and versioned infrastructure definition

---

## 2️⃣ IAM Role + Instance Profile

- Grants EC2 permission to use Systems Manager (SSM)
- Enables secure remote access via Session Manager
- Removes need for SSH or bastion host

Security Benefit:
- No public IP required
- No inbound SSH (port 22) required

---

## 3️⃣ Auto Scaling Group (`aws_autoscaling_group`)

Configured with:

- Private subnet placement
- Desired capacity (default: 2)
- Min/Max scaling limits
- Health check type: ELB
- Automatic registration to ALB target group

Purpose:
- High availability across multiple AZs
- Self-healing instances
- Horizontal scaling

---

# 🔄 Traffic Flow

Allowed traffic:

✅ ALB → EC2 on application port  
✅ EC2 → Database on DB port  
✅ EC2 → Internet via NAT (for updates/APIs)  

Blocked traffic:

❌ Internet → EC2 directly  
❌ Internet → Database  

The Application tier is private and protected.

---

# 🔐 Security Model

- EC2 instances have no public IPs
- Only accessible through ALB
- Managed securely via SSM
- Attached to App Security Group
- Database access restricted to App SG

---

# 📦 Module Inputs

- `vpc_id`
- `private_subnet_ids`
- `app_security_group_id`
- `target_group_arn`
- `instance_type`
- `desired_capacity`
- `min_size`
- `max_size`
- `app_port`
- `tags`

---

# 📤 Module Outputs

- `asg_name`
- `launch_template_id`

The Auto Scaling Group automatically registers instances
with the ALB target group.

---

# 🏗 Why This Design Is Production-Ready

- Instances are deployed in private subnets
- Multi-AZ high availability
- Auto Scaling capability
- Health check integration with ALB
- Self-healing infrastructure
- Secure instance management via SSM
- No direct public exposure

---

# 🎤 Interview Explanation (Short Version)

“I provisioned the application tier using a Launch Template and Auto Scaling Group in private subnets. Instances attach the App Security Group and automatically register with the ALB target group. The ASG ensures high availability and self-healing, and instances are managed securely via SSM without exposing SSH.”

---

# ✅ Next Modules

Next logical enhancements:

- RDS Module (Database Tier)
- HTTPS with ACM
- Route53 DNS
- Scaling policies (CPU-based auto scaling)
- WAF integration

The Compute module completes the end-to-end flow:

Internet → ALB → EC2 (App Tier)
