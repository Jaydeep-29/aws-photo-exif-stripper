
import os
import boto3
from PIL import Image
from io import BytesIO

s3 = boto3.client('s3')
dest_bucket = os.environ.get('DEST_BUCKET')

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    if not key.lower().endswith(".jpg"):
        return

    response = s3.get_object(Bucket=bucket, Key=key)
    img_bytes = response['Body'].read()

    img = Image.open(BytesIO(img_bytes))
    output = BytesIO()
    img.convert('RGB').save(output, format='JPEG', quality=95)
    output.seek(0)

    s3.put_object(Bucket=dest_bucket, Key=key, Body=output)
