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

resource "aws_security_group" "example-lb-sg" {
  name = "terraform-example-lb-sg"

  # Allow inbound HTTP requests
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example-lb" {
  name = "terraform-example-lb"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.subnet-d.ids
  security_groups = [aws_security_group.example-lb-sg.id]
}

resource "aws_lb_listener" "example-lb-l" {
  load_balancer_arn = aws_lb.example-lb.arn
  port = 80
  protocol = "HTTP"

  # Return 404 page, by default
  default_action {
    type = "fixed-response"

    fixed_response {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code = 404
    }
  }
}

resource "aws_lb_target_group" "example-lb-tg" {
  name = "terraform-example-lb-tg"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.vpc-d.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_group" "example-asg" {
  launch_configuration = aws_launch_configuration.example-lc.name
  vpc_zone_identifier = data.aws_subnet_ids.subnet-d.ids

  target_group_arns = [aws_lb_target_group.example-lb-tg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-example-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb_listener_rule" "example-lb-lr" {
  listener_arn = aws_lb_listener.example-lb-l.arn
  priority = 100

  condition {
    field = "path-pattern"
    values = ["*"]
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.example-lb-tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.example-lb.dns_name
  description = "The domain name of the load balancer"
}