#### v04_workspaces ####

Terraform starts with a single workspace called *default*. And to create a new workspace or switch between workspaces we can use `terraform workspace` commands.

First we create a `resource` for EC2 using `aws_instance`:
```hcl
resource "aws_instance" "example" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

Then using the same `backend` setting from `v01_tfstate_with_backend`, we use a different `key` to demonstrate workspaces:
```hcl
terraform {
  backend "s3" {
    bucket = "tf-up-and-running-state-20191009"
    key = "workspaces-example/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "tf-up-and-running-locks"
    encrypt = true
  }
}
```

Run `terraform init` and `terraform apply`.

To show the current workspace, run the following command:
```console
terraform workspace show
```

The expected output:
```console
default
```

To create a new workspace called `example1`, use the following command:
```console
terraform workspace new example1
```

If we run `terraform plan`, Terraform will suggest to create a new EC2 instance. This is okay, because we are in a different workspace. Run `terraform apply`

Create another workspace `example2`:
```console
terraform workspace new example2
```

And run `terraform apply` to create the third EC2 instance.

Now, if you run the following command:
```console
terraform workspace list
```

You will see three workspaces:
```console
default
example1
*example2
```

If you want to switch to another workspace `example1`, use the following command:
```console
terraform workspace select example1
```

Using workspace, the expression `terraform.workspace` can be used to control our provisioning using *ternary syntax*:
```hcl
resource "aws_instance" "example" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = terraform.workspace == "default"? "t2.medium" : "t2.micro"
}
```