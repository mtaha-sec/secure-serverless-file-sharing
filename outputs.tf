# S3 Bucket Name
output "s3_bucket_name" {
  description = "Name of the S3 bucket storing files"
  value       = aws_s3_bucket.files_bucket.bucket
}

# Cognito User Pool ID
output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.user_pool.id
}

# Cognito User Pool Client ID
output "cognito_client_id" {
  description = "Client ID for the Cognito User Pool"
  value       = aws_cognito_user_pool_client.user_pool_client.id
}

# API Gateway Endpoint
output "api_endpoint" {
  description = "HTTP API endpoint for Lambda function"
  value       = aws_apigatewayv2_api.api.api_endpoint
}
