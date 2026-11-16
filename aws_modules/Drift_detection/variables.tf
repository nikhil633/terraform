variable "cidr_block" {
  description = "cidr block for vpc main"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets with stable names, availability zones and CIDR"

  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))

  validation {
    condition     = length(var.public_subnets) > 0
    error_message = "atleast one public subnet must be configured"
  }
  validation {
    condition = length(distinct([
      for subnet in values(var.public_subnets) : subnet.cidr_block
    ])) == length(var.public_subnets)
    error_message = "The Public subnet CIDRs should not be unique"
  }
}

variable "availability_zones" {
  description = "Allowed Availability Zones for subnet placement."
  type        = list(string)
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
  validation {
    condition     = contains(["dev", "prod", "staging", "prod"], var.environment)
    error_message = "Environment must e dev, prod, staging or prod"
  }
}

variable "common_tags" {
  description = "Common tags applied to AWS resources."
  type        = map(string)
  default     = {}
}

variable "private_subnets" {
  description = "Map of private subnets with stable names, availability zones and CIDR"

  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))

  validation {
    condition     = length(var.private_subnets) > 0
    error_message = "atleast one private subnet must be configured"
  }
  validation {
    condition = length(distinct([
      for subnet in values(var.private_subnets) : subnet.cidr_block
    ])) == length(var.private_subnets)
    error_message = "The Public subnet CIDRs should not be unique"
  }
}


variable "project_name" {
  description = "Name of the application or infrastructure project."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "nat_gateways" {
  description = "NAT Gateway configuration keyed by Availability Zone."

  type = map(object({
    public_subnet_key = string
    availability_zone = string
  }))

  validation {
    condition     = length(var.nat_gateways) > 0
    error_message = "At least one NAT Gateway must be configured."
  }

  validation {
    condition = (
      length(distinct([
        for nat in values(var.nat_gateways) : nat.availability_zone
      ])) == length(var.nat_gateways)
    )

    error_message = "Configure at most one NAT Gateway per Availability Zone."
  }
}

variable "app_port" {
  description = "Port on which the application instances listen"
  type        = number
  default     = 80

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "enable_http" {
  description = "Allow HTTP to the public ALB, usually for redirecting to HTTPS"
  type        = bool
  default     = true
}

variable "enable_app_https_egress" {
  description = "Allow application instances to make outbound HTTPS connections"
  type        = bool
  default     = true
}



variable "bucket_name_prefix" {
  description = "Lowercase, globally unique-compatible S3 bucket name prefix"
  type        = string
  default     = "terraform-day15-prod"

  validation {
    condition = (
      length(var.bucket_name_prefix) >= 3 &&
      length(var.bucket_name_prefix) <= 54 &&
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name_prefix))
    )

    error_message = "Prefix must be 3-54 characters, use lowercase letters, numbers and hyphens, and start/end with a letter or number."
  }
}


variable "ami_id" {
  description = "Approved, tested application AMI ID"
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "ami_id must be a valid-format AWS AMI ID."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the application"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum ASG capacity"
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 2
    error_message = "Production minimum capacity must be at least 2."
  }
}

variable "max_size" {
  description = "Maximum ASG capacity"
  type        = number
  default     = 6

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be greater than or equal to min_size."
  }
}

variable "desired_capacity" {
  description = "Initial desired number of instances"
  type        = number
  default     = 2

  validation {
    condition = (
      var.desired_capacity >= var.min_size &&
      var.desired_capacity <= var.max_size
    )
    error_message = "desired_capacity must be between min_size and max_size."
  }
}

variable "root_device_name" {
  description = "Root block device name for the selected AMI"
  type        = string
  default     = "/dev/xvda"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "Root volume must be at least 8 GiB."
  }
}



variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the application domain"
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:acm:", var.acm_certificate_arn))
    error_message = "Provide a valid ACM certificate ARN."
  }
}

variable "alb_access_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to AWS resources"
  type        = map(string)
  default = {
    Project = "Application"
    Owner   = "Platform-Team"
  }
}


