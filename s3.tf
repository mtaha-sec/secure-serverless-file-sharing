
# App bucket (for logs, app data, etc.)
resource "aws_s3_bucket" "app_bucket" {
  bucket        = "demo-app-bucket-${random_id.bucket_id.hex}"
  
  force_destroy = true
}

# Server-side encryption for app bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket_sse" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
