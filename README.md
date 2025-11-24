# Secure Serverless File Sharing (AWS)

**Author:** Mohamed Taha Aboumehdi Hassani  

A **secure serverless file sharing application** built entirely on AWS, designed with **security best practices** in mind. This project demonstrates how to build a **fully serverless, encrypted, and authenticated file storage solution**.

---

## Built With

- **AWS S3** – Encrypted storage with **AWS KMS (Key Management Service)** for **server-side encryption**, ensuring that all files are encrypted at rest.  
- **AWS Lambda** – Serverless backend for handling file uploads, downloads, and deletions.  
- **API Gateway (HTTP API)** – Secure, RESTful API endpoints for client communication.  
- **Amazon Cognito** – JWT authentication and user management, protecting API access.  
- **Terraform** – Infrastructure-as-Code for automated, reproducible deployment.  

---

## AWS Resources

| Resource | Value | Notes |
|----------|-------|-------|
| **S3 Bucket** | `serverless-file-sharing-1e014312` | **Server-side encrypted with KMS**, automatically managed by Lambda |
| **Lambda Function** | `serverless-file-sharing-lambda` | Minimal IAM permissions (least privilege) |
| **API Endpoint** | `https://c6j1000nq9.execute-api.us-east-1.amazonaws.com` | Protected by Cognito JWT Authorizer |
| **Cognito User Pool** | `us-east-1_D4nqY2wmo` | Manages users and authentication |
| **Cognito Client ID** | `79stru2utq2fvrq38hlh84omnn` | Used for authenticating clients via JWT |

---

## HTTP Methods & Actions

| Method | Description | Security |
|--------|------------|----------|
| **PUT**    | Upload a file to S3 | Requires a valid **Cognito JWT token** |
| **GET**    | Generate a **pre-signed URL** for file download | Requires JWT token (optional: can be public if configured) |
| **DELETE** | Delete a file from S3 | Requires a valid JWT token |

> **Security Highlights:**  
> - All files are **encrypted at rest** using **KMS-managed keys**.  
> - **Lambda functions** follow the **least privilege principle**, only accessing the specific S3 bucket and KMS key.  
> - **API Gateway** routes are protected by **Cognito JWT authorizer**.  
> - Serverless architecture reduces exposure and attack surface.  

---

## Usage

### 1. Authenticate & Retrieve JWT Token & HTTP Methods

```bash
#this command returns an IdToken, which you will use to authorize API requests.
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id <COGNITO_CLIENT_ID> \
  --auth-parameters USERNAME=<your-username>,PASSWORD=<your-password> \
  --query "AuthenticationResult.IdToken" \
  --output text


# Secure Serverless File Sharing - API Commands

# Upload a File (PUT)
	curl -X PUT "https://c6j1000nq9.execute-api.us-east-1.amazonaws.com/test.txt" \
	-H "Authorization: Bearer <IdToken>" \
	--data-binary "@testfile.txt"

# Response:
 {"message":"File uploaded successfully."}

# Download a File (GET)
	curl -X GET "https://c6j1000nq9.execute-api.us-east-1.amazonaws.com/test.txt" \
	-H "Authorization: Bearer <IdToken>" \
	-o "downloaded_test.txt"

# Notes:
 - Files remain encrypted at rest in S3 until downloaded.

# Delete a File (DELETE)
	curl -X DELETE "https://c6j1000nq9.execute-api.us-east-1.amazonaws.com/test.txt" \
	-H "Authorization: Bearer <IdToken>"

# Notes:
 - Only authenticated users with a valid JWT token can delete files. 
