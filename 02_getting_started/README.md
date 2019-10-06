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
provider "<PROVIDER>" {
	[<CONFIG>...]
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
	[<CONFIG>...]
}
```

```hcl
resource "aws_instance" "example-instance" {
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
terraform init v01_setup
```

Run the preview. The syntax:
```console
terraform plan
terraform plan <DIR_OR_PLAN>
```

```console
terraform plan v01_setup
```

Apply the changes:
```console
terraform apply
terraform apply <DIR_OR_PLAN>
```

```console
terraform apply v01_setup
```

#### v02_add_tag ####
Add the tag to our EC2 instance:
```hcl
resource "aws_instance" "example-instance" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
	
	tags = {
		Name = "terraform-example-instance"
	}
}
```

And apply the changes using `terraform apply`.

#### v03_deploy_web_server ####
Add the web server using `user_data` to our EC2 instance, `example-instance`:
```
user_data = <<-EOF
            #!/bin/bash
            echo "Hello World" > index.html
            nohup busybox httpd -f -p 8080 &
            EOF
```
`<<-EOF` and `EOF` are Terraform's `heredoc` syntax, which allow multiline strings.

After the edit:
```hcl
resource "aws_instance" "example-instance" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"

	user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
	
	tags = {
		Name = "terraform-example-instance"
	}
}
```

Create a *security group* to allow inbound traffic *8080*
```hcl
resource "aws_security_group" "example-sg" {
  name = "terraform-example-sg"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

Next, use *resource attribute reference* so that our EC2 instance, `example-instance`, can refer to our *security group* resource. The syntax:
```hcl
<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>
```

After the edit:
```hcl
resource "aws_instance" "example-instance" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"

	vpc_security_group_ids = [aws_security_group.example-sg.id]

	user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
	
	tags = {
		Name = "terraform-example-instance"
	}
}
```

To display the graph in *DOT* format:
```console
terraform graph
terraform graph <DIR_OR_PLAN>
```

```console
terraform graph v03_deploy_web_server
```

An output's example:
```console
digraph {
        compound = "true"
        newrank = "true"
        subgraph "root" {
                "[root] aws_instance.example-instance" [label = "aws_instance.example-instance", shape = "box"]
                "[root] aws_security_group.example-sg" [label = "aws_security_group.example-sg", shape = "box"]
                "[root] provider.aws" [label = "provider.aws", shape = "diamond"]
                "[root] aws_instance.example-instance" -> "[root] aws_security_group.example-sg"
                "[root] aws_security_group.example-sg" -> "[root] provider.aws"
                "[root] meta.count-boundary (EachMode fixup)" -> "[root] aws_instance.example-instance"
                "[root] provider.aws (close)" -> "[root] aws_instance.example-instance"
                "[root] root" -> "[root] meta.count-boundary (EachMode fixup)"
                "[root] root" -> "[root] provider.aws (close)"
        }
}
```

The `digraph` value can be visualized in an online tool like [GraphvizOnline](http://dreampuf.github.io/GraphvizOnline/)

To test the web server, use `curl` command:
```console
curl http://<EC2_INSTANCE_PUBLIC_IP>:8080
```

#### v04_network_security ####
For production systems, deploy all servers and data stores in *private subnets*. In *public subnets*, deploy only a handful of reverse proxies and load balancers.

#### v05_deploy_configurable_web_servers ####
To define a variable, use the following syntax:
```hcl
variable "<NAME>" {
	[<CONFIG> ...]
}
```

The body of the `variable` declaration (`<CONFIG`) has three parameters:

| Parameter | Description |
|---------- |-|
| *description*    | A description on how a variable is used |
| *type* | The *type constraints* of a variable |
| *default* | There are two ways to provide a value for a variable, `-var`, `-var-file`, and an environment variable `TF_FAR_<VARIABLE_NAME>`. If no value is passed in, the variable will fall back to this default value | 

An example of a number:
```hcl
variable "number_example" {
	description = "An example of a number"
	type = number
	default = 123
}

```

An example of a list:
```hcl
variable "list_example" {
	description = "An example of a list"
	type = list
	default = ['one', 'two', 'three']
}
```

An example of a list of numerics:
```hcl
variable "list_numeric_example" {
	description = "An example of a list of numerics"
	type = list(number)
	default = [1, 2, 3]
}
```

An example of a map:
```hcl
variable "map_example" {
	description = "An example of a map"
	type = map(string)
	default = {
		key1 = "value1"
		key2 = "value2"
		key3 = "value3"
	}
}
```

An example of an object:
```hcl
variable "object_example" {
	description = "An example of an object"
	type = object({
		name = string
		age = number
		tags = list(string)
		enabled = bool
	})
	default = {
		name = "object_1"
		age = 1
		tags = ["o", "n", "e"]
		enabled = true
	}
}
```

Define a variable `server_port` for our `main.tf`:
```hcl
variable "server_port" {
	description = "The port to be used for HTTP requests"
	type = number
}
```

Because there is no `default` value, running `terraform apply` will prompt you to enter a value.

One way is to provide a value is to use `-var`:
```console
terraform plan -var "server_port=8080"
```
And another way is to use an environment variable `TF_VAR_<VARIABLE_NAME>`:
```console
export TF_VAR_server_port=8080
terraform plan
``` 

To avoid using CLI arguments everytime running `terraform apply` or `terraform plan`, specify a `default` value:
```console
variable "server_port" {
	description = "The port to be used for HTTP requests"
	type = number
	default = 8080
}
```

To use the value from an input variable, use *variable reference*

```hcl
var.<VARIABLE_NAME>
```

Apply the variable to `from_port` and `to_port` in our *security group*, `example-sg`
```hcl
resource "aws_security_group" "example-sg" {
  name = "terraform-example-sg"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

To apply the same variable in *User Data* script, use interpolation `${...}`, the syntax:
```hcl
${VARIABLE_NAME}
```

```hcl
resource "aws_instance" "example-instance" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.example-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  tags = {
    Name = "terraform-example-instance"
  }
}
```

We can also define an `output` variable:
```hcl
output "<NAME>" {
	value = <VALUE>
	[<CONFIG> ...]
}
```

The body of the `output` declaration (`<CONFIG`) has two parameters:

| Parameter | Description |
|---------- |-|
| *description*    | A description of the type of the output |
| *sensitive* | If this parameter is set to true, Terraform will not log this output |

Add the `output` to our `main.tf`:
```hcl
output "public_ip" {
	value = aws_instance.example-instance.public_ip
	description = "The public IP address of the web server"
}
```

Run `terraform apply` to apply changes.

We can also use the following command to display the `output`
```console
terraform output
terraform output <OUTPUT_NAME>
```

```console
terraform output public_ip
```