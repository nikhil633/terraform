variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "bucket_prefix" {
  type    = string
  default = "company-static-website-"
}

variable "domain_name" {
  description = "Website domain name"
  type        = string
}

variable "route53_zone_id" {
  description = "Existing Route53 hosted zone ID"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN created in us-east-1"
  type        = string
}