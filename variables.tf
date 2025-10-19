variable "project_name" {
  default = "serverless-file-sharing"
}

variable "lambda_runtime" {
  default = "python3.11"
}

variable "lambda_handler" {
  default = "file_handler.lambda_handler"
}
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}
