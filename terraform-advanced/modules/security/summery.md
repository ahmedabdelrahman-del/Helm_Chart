# Security Module – 3-Tier Architecture Summary

This module implements Security Groups for a production-ready
3-tier AWS architecture.

The goal is to enforce **least privilege network access**
between Public, Application, and Database tiers.

---

## 🎯 Design Principles

- Only the ALB is publicly accessible.
- Application servers are never publicly reachable.
- Database is never reachable from the internet.
- Traffic is allowed only between required tiers.
- Security groups reference other security groups instead of CIDR blocks.
- Default-deny model (only explicitly allowed traffic is permitted).

---

# 🧱 Security Groups Created

## 1️⃣ ALB Security Group (Public Entry)

Purpose:
- Acts as the only public entry point into the system.

Inbound Rules:
- Allow HTTP (80) from `0.0.0.0/0` (optional)
- Allow HTTPS (443) from `0.0.0.0/0` (optional)

Outbound Rules:
- Allow traffic to App Security Group on `app_port`

Result:
- Internet users can reach ALB only.
- ALB forwards traffic to App tier.

---

## 2️⃣ App Security Group (Private Tier)

Purpose:
- Protect application EC2 instances in private subnets.

Inbound Rules:
- Allow `app_port` traffic only from ALB Security Group

Outbound Rules:
- Allow traffic to DB Security Group on `db_port`
- (Optionally) Allow egress to internet via NAT for updates/APIs

Result:
- App cannot be reached directly from internet.
- Only ALB can send traffic to App.
- App can connect to Database.

---

## 3️⃣ Database Security Group (Isolated Tier)

Purpose:
- Protect RDS or database instances in isolated subnets.

Inbound Rules:
- Allow `db_port` only from App Security Group

Outbound Rules:
- Allow traffic only inside VPC CIDR (optional best practice)

Result:
- Database is never publicly accessible.
- Only App tier can connect to DB.
- No direct Internet or ALB access to DB.

---

# 🔄 Allowed Traffic Flow

✅ Internet → ALB (80/443)  
✅ ALB → App (`app_port`)  
✅ App → Database (`db_port`)  

❌ Internet → App (blocked)  
❌ Internet → Database (blocked)  
❌ ALB → Database (blocked)  
❌ Any random resource → Database (blocked)

---

# 🔐 Security Model

Security Groups act as **stateful virtual firewalls** at the ENI level.

They control:

- Source
- Destination
- Protocol
- Port

They do NOT control:

- Application authentication
- Database user permissions
- IAM roles
- OS-level firewall rules

Those are separate layers of security.

---

# 🏗 Why This Design is Production-Ready

- Enforces strict tier separation
- Prevents lateral movement inside VPC
- Follows AWS best practices
- Implements least privilege networking
- Clear and easy to explain in interviews

---

# 🎤 Interview Explanation (Short Version)

“I implemented three security groups aligned to the tiers. The ALB is the only public entry point. The App tier only accepts traffic from the ALB, and the Database only accepts traffic from the App tier. This enforces least-privilege east-west communication and prevents direct database exposure.”

---

# ✅ Next Modules in Architecture

After Security module:

1. ALB Module
2. Compute (EC2 / Auto Scaling)
3. RDS Module
4. Route53 (DNS)

The security layer now correctly enforces networking boundaries
for the entire 3-tier system.
