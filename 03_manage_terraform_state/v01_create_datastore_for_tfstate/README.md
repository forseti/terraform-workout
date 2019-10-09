#### v01_create_datastore_for_tfstate ####

First, define AWS as a provider:
```hcl
provider "aws" {
  region = "us-east-2"
}
```

Then, create a `resource` for S3, using `aws_s3_bucket`:
```hcl
resource "aws_s3_bucket" "tf_state" {
  bucket = "tf-up-and-running-state-20191009"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }

  # Enable versioning so we can see the full revision history of our state files
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
```

There are four S3's attributes being used.

| Attribute | Description |
|---|---|
| bucket<img width="150px"/> | The name of S3 bucket. It must be globally unique among all AWS customers. |
| prevent_destroy | This flag, when is set to true, will cause Terraform to exist with an error if any delete attempt occurs. |
| versioning | Enable versioning on the S3 bucket so that every update to a file creates a new version of that file. |
| server_side_encryption_configuration | Enable server side encryption by default and ensure that state files and any secrets are encrypted on disk when stored in S3 |

Next step is to create DynamoDB table for locking:
```hcl
resource "aws_dynamodb_table" "tf_locks" {
  name = "tf-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

To see the events, we can use `output` variables:
```hcl
output "s3_bucket_arn" {
	value = aws_s3_bucket.tf_state.arn
	description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
	value = aws_dynamodb_table.tf_locks.name
	description = "The name of the DynamoDB table"
}
```