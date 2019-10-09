#### v03_deploy_web_server ####
Add the web server using `user_data` to our EC2 instance, `example`:
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
resource "aws_instance" "example" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"

	user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
	
	tags = {
		Name = "example-inst"
	}
}
```

Create a *security group* to allow inbound traffic *8080*
```hcl
resource "aws_security_group" "inst" {
  name = "sg-for-ec2-inst"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

Next, use *resource attribute reference* so that our EC2 instance, `example`, can refer to our *security group* resource. The syntax:
```hcl
<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>
```

After the edit:
```hcl
resource "aws_instance" "example" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"

	vpc_security_group_ids = [aws_security_group.inst.id]

	user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
	
	tags = {
		Name = "example-ec2-inst"
	}
}
```

To test the web server, use `curl` command:
```console
curl http://<EC2_INSTANCE_PUBLIC_IP>:8080
```