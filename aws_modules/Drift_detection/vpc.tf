resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name        = each.key
      Environment = var.environment
      Network     = "public"
      ManagedBy   = "Terraform"
    }
  )

  lifecycle {
    precondition {
      condition     = contains(var.availability_zones, each.value.availability_zone)
      error_message = "The subnet Availability Zone must be included in var.availability_zones."
    }
  }
}


resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name        = each.key
      Environment = var.environment
      Network     = "private"
      ManagedBy   = "Terraform"
    }
  )

  lifecycle {
    precondition {
      condition     = contains(var.availability_zones, each.value.availability_zone)
      error_message = "The subnet Availability Zone must be included in var.availability_zones."
    }
  }
}


# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-public-rt"
      Environment = var.environment
      Network     = "public"
      ManagedBy   = "Terraform"
    }
  )

  lifecycle {
    precondition {
      condition     = length(var.public_subnets) > 0
      error_message = "At least one public subnet must be configured."
    }
  }
}

# Default route to the Internet Gateway
resource "aws_route" "public_default_ipv4" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate every public subnet with the public route table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-igw"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}


resource "aws_eip" "nat" {
  for_each = var.nat_gateways

  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name             = "${var.project_name}-${var.environment}-nat-eip-${each.key}"
      Environment      = var.environment
      Network          = "public"
      AvailabilityZone = each.value.availability_zone
      ManagedBy        = "Terraform"
    }
  )

  depends_on = [
    aws_internet_gateway.main
  ]
}

resource "aws_nat_gateway" "main" {
  for_each = var.nat_gateways

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value.public_subnet_key].id

  connectivity_type = "public"

  tags = merge(
    var.common_tags,
    {
      Name             = "${var.project_name}-${var.environment}-nat-${each.key}"
      Environment      = var.environment
      Network          = "egress"
      AvailabilityZone = each.value.availability_zone
      ManagedBy        = "Terraform"
    }
  )

  depends_on = [
    aws_internet_gateway.main
  ]

  lifecycle {
    precondition {
      condition = (
        aws_subnet.public[each.value.public_subnet_key].availability_zone ==
        each.value.availability_zone
      )
      error_message = "Each NAT Gateway must be deployed in its configured public subnet Availability Zone."
    }
  }
}


