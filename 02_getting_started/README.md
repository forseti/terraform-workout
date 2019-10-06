### 02_getting_started ###
There are several versions here to track the learning progress.

#### v01_setup ####
Set the environment variables:
```console
export AWS_ACCESS_KEY_ID=<YOUR_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<YOUR_SECRET_ACCESS_KEY>
```

Define a provider in `main.tf`. The syntax:
```hcl
provider <PROVIDER> {
	[<CONFIG>...]
}
```

```hcl
provider aws {
	region = "us-east-2"
}
```

Define a resource in `main.tf`. The syntax:
```hcl
resource <PROVIDER>_<TYPE> <NAME> {
	[<CONFIG>...]
}
```

```hcl
resource "aws_instance" "example" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
}

```

Initialize this Terraform project. The syntax:
```console
terraform init
terraform init <DIR_OR_PLAN>
```

```console
terraform init v01
```

Run the preview. The syntax:
```console
terraform plan
terraform plan <DIR_OR_PLAN>
```

```console
terraform plan v01
```

Apply the changes:
```console
terraform apply
terraform apply <DIR_OR_PLAN>
```

```console
terraform apply v01
```

#### v02_add_tag ####
Add the tag to our EC2 instance
```hcl
resource "aws_instance" "example" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
	tags = {
		Name = "terraform-example"
	}
}
```