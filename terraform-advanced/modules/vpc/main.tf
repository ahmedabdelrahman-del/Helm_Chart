# Get Availability Zones (AZs)
data "aws_availability_zones" "available" {
  state = "available"
}
# Region helper + a dedicated SG for endpoints
data "aws_region" "current" {}
# Locals: pick the first N AZs + build common tags
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count) # slice(..., 0, var.az_count) takes the first az_count AZs (usually 2).

  common_tags = merge(
    { Project = var.name },
    var.tags
  )
}

# create vpc
#enable DNS stuff :
#Required for many services:
#ALB internal resolution
resource "aws_vpc" "this"{
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
    tags = merge(
        local.common_tags,
        { Name = "${var.name}-vpc" }
    )
}
# Attach an Internet Gateway (IGW). allow the traffioc
# Without IGW:
# Public subnets cannot reach the internet. 
# ALB cannot be publicly reachable.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(
    local.common_tags,
    { Name = "${var.name}-igw" }
  )
}
# Create the Public Subnets (one per AZ)
# Creates az_count public subnets (2 if az_count=2)
# Each subnet goes into a different AZ.
# Public subnets auto-assign public IPv4 to instances by default.
# ALB sits in public subnets.
# NAT Gateways must be in public subnets.
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-public-${local.azs[count.index]}"
    Tier = "public"
  })
}
# Create the Private Subnets (App Tier)
# EC2 app tier lives here:
# not reachable from internet
# can reach internet only via NAT (we’ll add routing later)
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-${local.azs[count.index]}"
    Tier = "private"
  })
}
# Create the Isolated Subnets (DB Tier)
# Database belongs here (RDS)
# These will have no route to internet (true isolation)
resource "aws_subnet" "isolated" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = var.isolated_subnet_cidrs[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.name}-isolated-${local.azs[count.index]}"
    Tier = "isolated"
  })
}
# Public Route Table + default internet route
# Creates a public route table
# Adds a default route to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-rt-public"
  })
}
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}
# Associate Public Route Table with Public Subnets
# Attaches the public route table to each public subnet.
resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
# First compute NAT count:
locals {
  nat_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.az_count) : 0
}
# Then create EIPs
resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name}-eip-nat-${count.index}"
  })
}
# Then NAT Gateways
# Gives private subnets a way out to internet without being public.
# NAT needs IGW ready (AWS can fail if IGW isn’t attached yet)
resource "aws_nat_gateway" "this" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id

  subnet_id = var.single_nat_gateway ? aws_subnet.public[0].id : aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.this]

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-${count.index}"
  })
}
# Private Route Tables + default route to NAT
# Private RT (one per AZ)
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-rt-private-${local.azs[count.index]}"
  })
}
# Route to NAT:
resource "aws_route" "private_to_nat" {
  count                  = var.enable_nat_gateway ? var.az_count : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
}
# Associate to private subnets:
# Private subnets can update packages / pull images / reach external APIs.
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
# Isolated Route Tables (no internet routes)
# DB subnets remain isolated.
# DB can still be reached from private tier inside the VPC.
# DB cannot reach the internet and the internet cannot reach DB.
resource "aws_route_table" "isolated" {
  count  = var.az_count
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-rt-isolated-${local.azs[count.index]}"
  })
}

resource "aws_route_table_association" "isolated" {
  count          = var.az_count
  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated[count.index].id
}
# SG matters: interface endpoints create ENIs in your subnets, and you must allow your instances to talk to them on 443.
resource "aws_security_group" "vpce" {
  count       = (var.enable_vpc_endpoints && var.enable_interface_endpoints) ? 1 : 0
  name        = "${var.name}-vpce-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.this.id

  # Allow HTTPS from inside the VPC to the endpoints
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  # Outbound can be open (AWS-managed services)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpce-sg"
  })
}
# S3 gateway endpoints attach to route tables.
resource "aws_vpc_endpoint" "s3" {
  count = (var.enable_vpc_endpoints && var.enable_s3_endpoint) ? 1 : 0

  vpc_id            = aws_vpc.this.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"

  # Attach to the route tables that should access S3
  # Typically: private + isolated (if DB tier needs backups/log exports to S3)
  route_table_ids = concat(
    [for rt in aws_route_table.private : rt.id],
    [for rt in aws_route_table.isolated : rt.id]
  )

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpce-s3"
  })
}
# Interface Endpoints (SSM, ECR, Logs)
#private_dns_enabled = true:
#It makes AWS service DNS names resolve to the endpoint inside the VPC automatically.
#Example: ssm.<region>.amazonaws.com resolves privately.
locals {
  interface_services = var.enable_vpc_endpoints && var.enable_interface_endpoints ? toset(var.interface_endpoint_services) : toset([])
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_services

  vpc_id            = aws_vpc.this.id
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.value}"

  subnet_ids         = [for s in aws_subnet.private : s.id]
  private_dns_enabled = true

  security_group_ids = [aws_security_group.vpce[0].id]

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpce-${replace(each.value, ".", "-")}"
  })
}

/*
EC2 instances still need to talk to AWS services like:
S3 (files, backups, artifacts)
Systems Manager (SSM)
ECR (container images)
CloudWatch Logs
Without endpoints, the network path looks like: 
EC2 (private subnet)
   ↓
NAT Gateway
   ↓
Internet
   ↓
AWS service public endpoint
With VPC endpoints:
EC2 (private subnet)
   ↓
VPC Endpoint
   ↓
AWS service (inside AWS network)
The S3 VPC endpoint is a Gateway endpoint.
That means:
It is NOT an ENI.
It does NOT sit in a subnet.
It is added to route tables.
Traffic destined for S3 is routed privately inside AWS
Why EC2 talks to S3 at all
Very common cases:
Download application artifacts
Terraform state files
Logs / exports
Backups
Machine learning models
Static assets
If you don’t add an endpoint:
👉 Every aws s3 cp from private EC2 goes through NAT.
That costs money and sends traffic through the internet edge.
Why S3 endpoint is useful
1) Cost
NAT Gateway charges per GB.
If you move 500 GB/month to S3:
Without endpoint → NAT charges
With endpoint → NAT not used
2) Security
Traffic never leaves AWS’s backbone network.
You can even:
Lock S3 buckets so they only accept traffic from your VPC endpoint.
3) Reliability
Less dependency on NAT.
You add:
S3 Endpoint because:
EC2 needs S3
You don’t want NAT charges
You want private traffic
You want to restrict buckets to your VPC
“EC2 endpoints” usually means:
SSM + ECR + Logs + STS endpoints
For managing EC2 without bastions
For private AWS API access
*/





