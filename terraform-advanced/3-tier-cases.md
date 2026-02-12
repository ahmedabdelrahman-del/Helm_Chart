# 1) interview-question:
Describe a 3-tier architecture on AWS.”
You answer:
A VPC across multiple AZs with public subnets for ALBs and NAT gateways, private subnets for application compute that route outbound through NAT, and isolated subnets for databases. Traffic flows from ALB → app tier → DB, enforced by route tables and security groups.
# 2) 👉 What changes in a 3-tier design when the app tier is Kubernetes/EKS instead of ECS or EC2?
Internet
   |
Route53
   |
Public Subnets
   |
ALB / NLB
   |
Private Subnets (EKS Worker Nodes)
   |
Pods / Services / Ingress
   |
Databases in Isolated Subnets
# web tier still the same changes will applied in app tier 
