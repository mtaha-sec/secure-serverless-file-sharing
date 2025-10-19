# ----------------------------
# Random ID for bucket
# ----------------------------
resource "random_id" "bucket_id" {
  byte_length = 4
}

# ----------------------------
# KMS Key for S3 encryption
# ----------------------------
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 7
}

# ----------------------------
# S3 Bucket
# ----------------------------
resource "aws_s3_bucket" "files_bucket" {
  bucket        = "serverless-file-sharing-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "files_bucket_sse" {
  bucket = aws_s3_bucket.files_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.id
    }
  }
}

# ----------------------------
# Cognito User Pool
# ----------------------------
resource "aws_cognito_user_pool" "user_pool" {
  name                     = "${var.project_name}-users"
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

# ----------------------------
# IAM Role for Lambda
# ----------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${var.project_name}-s3-access"
  description = "Lambda access to S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.files_bucket.arn}/*"
      },
      {
        Action   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
        Effect   = "Allow"
        Resource = aws_kms_key.s3_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_s3_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# ----------------------------
# Lambda Function
# ----------------------------
resource "aws_lambda_function" "file_handler" {
  function_name    = "${var.project_name}-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  filename         = "lambda/file_handler.zip"
  source_code_hash = filebase64sha256("lambda/file_handler.zip")
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.files_bucket.bucket
    }
  }
}

# ----------------------------
# API Gateway
# ----------------------------
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.file_handler.arn
  payload_format_version = "2.0"
}

# ----------------------------
# Cognito JWT Authorizer (fixed issuer)
# ----------------------------
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.api.id
  name             = "CognitoAuthorizer"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.user_pool_client.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
  }
}

# ----------------------------
# API Gateway Route (protected)
# ----------------------------
resource "aws_apigatewayv2_route" "default_route" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# ----------------------------
# API Gateway Deployment Stage
# ----------------------------
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}
