#### v02_add_tag ####
Add the tag to our EC2 instance:
```hcl
resource "aws_instance" "example" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
	
	tags = {
		Name = "example-ec2-inst"
	}
}
```