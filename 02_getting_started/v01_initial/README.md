#### v01_initial ####

This is an initial project. We will learn to use `provider` and `resource`.

##### Provider #####
To initialize the provider for a project, use the following syntax:
```hcl
provider "<PROVIDER>" {
	[<CONFIG> ...]
}
```

Define an `aws` provider in `main.tf`:
```hcl
provider "aws" {
	region = "us-east-2"
}
```

##### Resource #####
The define a resource, use the following syntax:
```hcl
resource "<PROVIDER>_<TYPE>" "<NAME>" {
	[<CONFIG> ...]
}
```

Define an `aws_instance` resource in `main.tf`:
```hcl
resource "aws_instance" "example-i" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
}

```