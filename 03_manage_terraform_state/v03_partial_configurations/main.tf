provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    key = "global/s3/terraform.tfstate"
  }
}