provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "tf-up-and-running-state-20191009"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "tf-up-and-running-locks"
    encrypt = true
  }
}