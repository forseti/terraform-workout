#### v06_auto_scaling_and_load_balancer ####

We will learn to use *Auto Scaling Group* and *Elastic Load Balancer*

Replace our `aws_instance` resource with the following `aws_launch_configuration`:
```hcl
resource "aws_launch_configuration" "example-lc" {
  image_id = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.example-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
}
```

Also remove the `output` variable.

Next is to create the `aws_autoscaling_group`:
```hcl
resource "aws_autoscaling_group" "example-asg" {
  launch configuration = aws_launch_configuration.example-lc.name

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}
```

##### Data Sources #####
Before we can run our *auto scaling group*, we need to define its `subnet_ids`. We can hardcode a list of subnets, but that would not be portable and maintainable. The best option is to use *data sources*.

The syntax is similar to a `resource`:
```hcl
data "<PROVIDER>_<TYPE>" "<NAME>" {
  [<CONFIG> ...]
}
```

To define our *Default VPC* as a *data source*:
```hcl
data "aws_vpc" "vpc-d" {
  default = true
}
```

To reference our *data source*:
```hcl
data.<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>
```

In our case, to get the `id` of our *Default VPC*:
```hcl
data.aws_vpc.vpc-d.id
```

Next, to get the our subnet IDs, we can use `aws_subnet_ids`:
```hcl
data "aws_subnet_ids" "subnet-d" {
  vpc_id = data.aws_vpc.vpc-d.id
}
```

And finally assign our subnet IDs to `vpc_zone_identifier` in our `aws_autoscaling_group`:
```hcl
resource "aws_autoscaling_group" "example-asg" {
  launch configuration = aws_launch_configuration.example-lc.name
  vpc_zone_identifier = data.aws_subnet_ids.subnet-d.ids

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}
```