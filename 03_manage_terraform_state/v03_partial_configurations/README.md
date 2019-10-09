#### v02_partial_configurations ####

Currently, the S3 bucket name and DynamoDB table name are hardcoded in `backend` our Terraform main configuration (`main.tf`)

We can extract `backend` attributes into a file, for example `backend.hcl`:
```hcl
# backend.hcl
bucket = "tf-up-and-running-state-20191009"
region = "us-east-2"
dynamodb_table = "tf-up-and-running-locks"
encrypt = true
```

And we can leave the `key` in `backend` because we need different keys for our modules.
```hcl
terraform {
  backend "s3" {
    key = "global/s3/terraform.tfstate"
  }
}
```

To initialize Terraform using an external backend file, use the option `-backend-config`:
```console
terraform apply -backend-config=backend.hcl
```

Alternatively, we can also use `terragrunt` CLI.