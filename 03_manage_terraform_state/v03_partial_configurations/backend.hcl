# backend.hcl
bucket = "tf-up-and-running-state-20191009"
region = "us-east-2"
dynamodb_table = "tf-up-and-running-locks"
encrypt = true