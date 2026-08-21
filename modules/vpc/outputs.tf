output "vpc_id" {
  description = "ID della VPC creata"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "ID delle subnet pubbliche"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "ID delle subnet private"
  value       = aws_subnet.private[*].id
}

output "db_subnet_group_name" {
  description = "Nome del DB Subnet Group per RDS"
  value       = aws_db_subnet_group.main.name
}