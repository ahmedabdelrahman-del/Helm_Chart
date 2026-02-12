############################################################
# What Is a 3-Tier Architecture?
# A classic 3-tier system separates an application into:
# 1) Presentation / Web tier
 -> Handles user traffic (UI, API gateway, load balancer)
# 2️⃣ Application tier
 → Business logic (services, APIs, workers)
# 3️⃣ Data tier
 → Databases, caches, storage
 Each tier is isolated and scaled independently.
# Why Companies Use This Architecture
This pattern isn’t about being fancy — it solves real production problems.
##############################################################
1. Security (Big One)
You don’t want:
your database exposed to the internet ❌
your app servers directly reachable ❌
So:
Web tier in public subnets
App tier in private subnets
DB tier in more restricted private subnets
Only specific traffic is allowed between them.
👉 This is defense in depth.
###############################################################
2. Scalability
Traffic spikes?
scale web/API layer horizontally
scale app tier separately
database tuned independently
You’re not forced to scale everything together.
###############################################################
3. Reliability
If one tier misbehaves:
load balancer keeps serving healthy nodes
DB stays protected
blast radius is limited
Also easy to deploy blue/green or rolling updates in one tier without touching others.
################################################################
4. Maintainability
Teams can own tiers:
frontend team → web tier
backend team → app tier
platform/DB team → data tier
Changes in one tier don’t break the others.
#################################################################
5. Compliance & Auditing
For regulated industries:
DB locked in private network
IAM tightly scoped
logging per tier
access controlled
Auditors love this 😅
#################################################################
Why Terraform Is Relevant Here
Terraform isn’t required for 3-tier architecture…
…but:
👉 cloud infra is code now.
Terraform lets you:
version control your architecture
recreate environments
avoid manual console clicking
enforce consistency
build prod-like setups for learning
############################################################
Internet
   |
Route53
   |
Public Subnets (Web Tier)
   |
ALB
   |
Private Subnets (App Tier)
   |
Databases in Isolated Subnets (Data Tier)

