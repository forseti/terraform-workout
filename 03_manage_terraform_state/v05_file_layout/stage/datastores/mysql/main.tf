provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "tf-up-and-running-state-20191009"
    key = "stage/datastores/mysql/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "tf-up-and-running-locks"
    encrypt = true
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix = "tf-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "example_db"
  username = "admin"
  
  skip_final_snapshot = true

  password = var.db_password
}