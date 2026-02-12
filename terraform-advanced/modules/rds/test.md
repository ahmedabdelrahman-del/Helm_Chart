# RDS Connectivity Test – 3-Tier Architecture Validation

This document describes how to validate database connectivity
from the Application tier (EC2 in private subnets)
to the Database tier (RDS in isolated subnets).

The goal is to prove:

- Network routing is correct
- Security groups are correctly configured
- RDS is reachable only from the App tier
- SSL connectivity works
- Authentication works

---

# 🎯 Architecture Context

Internet → ALB → EC2 (App Tier) → RDS (DB Tier)

- EC2 instances run in private subnets
- RDS runs in isolated subnets
- DB security group allows inbound only from App security group
- RDS is not publicly accessible

---

# 🔐 Step 1 – Connect to EC2 via SSM

Use AWS Systems Manager Session Manager:

AWS Console → Systems Manager → Session Manager → Start Session

Select one of the application EC2 instances.

---

# 🔎 Step 2 – Connect to RDS Using SSL

Run:

```bash
psql "host=<db-endpoint> port=5432 dbname=appdb user=appadmin sslmode=require"
# psql "host=vpc-test-db.cm7kuw8a8p5h.us-east-1.rds.amazonaws.com port=5432 dbname=appdb user=appadmin sslmode=require"
Expected result:
appdb=>
#########
Validate Connection Details:
# \conninfo
This confirms:
Host
Port
SSL usage
Current user
#####################
Verify Database Identity
# SELECT current_database(), current_user, inet_client_addr();
Expected:
Database: appdb
User: appadmin
Client address: private EC2 IP
######################
Functional Test (Create Table + Insert Data):

CREATE TABLE IF NOT EXISTS healthcheck (
  id SERIAL PRIMARY KEY,
  note TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO healthcheck(note)
VALUES ('RDS connectivity test from app tier');

SELECT * FROM healthcheck ORDER BY id DESC LIMIT 5;

Expected:
Table created successfully
Insert successful
Row returned in SELECT query
This confirms:
Write access works
Read access works
Full application-tier database interaction is functional
