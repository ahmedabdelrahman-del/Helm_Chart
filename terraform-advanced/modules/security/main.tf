locals {
  common_tags = merge(
    { Project = var.name },
    var.tags
  )
}
# Create ALB Security Group 
# ALB is public-facing, so inbound is from the internet (80/443). Outbound goes to the app SG.
resource "aws_security_group" "alb" {
  name        = "${var.name}-sg-alb"
  description = "ALB security group (public entry)"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name}-sg-alb"
    Tier = "alb"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count             = var.enable_http_on_alb ? 1 : 0
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count             = var.enable_https_on_alb ? 1 : 0
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow ALB to reach app on app_port"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.app.id
}
# Create App Security Group
# Inbound only from ALB on app_port. Egress is typically open (instances need updates, APIs, etc. via NAT).
resource "aws_security_group" "app" {
  name        = "${var.name}-sg-app"
  description = "App tier security group (private)"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name}-sg-app"
    Tier = "app"
  })
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow app traffic from ALB"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "app_to_internet" {
  count             = var.allow_app_egress_to_internet ? 1 : 0
  security_group_id = aws_security_group.app.id
  description       = "Allow app egress (via NAT for internet access)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
# Create DB Security Group
# DB should only accept traffic from the app SG on the DB port.
resource "aws_security_group" "db" {
  name        = "${var.name}-sg-db"
  description = "DB tier security group (isolated)"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name}-sg-db"
    Tier = "db"
  })
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "Allow DB access from app tier only"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "db_egress" {
  security_group_id = aws_security_group.db.id
  description       = "Allow DB egress (patching/monitoring as needed)"
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}
