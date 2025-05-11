output "public_ip" {
  value       = aws_instance.ngnix-server.public_ip
  description = "Public IP"
}

output "dni_ip" {
  value       = aws_instance.ngnix-server.public_dns
  description = "Public DNS"
}
