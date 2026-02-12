# RDS Module – Database Tier (3-Tier Architecture)

This module provisions the **Database tier** for a production-ready 3-tier AWS architecture.

It creates an **RDS instance** inside **isolated subnets**, attaches the **DB security group**, and exposes the database endpoint for application connectivity.

---

## 🎯 Purpose

The RDS module provides:

- A managed relational database (RDS)
- DB Subnet Group using **isolated subnets**
- Security group attachment to enforce least-privilege access
- Optional Multi-AZ (high availability)
- Encryption and backups
- Outputs for endpoint/port/db name

---

## 🧱 Architecture Role

In the 3-tier design:

Internet → ALB → EC2 (App Tier) → RDS (DB Tier)

The RDS instance is placed in **isolated subnets** and is **not publicly accessible**.

---

## 🏗 Resources Created

### 1️⃣ DB Subnet Group (`aws_db_subnet_group`)
- Built from `isolated_subnet_ids`
- Ensures RDS is deployed only in isolated/private networking
- Provides HA capability across multiple AZs

### 2️⃣ RDS Instance (`aws_db_instance`)
Configured with:

- Engine (default: Postgres)
- Instance class (default: `db.t4g.micro`)
- Allocated storage (default: 20 GB)
- Master username + password
- Port (default: 5432)
- `publicly_accessible = false`
- Security group attached (`db_security_group_id`)
- Storage encryption enabled (default: true)
- Backups enabled (default retention: 7 days)
- Optional Multi-AZ (default: true)

---

## 🔒 Security Model

Database access is controlled by:

1) **Subnet placement**
- RDS is deployed in **isolated subnets**
- Isolated subnets have **no default route to the internet**
- No IGW and no NAT routes for the DB tier

2) **Security groups**
- DB security group allows inbound only from App tier security group on DB port:
  - Example: App → DB on `5432`
- No public inbound traffic is allowed

Result:
- Database is not reachable from the internet
- Only the application tier can connect to it

---

## 🔄 Allowed Traffic Flow

✅ App tier → DB tier (`db_port`)  
❌ Internet → DB (blocked)  
❌ ALB → DB (blocked)  
❌ Any other tier → DB (blocked)

---

## 📦 Module Inputs

- `name`
- `vpc_id`
- `isolated_subnet_ids`
- `db_security_group_id`
- `engine` (default: postgres)
- `engine_version` (optional)
- `instance_class`
- `allocated_storage`
- `db_name`
- `username`
- `password` (sensitive)
- `port` (default: 5432)
- `multi_az` (default: true)
- `publicly_accessible` (default: false)
- `storage_encrypted` (default: true)
- `backup_retention_period` (default: 7)
- `deletion_protection`
- `skip_final_snapshot`
- `tags`

---

## 📤 Module Outputs

- `db_instance_id`
- `db_endpoint`
- `db_port`
- `db_name`

These outputs are consumed by the application layer to configure database connectivity.

---

## ✅ Production-Ready Characteristics

- Deployed in isolated subnets (no internet routing)
- Security group restricts access to app tier only
- Supports Multi-AZ for high availability
- Supports encryption at rest
- Supports automated backups
- Easy to extend with:
  - Secrets Manager for credentials
  - KMS key management
  - Parameter groups
  - Read replicas / clustering

---

## 🎤 Interview Explanation (Short Version)

“I deployed the database tier using RDS in isolated subnets to prevent internet access. The DB security group only allows inbound from the app tier on the database port, enforcing least-privilege networking. Multi-AZ, encryption, and backups provide production-grade reliability and security.”

---
