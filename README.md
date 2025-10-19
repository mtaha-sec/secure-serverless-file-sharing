# Secure Serverless File Sharing (AWS)

**Author:** Mohamed Taha Aboumehdi Hassani  

This is a **secure serverless file sharing application** built on AWS with a focus on **security best practices**.  

---

##  Built With

- **AWS S3** – Encrypted storage using KMS  
- **AWS Lambda** – Serverless backend  
- **API Gateway** – HTTP API endpoints  
- **Amazon Cognito** – JWT authentication & user management  

---

## AWS Resources

| Resource | Value |
|----------|-------|
| S3 Bucket | `serverless-file-sharing-1e014312` |
| Lambda Function | `serverless-file-sharing-lambda` |
| API Endpoint | `https://c6j1000nq9.execute-api.us-east-1.amazonaws.com` |
| Cognito User Pool | `us-east-1_D4nqY2wmo` |
| Cognito Client ID | `79stru2utq2fvrq38hlh84omnn` |

---

##  HTTP Methods

| Method | Action |
|--------|--------|
| **PUT**    | Upload a file (requires JWT token) |
| **GET**    | Generate a pre-signed URL for download |
| **DELETE** | Delete a file (requires JWT token) |

---

##  Usage

### 1. Authenticate
Get an IdToken from Cognito:

```bash
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id <COGNITO_CLIENT_ID> \
  --auth-parameters USERNAME=<your-username>,PASSWORD=<your-password> \
  --query "AuthenticationResult.IdToken" \
  --output text
