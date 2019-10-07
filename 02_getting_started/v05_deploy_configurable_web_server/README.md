#### v05_deploy_configurable_web_servers ####
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