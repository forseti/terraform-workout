#### v05_use_variables ####

In this chapter, we are going to use variables `variable` and `output`

#### Input variables (`variable`) ####
To define an input `variable`, use the following syntax:
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

##### Add an input variable to our project #####
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
And another way is to export an environment variable `TF_VAR_<VARIABLE_NAME>`:
```console
export TF_VAR_server_port=8080
``` 
Then run a command:
```console
terraform plan
```

To avoid using CLI arguments everytime running `terraform apply` or `terraform plan`, specify a `default` value:
```hcl
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

#### Output variables (`output`) ####
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

##### Add an output variable to our project #####
Add an `output` variable to our `main.tf`:
```hcl
output "public_ip" {
  value = aws_instance.example-instance.public_ip
  description = "The public IP address of the web server"
}
```