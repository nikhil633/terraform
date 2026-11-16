
# --------------------------------------------------
# ALB Security Group
# --------------------------------------------------

resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.project_name}-alb-"
  description = "Controls public access to the application load balancer"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-alb-sg"
    Component = "load-balancer"
    ManagedBy = "Terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Public HTTP ingress (optional)

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count = var.enable_http ? 1 : 0

  security_group_id = aws_security_group.alb_sg.id
  description       = "Public HTTP access to ALB"

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  cidr_ipv4 = "0.0.0.0/0"
}

# Public HTTPS ingress

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Public HTTPS access to ALB"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  cidr_ipv4 = "0.0.0.0/0"
}

# ALB can connect only to the application port

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Forward traffic and health checks to app instances"

  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.app_sg.id
}


# --------------------------------------------------
# Application Security Group
# --------------------------------------------------

resource "aws_security_group" "app_sg" {
  name_prefix = "${var.project_name}-app-"
  description = "Allows application traffic from the ALB only"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-app-sg"
    Component = "application"
    ManagedBy = "Terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Only the ALB security group can reach the app port

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id = aws_security_group.app_sg.id
  description       = "Application traffic from the ALB only"

  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.alb_sg.id
}

# Outbound HTTPS for package downloads and external APIs

resource "aws_vpc_security_group_egress_rule" "app_https" {
  count = var.enable_app_https_egress ? 1 : 0

  security_group_id = aws_security_group.app_sg.id
  description       = "Outbound HTTPS for updates and external APIs"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  cidr_ipv4 = "0.0.0.0/0"
}


