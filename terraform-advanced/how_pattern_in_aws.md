# AWS 3-Tier Architecture Pattern

This document describes the classic **3-tier application architecture on AWS** and how each tier maps to AWS networking, compute, and managed services.

---

## 🧱 What Is a 3-Tier Architecture?

A 3-tier architecture separates an application into:

1. **Web / Edge Tier** – entry point for users
2. **Application Tier** – business logic and APIs
3. **Data Tier** – databases and persistent storage

Each tier is isolated for **security**, **scalability**, and **reliability**.

---

## 🌐 Network Layout (VPC Design)

A single **VPC** spans **2–3 Availability Zones** for high availability.

Each AZ contains three subnet layers:

### 🔓 Public Subnets (Web Tier Edge)
- Route to an **Internet Gateway (IGW)**
- Contain:
  - Application Load Balancer (ALB)
  - NAT Gateway (for outbound traffic from private subnets)
- Optional:
  - Bastion host (less common today)

---

### 🔒 Private Subnets (Application Tier)
- No direct internet route
- Default route goes to **NAT Gateway**
- Contain:
  - ECS / EC2 Auto Scaling / EKS nodes / Lambda ENIs
  - Internal services and workers

---

### 🔐 Isolated / DB Subnets (Data Tier)
- No route to IGW or NAT
- Contain:
  - RDS / Aurora
  - ElastiCache
  - Other stateful services

---

## 🔄 Traffic Flow

1. User → DNS (Route53)
2. Route53 → ALB in public subnets
3. ALB → App tier in private subnets
4. App tier → Database in DB subnets
5. App tier → Internet (via NAT Gateway)
6. Database tier has no public connectivity

---

## 🔑 Security Group Model

Security Groups enforce **least privilege** between tiers.

### ALB Security Group
- Inbound: 443/80 from `0.0.0.0/0`
- Outbound: App tier port

### App Tier Security Group
- Inbound: App port only from ALB SG
- Outbound:
  - DB port to DB SG
  - Internet via NAT

### DB Tier Security Group
- Inbound: DB port only from App SG
- Outbound: minimal

---

## ☁️ AWS Services Per Tier

### Web Tier
- Route53 (DNS)
- ACM (TLS certificates)
- ALB (public)
- AWS WAF (optional)

### Application Tier
Choose one:
- ECS Fargate
- EC2 Auto Scaling Group
- EKS
- Lambda (serverless variant)

### Data Tier
- RDS / Aurora (Multi-AZ)
- ElastiCache
- S3 (assets & backups)
- Secrets Manager / SSM Parameter Store

---

## 🛡 High Availability Design

- ALB across multiple AZs
- App tier instances across multiple AZs
- RDS Multi-AZ or Aurora cluster
- No single point of failure

---

## 🧠 Why This Pattern Is Used

- Security isolation between layers
- Independent scaling per tier
- Smaller blast radius
- Compliance-friendly networking
- Easier operations and ownership

---

## 🛠 Typical Terraform Module Breakdown

