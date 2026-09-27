aws_region   = "us-east-1"

project_name = "devops-ec2"
environment  = "dev"

instance_type = "t2.micro"



vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# Prefer YOUR_PUBLIC_IP/32 rather than 0.0.0.0/0
ssh_allowed_cidr = "0.0.0.0/0"