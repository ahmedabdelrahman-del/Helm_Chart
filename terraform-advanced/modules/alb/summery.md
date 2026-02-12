# ALB Module – Application Load Balancer (3-Tier Architecture)

This module provisions an AWS Application Load Balancer (ALB)
as the public entry point of a 3-tier architecture.

It handles inbound traffic from the Internet
and forwards it securely to the Application tier.

---

# 🎯 Purpose

The ALB module provides:

- Internet-facing load balancer
- HTTP listener
- Target group for application instances
- Health checks
- Integration with security groups
- High availability across multiple AZs

---

# 🧱 Architecture Role

In the 3-tier design:

Internet → ALB → App Tier → Database

The ALB is the only publicly accessible component.
It distributes traffic across application instances
located in private subnets.

---

# 🏗 Resources Created

## 1️⃣ Application Load Balancer (`aws_lb`)

- Type: `application`
- Placed in public subnets
- Attached to ALB Security Group
- Internet-facing by default
- Highly available across multiple AZs

Security:
- Inbound allowed on 80/443 (controlled by SG)
- No direct access to EC2 instances

---

## 2️⃣ Target Group (`aws_lb_target_group`)

- Defines where ALB forwards traffic
- Target type:
  - `instance` (for EC2 / ASG)
  - `ip` (for ECS / EKS)
- Configurable application port
- Health check configuration included

Health Check:
- Path: `/`
- Success range: `200–399`
- Interval: 30 seconds
- Automatically removes unhealthy targets

---

## 3️⃣ Listener (`aws_lb_listener`)

- Listens on HTTP (port 80)
- Default action: forward to target group

Flow:

Client → ALB:80 → Target Group → App EC2

HTTPS can be added later with ACM certificates.

---

# 🔄 Traffic Flow

Allowed traffic:

✅ Internet → ALB (80/443)  
✅ ALB → App instances (app_port)  

Blocked traffic:

❌ Internet → App instances directly  
❌ Internet → Database  

The ALB acts as a controlled entry gateway.

---

# 📦 Module Inputs

- `vpc_id`
- `public_subnet_ids`
- `alb_security_group_id`
- `listener_port`
- `target_port`
- `health_check_path`
- `target_type`
- `internal` (internet-facing or internal)
- `tags`

---

# 📤 Module Outputs

- `alb_arn`
- `alb_dns_name`
- `alb_zone_id`
- `target_group_arn`

The `target_group_arn` is consumed by the Compute module
to register EC2 instances or an Auto Scaling Group.

---

# 🔐 Security Model

- ALB is the only public-facing resource.
- Protected by its own security group.
- Application tier is not directly exposed.
- Enforces separation between public and private layers.

---

# 🏗 Why This Design Is Production-Ready

- Multi-AZ deployment
- Health checks and automatic failover
- Clean separation of tiers
- Compatible with EC2, ECS, or EKS
- Easily extended to HTTPS with ACM
- Supports Auto Scaling integration

---

# 🎤 Interview Explanation (Short Version)

“The ALB is the only public entry point. It listens on HTTP and forwards traffic to a target group associated with the application tier. Health checks ensure only healthy instances receive traffic. The application servers remain private and are never directly exposed to the Internet.”

---

# ✅ Next Module

Next logical step:

Compute Module (EC2 + Auto Scaling Group)

This will:
- Launch application instances
- Attach the App Security Group
- Register instances into the ALB target group
- Complete the end-to-end request path
