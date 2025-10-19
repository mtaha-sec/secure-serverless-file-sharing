# =====================================================
# Project: Secure Serverless File Sharing (AWS)
# =====================================================
# Author: Mohamed Taha Aboumehdi Hassani
# 
# Hey there! This is my secure serverless file sharing project.
# I built it using AWS services, focusing on security and simplicity.
# Here's what I used:
#   - AWS S3: for storing files, all encrypted with KMS
#   - AWS Lambda: handles the backend logic without servers
#   - API Gateway: provides HTTP endpoints for interacting with files
#   - Amazon Cognito: manages users and authentication with JWT tokens
# 
# Security was my top priority, so everything is protected and follows best practices.
# =====================================================

# ---------------------------
# AWS Resources
# ---------------------------
S3_BUCKET        = serverless-file-sharing-1e014312
LAMBDA_FUNCTION  = serverless-file-sharing-lambda
API_ENDPOINT     = https://c6j1000nq9.execute-api.us-east-1.amazonaws.com
COGNITO_POOL_ID  = us-east-1_D4nqY2wmo
COGNITO_CLIENT_ID= 79stru2utq2fvrq38hlh84omnn

# ---------------------------
# HTTP Methods You Can Use
# ---------------------------
# PUT    -> Upload a file to S3 (needs a Cognito JWT token)
# GET    -> Get a download link for a file
# DELETE -> Remove a file from S3 (also needs JWT token)

# ---------------------------
# How to Use
# ---------------------------
# 1. Get an IdToken from Cognito:
#    aws cognito-idp initiate-auth \
#        --auth-flow USER_PASSWORD_AUTH \
#        --client-id $(COGNITO_CLIENT_ID) \
#        --auth-parameters USERNAME=<your-username>,PASSWORD=<your-password> \
#        --query "AuthenticationResult.IdToken" \
#        --output text
#
# 2. Upload a file (PUT):
#    curl -X PUT "$(API_ENDPOINT)/<filename>" \
#        -H "Authorization: Bearer <IdToken>" \
#        --data-binary "@<localfile>"
#
# 3. Download a file (GET):
#    curl -X GET "$(API_ENDPOINT)/<filename>" \
#        -H "Authorization: Bearer <IdToken>"
#
# 4. Delete a file (DELETE):
#    curl -X DELETE "$(API_ENDPOINT)/<filename>" \
#        -H "Authorization: Bearer <IdToken>"

# ---------------------------
# Why This Project is Secure
# ---------------------------
# 1. API access is protected with Cognito JWT tokens
# 2. All files in S3 are encrypted using AWS KMS
# 3. Lambda has only the permissions it needs (least privilege)
# 4. API Gateway routes are protected by Cognito authorizer
# 5. Serverless design reduces the attack surface

# ---------------------------
# Example
# ---------------------------
# Uploading a file is simple:
#    curl -X PUT "$(API_ENDPOINT)/test.txt" \
#        -H "Authorization: Bearer <IdToken>" \
#        --data-binary "@testfile.txt"
#
# And you'll get a response like:
#    {"message":"File uploaded successfully."}
