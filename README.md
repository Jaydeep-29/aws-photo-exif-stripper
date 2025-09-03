
# AWS S3 EXIF Stripper Solution

## Overview
- Uploads to S3 Bucket A (raw photos) trigger a Lambda function.
- Lambda removes all EXIF from .jpg and saves clean copy to S3 Bucket B, preserving directory structure.
- Two IAM users: UserA (RW to A), UserB (R from B).

## How to Deploy
1. Install Terraform and AWS CLI.
2. Fill in your desired bucket names if required.
3. Run `terraform init`, `terraform apply`.
4. Package Lambda using `pip install -r requirements.txt -t .` in `lambda/` and then zip all content for deployment.


## Testing
- Upload .jpg to Bucket A.
- Confirm EXIF is stripped by downloading same-path file from Bucket B.

## Notes
- For this assessment, environment separation (e.g., dev, prod) and remote Terraform backend configuration have been omitted to keep the solution straightforward and focused on core requirements.
- In a production setting, these features would be included to support multi-environment deployments, state management, and collaboration.
