output "address" {
  value = aws_db_instance.example.address
  description = "Connect to the database at this point"
}

output "port" {
  value = aws_db_instance.example.address
  description = "The port database is listening on"
}