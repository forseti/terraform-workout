#### v01_initial ####

Define a provider in `main.tf`. The syntax:
```hcl
provider "<PROVIDER>" {
	[<CONFIG> ...]
}
```

```hcl
provider "aws" {
	region = "us-east-2"
}
```

Define a resource in `main.tf`. The syntax:
```hcl
resource "<PROVIDER>_<TYPE>" "<NAME>" {
	[<CONFIG> ...]
}
```

```hcl
resource "aws_instance" "example-instance" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
}

```