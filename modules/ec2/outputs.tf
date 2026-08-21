output "public_ip" {
  description = "Indirizzo IP pubblico dell'istanza"
  value       = aws_instance.mio_primo_server.public_ip
}

output "security_group_id" {
  description = "ID del security group web"
  value       = aws_security_group.web_sg.id
}