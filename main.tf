# --------- VPC ---------
resource "aws_vpc" "secure_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "secure-vpc"
  }
}

# --------- Public Subnets ---------
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.secure_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = element(["eu-north-1a", "eu-north-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index+1}"
  }
}

# --------- Private Subnets ---------
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.secure_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(["eu-north-1a", "eu-north-1b"], count.index)

  tags = {
    Name = "private-subnet-${count.index+1}"
  }
}

# --------- Internet Gateway ---------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.secure_vpc.id

  tags = {
    Name = "secure-igw"
  }
}

# --------- NAT Gateway ---------
# Allocate Elastic IP
resource "aws_eip" "nat_eip" {
  count = length(var.public_subnet_cidrs)
}

# NAT Gateways for each public subnet
resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-gateway-${count.index+1}"
  }
}

# --------- Route Tables ---------

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.secure_vpc.id

  # Route all internet-bound traffic through the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Private Route Tables (one per private subnet)
resource "aws_route_table" "private_rt" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.secure_vpc.id

  # Route all outbound traffic through NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "private-route-table-${count.index + 1}"
  }
}

# --------- Route Table Associations ---------

# Link each Public Subnet to the Public Route Table
resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Link each Private Subnet to its corresponding Private Route Table
resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# -----------------------------
# EC2 IAM Role
# -----------------------------
resource "aws_iam_role" "ec2_role" {
  name = var.ec2_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = var.ec2_role_name
  }
}

# -----------------------------
# Attach Policies to Role
# -----------------------------
resource "aws_iam_role_policy_attachment" "ec2_role_policies" {
  for_each = toset(var.ec2_role_policies)

  role       = aws_iam_role.ec2_role.name
  policy_arn = each.key
}

# -----------------------------
# Instance Profile (for EC2)
# -----------------------------
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.ec2_role_name}-profile"
  role = aws_iam_role.ec2_role.name
}

# -----------------------------
# Lambda IAM Role
# -----------------------------
resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  # This defines *who can assume this role*
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"   # Lambda service will assume this role
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = var.lambda_role_name
  }
}
# Attach Managed Policies
resource "aws_iam_role_policy_attachment" "lambda_role_policies" {
  for_each = toset(var.lambda_role_policies)
  role       = aws_iam_role.lambda_role.name
  policy_arn = each.key
}

# -----------------------------
# Custom Inline Policy for Security Actions
# -----------------------------
resource "aws_iam_role_policy" "lambda_security_policy" {
  name = "lambda-security-actions"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:UpdateLoginProfile",
          "iam:DeactivateMFADevice"
        ]
        Resource = "*"
      }
    ]
  })
}
# -----------------------------
# Logging / Security IAM Role
# -----------------------------
resource "aws_iam_role" "logging_role" {
  name = var.logging_role_name   # variable for role name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "cloudtrail.amazonaws.com",
            "config.amazonaws.com",
            "securityhub.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = var.logging_role_name
  }
}
# Attach managed policies
resource "aws_iam_role_policy_attachment" "logging_role_policies" {
  for_each = toset(var.logging_role_policies)  # list of managed policies

  role       = aws_iam_role.logging_role.name
  policy_arn = each.key
}

