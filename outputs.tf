output "node1_public_ip" {
  description = "IP publica del proxy (usarla en las validaciones curl)"
  value       = aws_instance.node1_proxy.public_ip
}

output "node2_public_ip" {
  description = "IP publica de Node 2 (para probar que sg-services bloquea acceso directo)"
  value       = aws_instance.node2_reservas.public_ip
}

output "vpc_id" {
  value = aws_vpc.lab.id
}

output "instance_ids" {
  value = {
    node1_proxy      = aws_instance.node1_proxy.id
    node2_reservas   = aws_instance.node2_reservas.id
    node3_pasajeros  = aws_instance.node3_pasajeros.id
    node4_database   = aws_instance.node4_database.id
  }
}
