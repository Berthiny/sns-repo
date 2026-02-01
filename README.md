# Terraform S3 backend — steps and why we need it

## Why use an S3 backend
- Stores Terraform state remotely so team members share one source of truth.
- Enables state locking (with DynamoDB) to prevent concurrent writes/corruption.
- Provides durability (S3 versioning) and encryption of state.
- Allows CI/CD pipelines to run Terraform against the same state.

## Prerequisites
- AWS credentials with permissions to create S3 bucket, DynamoDB table, and manage objects.
- AWS CLI or Console access.
- Terraform installed.

## Quick steps (high level)
1. Create an S3 bucket for state.
2. Enable versioning and server-side encryption on the bucket.
3. Create a DynamoDB table for state locking (primary key: LockID).
4. Add a backend configuration to your Terraform code (backend.tf or CLI backend-config).
5. Initialize Terraform (terraform init) and migrate state if needed.

## Example commands (AWS CLI)
Replace <region>, <bucket-name>, <dynamodb-table> accordingly.

Create bucket, enable versioning and encryption:
```bash
aws s3api create-bucket --bucket my-terraform-state-bucket --region us-east-1
aws s3api put-bucket-versioning --bucket my-terraform-state-bucket --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket my-terraform-state-bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket my-terraform-state-bucket --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

Create DynamoDB table for locking:
```bash
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

## Example backend.tf
Place this in your repo (e.g., backend.tf) or pass equivalent via -backend-config:
```hcl
terraform {
    backend "s3" {
        bucket         = "my-terraform-state-bucket"
        key            = "path/to/terraform.tfstate"  # e.g., env/project/terraform.tfstate
        region         = "us-east-1"
        dynamodb_table = "terraform-state-lock"
        encrypt        = true
    }
}
```

## Initialize and migrate state
- If you already have local state and added backend.tf, run:
```bash
terraform init
# Follow prompts to migrate local state to the S3 backend
```
- Or specify backend config at init:
```bash
terraform init \
    -backend-config="bucket=my-terraform-state-bucket" \
    -backend-config="key=env/prod/terraform.tfstate" \
    -backend-config="region=us-east-1" \
    -backend-config="dynamodb_table=terraform-state-lock" \
    -backend-config="encrypt=true"
```

## Minimal IAM policy for Terraform user
Allow S3 and DynamoDB operations Terraform needs:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:GetBucketVersioning",
                "s3:PutBucketVersioning",
                "s3:GetBucketEncryption",
                "s3:PutBucketEncryption"
            ],
            "Resource": [
                "arn:aws:s3:::my-terraform-state-bucket",
                "arn:aws:s3:::my-terraform-state-bucket/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:DeleteItem",
                "dynamodb:DescribeTable",
                "dynamodb:UpdateItem"
            ],
            "Resource": "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-state-lock"
        }
    ]
}
```

## Notes / best practices
- Use a per-environment key path (e.g., env/project/terraform.tfstate).
- Enable S3 versioning so you can recover old state.
- Restrict bucket access with least privilege and block public access.
- Use MFA-protected or temporary credentials in CI where possible.

Place this README content into /Users/cameronmonthe/Desktop/workplace/general-template/README.md and update the sample names and ARNs to match your account.