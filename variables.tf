variable "aws_region" {
  default = "us-east-1"
}

variable "aws_profile" {
  default = "myproject"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

# EC2 IAM Role name
variable "ec2_role_name" {
  description = "Name of the IAM role for EC2 instances"
  type        = string
  default     = "ec2-web-role"
}

# Optional: EC2 IAM Policies to attach
variable "ec2_role_policies" {
  description = "List of managed policies to attach to the EC2 role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}
# -----------------------------
# Lambda IAM Role Variables
# -----------------------------
variable "lambda_role_name" {
  description = "Name of the IAM role for Lambda functions"
  type        = string
  default     = "lambda-security-role"
}

variable "lambda_role_policies" {
  description = "Managed policies to attach to Lambda role"
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # for CloudWatch logs
  ]
}

# Role name
variable "logging_role_name" {
  description = "Name of the IAM role for logging and security services"
  type        = string
  default     = "logging-security-role"
}

# Policies to attach
variable "logging_role_policies" {
  description = "List of managed policies for logging and security role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/SecurityHubFullAccess"
  ]
}
# -----------------------------
# EC2 Variables
# -----------------------------

variable "admin_ip" {
  description = "Your public IP to allow SSH to bastion (e.g. 102.120.x.x/32)"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID for us-east-1"
  type        = string
  default     = "ami-0c2b8ca1dad447f8a" # Ubuntu 22.04 LTS AMI for us-east-1
}

variable "key_name" {
  description = "SSH key pair name to connect to instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

