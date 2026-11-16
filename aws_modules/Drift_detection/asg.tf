
###############################################################################
# Variables expected:
# var.ami_id
# var.instance_type
# var.min_size
# var.max_size
# var.desired_capacity
#
# Existing resources:
# aws_security_group.app_sg
# aws_subnet.private
# aws_lb_target_group.app_tg
#
# Recommended existing resource:
# aws_iam_instance_profile.app
###############################################################################

locals {
  app_name    = "app"
  environment = "production"

  common_tags = {
    Application = local.app_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

###############################################################################
# EC2 LAUNCH TEMPLATE
###############################################################################

resource "aws_launch_template" "app" {
  name_prefix            = "app-production-"
  description            = "Production launch template for the app ASG"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  update_default_version = true

  # Attach only the application SG.
  # Do not attach a public SSH-access security group.
  vpc_security_group_ids = [
    aws_security_group.app_sg.id
  ]

  # IAM instance profile with least-privilege permissions.
  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  # Application bootstrap script.
  # Prefer baking stable dependencies into a tested AMI.
  user_data = filebase64("${path.module}/scripts/user_data.sh")

  # IMDSv2 required.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # EBS optimization.
  ebs_optimized = true

  # Encrypt the root volume and delete it with the instance.
  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # One-minute EC2 CloudWatch metrics.
  monitoring {
    enabled = true
  }

  # Apply tags to the instance.
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "app-production"
    })
  }

  # Apply tags to EBS volumes created by this template.
  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "app-production-volume"
    })
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = trimspace(var.ami_id) != ""
      error_message = "ami_id must be a non-empty AMI ID."
    }

    precondition {
      condition     = var.root_volume_size >= 8
      error_message = "root_volume_size must be at least 8 GiB."
    }
  }
}

###############################################################################
# AUTO SCALING GROUP
###############################################################################

resource "aws_autoscaling_group" "app_asg" {
  name = "app-production-asg"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = aws_subnet.private[*].id

  target_group_arns = [
    aws_lb_target_group.app_tg.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Helps determine when a newly launched instance is ready for
  # scaling calculations.
  default_instance_warmup = 300

  # Enables replacement capacity for certain Spot interruption scenarios.
  # Most useful if the ASG uses a mixed instances policy with Spot capacity.
  capacity_rebalance = true

  # Distribute capacity across Availability Zones.
  availability_zone_distribution {
    capacity_distribution_strategy = "balanced-best-effort"
  }

  # Use an explicit version instead of "$Latest".
  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # Safely roll out launch template changes.
  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 300
      skip_matching          = true
    }

    triggers = ["launch_template"]
  }

  # Useful ASG operational metrics.
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  # ASG-level tags propagate to launched instances.
  tag {
    key                 = "Name"
    value               = "app-production"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = local.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  lifecycle {
    # Allow the scaling policy to control runtime capacity without
    # Terraform resetting desired capacity on every plan.
    ignore_changes = [desired_capacity]

    precondition {
      condition = (
        var.min_size >= 2 &&
        var.max_size >= var.min_size &&
        var.desired_capacity >= var.min_size &&
        var.desired_capacity <= var.max_size
      )

      error_message = "Capacity must satisfy: 2 <= min_size <= desired_capacity <= max_size."
    }

    precondition {
      condition     = length(distinct(aws_subnet.private[*].availability_zone)) >= 2
      error_message = "Production ASG must span at least two Availability Zones."
    }
  }
}

###############################################################################
# TARGET TRACKING AUTOSCALING POLICY
###############################################################################

resource "aws_autoscaling_policy" "target_tracking" {
  name                   = "app-production-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60.0
  }
}


# resource "aws_sns_topic" "app_alerts" {
#   name = "app-production-alerts"

#   tags = {
#     Environment = "production"
#     ManagedBy   = "Terraform"
#   }
# }

# variable "alert_email" {
#   description = "Email address for production alerts"
#   type        = string
# }

# resource "aws_sns_topic_subscription" "app_alerts_email" {
#   topic_arn = aws_sns_topic.app_alerts.arn
#   protocol  = "email"
#   endpoint  = var.alert_email
# }


# resource "aws_cloudwatch_metric_alarm" "high_cpu" {
#   alarm_name        = "app-production-high-cpu"
#   alarm_description = "ASG average CPU utilization is above 80%."

#   namespace   = "AWS/EC2"
#   metric_name = "CPUUtilization"
#   statistic   = "Average"
#   period      = 300

#   evaluation_periods  = 3
#   datapoints_to_alarm = 2

#   comparison_operator = "GreaterThanThreshold"
#   threshold           = 80

#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.app_asg.name
#   }

#   treat_missing_data = "notBreaching"

#   alarm_actions = [
#     aws_sns_topic.app_alerts.arn
#   ]

#   ok_actions = [
#     aws_sns_topic.app_alerts.arn
#   ]

#   tags = {
#     Environment = "production"
#     ManagedBy   = "Terraform"
#   }
# }


# resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
#   alarm_name        = "app-production-unhealthy-targets"
#   alarm_description = "One or more application targets are unhealthy."

#   namespace   = "AWS/ApplicationELB"
#   metric_name = "UnHealthyHostCount"
#   statistic   = "Maximum"
#   period      = 60

#   evaluation_periods  = 2
#   datapoints_to_alarm = 2

#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   threshold           = 1

#   dimensions = {
#     TargetGroup  = aws_lb_target_group.app_tg.arn_suffix
#     LoadBalancer = aws_lb.app.arn_suffix
#   }

#   treat_missing_data = "notBreaching"

#   alarm_actions = [
#     aws_sns_topic.app_alerts.arn
#   ]

#   ok_actions = [
#     aws_sns_topic.app_alerts.arn
#   ]

#   tags = {
#     Environment = "production"
#     ManagedBy   = "Terraform"
#   }
# }


