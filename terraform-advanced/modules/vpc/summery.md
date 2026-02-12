# VPC Module – Design & Implementation Summary

This document describes the Terraform VPC module used to support a
production-ready 3-tier AWS architecture across two Availability Zones.

---

## 🎯 Goals

The VPC must support:

- High availability across 2 AZs
- Public access layer (ALB, NAT)
- Private application tier (EC2)
- Fully isolated database tier (RDS)
- Outbound internet access only from private subnets via NAT
- No internet routing from database subnets

---

## 🧱 Architecture Overview

### Subnet Tiers per AZ

Each Availability Zone contains:

| Tier     | Purpose                        | Internet Access |
|----------|-------------------------------|----------------|
| Public   | ALB, NAT Gateway              | Via IGW       |
| Private  | Application EC2              | Via NAT only  |
| Isolated | Database (RDS)               | None          |

Total with 2 AZs:

- 2 Public subnets
- 2 Private subnets
- 2 Isolated subnets

---

## 📐 CIDR Layout

VPC CIDR:

Subnet allocation:

### AZ-A
- Public:   10.0.0.0/24
- Private:  10.0.10.0/24
- Isolated: 10.0.20.0/24

### AZ-B
- Public:   10.0.1.0/24
- Private:  10.0.11.0/24
- Isolated: 10.0.21.0/24

Spacing allows easy future expansion.

---

## 🌐 Internet Gateway

- One Internet Gateway is attached to the VPC.
- Public route table includes:


---

## 🚪 NAT Gateway Strategy

Two supported patterns:

### Pattern B – NAT per AZ (default)

- One NAT Gateway in each public subnet
- Private subnet in each AZ routes to its local NAT
- Higher availability
- Higher cost

### Pattern A – Single NAT (optional)

- One NAT Gateway in the first public subnet
- All private subnets route to it
- Lower cost
- Lower resilience

---

## 🗺️ Route Tables

### Public Route Table
- Associated with public subnets
- Default route to IGW

### Private Route Tables (one per AZ)
- Associated with private subnets
- Default route to NAT Gateway

### Isolated Route Tables
- Associated with isolated subnets
- No default route
- No IGW
- No NAT

---

## 🧩 Terraform Module Structure


---

## 📤 Module Outputs

The VPC module exports:

- vpc_id
- azs
- public_subnet_ids
- private_subnet_ids
- isolated_subnet_ids

These are consumed by:

- ALB module (public subnets)
- EC2 module (private subnets)
- RDS module (isolated subnets)

---

## ✅ What This VPC Provides

- Strong network isolation between tiers
- High availability across AZs
- Secure database placement
- Controlled outbound access
- Production-ready routing model
- Clean Terraform composition for downstream modules

---

## ➡️ Next Enhancement (Not Yet Implemented)

Add VPC Endpoints for:

- S3
- ECR
- CloudWatch Logs
- Systems Manager (SSM)

Purpose:

- Reduce NAT Gateway cost
- Improve security
- Keep AWS traffic inside the VPC
- Allow private EC2 management without bastions

---


