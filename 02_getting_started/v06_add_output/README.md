#### v06_add_output ####
Add an `output` to our `main.tf`:
```hcl
output "public_ip" {
	value = aws_instance.example-instance.public_ip
	description = "The public IP address of the web server"
}
```