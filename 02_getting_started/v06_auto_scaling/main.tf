provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "The port to be used for HTTP requests"
  type = number
  default = 8080
}

resource "aws_security_group" "example-sg" {
  name = "terraform-example-sg"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
resource "aws_instance" "example-i" {
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

output "public_ip" {
  value = aws_instance.example-i.public_ip
  description = "The public IP address of the web server"
}
*/

resource "aws_launch_configuration" "example-lc" {
  image_id = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.example-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  
  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle { 
    create_before_destroy = true 
  }
}

data "aws_vpc" "vpc-d" {
  default = true
}

data "aws_subnet_ids" "subnet-d" {
  vpc_id = data.aws_vpc.vpc-d.id
}

resource "aws_autoscaling_group" "example-asg" {
  launch_configuration = aws_launch_configuration.example-lc.name
  vpc_zone_identifier = data.aws_subnet_ids.subnet-d.ids

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}