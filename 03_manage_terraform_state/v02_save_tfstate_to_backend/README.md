#### v02_save_tfstate_to_backend ####
To configure Terraform to store the state in the S3 bucket, we need to define the `backend` configuration in the `terraform` block:
```hcl
terraform {
	backend "<BACKEND_NAME>" {
		[<CONFIG> ...]
	}
}
```

In our case:
```hcl
terraform {
	backend "s3" {
		bucket = "tf-up-and-running-state-20191009"
		key = "global/s3/terraform.tfstate"
		region = "us-east-2"

		dynamodb_table = "tf-up-and-running-locks"
		encrypt = true
	}
}
```

Then run `terraform init` and `terraform apply` to instruct Terraform to store the state file in S3 bucket.