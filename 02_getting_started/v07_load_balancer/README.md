#### v07_load_balancer ####

We will learn to use *Elastic Load Balancer (ELB)*

There are three types:

| Type | Description |
|---|---|
| Application Load Balancer (ALB)<img width="150px"/> | <ul><li>Best suited for load balancing HTTP/HTTPS traffic.</li><li>Operates at application layer (Layer 7)</li></ul> |
| Network Load Balancer (NLB) | <ul><li>Best suited for load balancing TCP, UDP, TLS traffic.</li><li>Can scale up/down in response to load faster than ALB (scalable to tens of millions of requests per second).</li><li>Operate at transport layer (Layer 4)</li>|
| Classic Load Balancer (CLB) | <ul><li>The 'legacy' load balancer that predates both ALB and NLB.</li><li>It can handle HTTP/HTTPS, TCP, and TLS traffic.</li><li>It has less features than either ALB or NLB.</li><li>Operates at both application layer (Layer 7) and transport layer (Layer 4)</li> |

These days, applications should use either ALB or NLB. And since we are managing a web server, it is best to use ALB.

ALB has several parts.

| Property | Description |
|---|---|
| Listener<img width="250px"/> | Listens on specific port (e.g. 80) and protocol (e.g. HTTP). |
| Listener rule | Takes requests that come into a listener and sends those that match specific paths (e.g. /foo/bar) or hostnames (e.g. foo.bar.com) to specific target groups. |
| Target groups | One or more servers that receive requests from the load balancer. It also performs health checks on these servers and only sends requests to healthy nodes. |

Start by creating the ALB using `aws_lb` resource:
```hcl
resource "aws_lb" "example" {
  name = "alb-for-example-ec2-inst"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
}
```

Next, create an HTTP listener for ALB using `aws_lb_listener`:
```hcl
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
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
```

By default, all AWS resources, including ALBs, don't allow any inbound/outbound traffic. So we need to create a new security group for our ALB:
```hcl
resource "aws_security_group" "alb" {
  name = "sg-for-alb"

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
``` 

Then, we want to add the new *security group* to our ALB:
```hcl
resource "aws_lb" "example" {
  name = "alb-for-example-ec2-inst"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}
```

Next is to create a target group for our *auto scaling group*, using `aws_alb_target_group`:
```hcl
resource "aws_lb_target_group" "asg" {
  name = "tg-for-asg"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

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
```

Add the target group to our *auto scaling group*. By default, `health_check_type` is `EC2`, and we want to set it to `ELB`:
```hcl
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "asg-for-example-ec2-inst"
    propagate_at_launch = true
  }
}
```

Finally, create a listener rule using `aws_lb_listener_rule`:
```hcl
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    field = "path-pattern"
    values = ["*"]
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
```

We can add an `output` variable to show DNS of our ALB:
```hcl
output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}
```