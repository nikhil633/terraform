resource "aws_lb" "app_lb" {
  name               = "app-production-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]
  subnets         = aws_subnet.public[*].id

  # Production protection
  enable_deletion_protection = false
  enable_http2               = false
  idle_timeout               = 60

  # Access logging. The S3 bucket must already exist,
  # and its bucket policy must allow ALB log delivery.
  access_logs {
    bucket  = var.alb_access_logs_bucket
    prefix  = "application-alb"
    enabled = true
  }

  # Reject malformed HTTP headers
  drop_invalid_header_fields = true

  tags = merge(var.common_tags, {
    Name        = "app-production-alb"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  lifecycle {
    precondition {
      condition     = length(aws_subnet.public) >= 2
      error_message = "The production ALB must use at least two public subnets."
    }
  }
}




resource "aws_lb_target_group" "app_tg" {
  name        = "app-production-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  # Allow in-flight requests to finish during deregistration.
  deregistration_delay = 30

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  # Avoid sending traffic to an instance before it is healthy.
  slow_start = 30

  tags = merge(var.common_tags, {
    Name        = "app-production-tg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.common_tags, {
    Name        = "app-http-redirect"
    Environment = var.environment
  })
}



resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = var.acm_certificate_arn
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  tags = merge(var.common_tags, {
    Name        = "app-https-listener"
    Environment = var.environment
  })
}


