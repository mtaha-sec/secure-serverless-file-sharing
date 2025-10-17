# -----------------------------
# S3 Buckets (Logs, App, Backups)
# -----------------------------

# Random suffix for unique bucket names
resource "random_id" "suffix" {
  byte_length = 4
}

# 1️⃣ Logs Bucket
resource "aws_s3_bucket" "logs_bucket" {
  bucket = "secure-logs-bucket-${random_id.suffix.hex}"

  tags = {
    Name      = "secure-logs-bucket"
    Purpose   = "Centralized logging"
    ManagedBy = "Terraform"
  }
}

# 2️⃣ Application Data Bucket
resource "aws_s3_bucket" "app_data_bucket" {
  bucket = "secure-app-data-bucket-${random_id.suffix.hex}"

  tags = {
    Name      = "secure-app-data-bucket"
    Purpose   = "Application data storage"
    ManagedBy = "Terraform"
  }
}

# 3️⃣ Backup Bucket
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "secure-backup-bucket-${random_id.suffix.hex}"

  tags = {
    Name      = "secure-backup-bucket"
    Purpose   = "Data backups"
    ManagedBy = "Terraform"
  }
}

# -----------------------------
# Block Public Access
# -----------------------------
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app_data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "backup" {
  bucket = aws_s3_bucket.backup_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------
# Enable Versioning
# -----------------------------
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = {
    logs   = aws_s3_bucket.logs_bucket.id
    app    = aws_s3_bucket.app_data_bucket.id
    backup = aws_s3_bucket.backup_bucket.id
  }

  bucket = each.value

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------
# Server-Side Encryption (SSE-KMS)
# -----------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  for_each = {
    logs   = aws_s3_bucket.logs_bucket.id
    app    = aws_s3_bucket.app_data_bucket.id
    backup = aws_s3_bucket.backup_bucket.id
  }

  bucket = each.value

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/aws/s3" # AWS-managed key
    }
  }
}

# -----------------------------
# S3 Access Logging
# -----------------------------
resource "aws_s3_bucket_logging" "logging" {
  for_each = {
    app    = aws_s3_bucket.app_data_bucket.id
    backup = aws_s3_bucket.backup_bucket.id
  }

  bucket        = each.value
  target_bucket = aws_s3_bucket.logs_bucket.id
  target_prefix = "${each.key}-access-logs/"
}

# -----------------------------
# Logs Bucket Policy for CloudTrail
# -----------------------------
resource "aws_s3_bucket_policy" "logs_policy" {
  bucket = aws_s3_bucket.logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudTrailWrite"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# -----------------------------
# Optional: CloudTrail to deliver logs
# -----------------------------
resource "aws_cloudtrail" "main_trail" {
  name                          = "secure-trail"
  s3_bucket_name                = aws_s3_bucket.logs_bucket.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}

