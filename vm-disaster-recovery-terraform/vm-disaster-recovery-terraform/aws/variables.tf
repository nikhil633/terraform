variable "primary_region" {
  description = "AWS region where the existing EC2 instance runs."
  type        = string
  default     = "ap-south-1"
}

variable "destination_region" {
  description = "Different AWS region for the cross-region backup copy."
  type        = string
  default     = "ap-southeast-1"
}

variable "ec2_instance_arn" {
  description = "ARN of the existing EC2 instance to protect."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for backup resources."
  type        = string
  default     = "ec2"
}
