import os
import boto3
from urllib.parse import unquote_plus

s3 = boto3.client('s3')
BUCKET = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    method = event['requestContext']['http']['method']
    key = unquote_plus(event['rawPath'].lstrip('/'))

    if method == 'PUT':
        body = event['body']
        s3.put_object(Bucket=BUCKET, Key=key, Body=body)
        return {"statusCode": 200, "body": "File uploaded successfully."}

    elif method == 'GET':
        url = s3.generate_presigned_url('get_object', Params={'Bucket': BUCKET, 'Key': key}, ExpiresIn=3600)
        return {"statusCode": 200, "body": url}

    elif method == 'DELETE':
        s3.delete_object(Bucket=BUCKET, Key=key)
        return {"statusCode": 200, "body": "File deleted successfully."}

    return {"statusCode": 400, "body": "Unsupported method"}
