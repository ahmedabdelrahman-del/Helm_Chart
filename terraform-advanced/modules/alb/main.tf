locals {
  common_tags = merge(
    { Project = var.name },
    var.tags
  )
}
# create the ALB
# internet-facing ALB (by default) placed in public subnets
# Protected by  sg_alb
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = var.internal

  security_groups = [var.alb_security_group_id]
  subnets         = var.public_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.name}-alb"
    Tier = "alb"
  })
}
# Create the Target Group
# ALB forwards requests to a target group (instances/IPs).
# Later ASG/EC2 module registers instances into this target group.
resource "aws_lb_target_group" "app" {
  name        = "${var.name}-tg-${var.target_port}"
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-tg"
    Tier = "alb"
  })
}
# Create the Listener (HTTP)
# Listens on port 80
# Forwards traffic to your target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

