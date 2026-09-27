variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "bastion-ec2"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}


variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}





variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH to EC2"
  type        = string
}