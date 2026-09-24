# --- PASO 7: Node 4 - PostgreSQL (se lanza primero, los demás dependen de su IP) ---
resource "aws_instance" "node4_database" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.az_b.id
  private_ip             = "10.0.2.50"
  vpc_security_group_ids = [aws_security_group.sg_database.id]

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user_data/node4_database.sh.tpl", {
    db_password = var.db_password
  })

  tags = {
    Name    = "lab-3tier-node4-database"
    Project = var.project_tag
  }
}

# --- PASO 8: Node 2 - servicio de reservas (AZ-b, junto a Node 4) ---
resource "aws_instance" "node2_reservas" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.az_b.id
  private_ip             = "10.0.2.10"
  vpc_security_group_ids = [aws_security_group.sg_services.id]

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user_data/node2_reservas.sh.tpl", {
    db_host     = aws_instance.node4_database.private_ip
    db_password = var.db_password
  })

  tags = {
    Name    = "lab-3tier-node2-reservas"
    Project = var.project_tag
  }

  depends_on = [aws_instance.node4_database]
}

# --- PASO 9: Node 3 - servicio de pasajeros (AZ-a, conexión cross-AZ a la DB) ---
resource "aws_instance" "node3_pasajeros" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.az_a.id
  private_ip             = "10.0.1.20"
  vpc_security_group_ids = [aws_security_group.sg_services.id]

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user_data/node3_pasajeros.sh.tpl", {
    db_host     = aws_instance.node4_database.private_ip
    db_password = var.db_password
  })

  tags = {
    Name    = "lab-3tier-node3-pasajeros"
    Project = var.project_tag
  }

  depends_on = [aws_instance.node4_database]
}

# --- PASO 10: Node 1 - proxy nginx (único con IP pública usada, referencia Node 2 y Node 3) ---
resource "aws_instance" "node1_proxy" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.az_a.id
  private_ip             = "10.0.1.10"
  vpc_security_group_ids = [aws_security_group.sg_proxy.id]

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user_data/node1_proxy.sh.tpl", {
    node2_ip = aws_instance.node2_reservas.private_ip
    node3_ip = aws_instance.node3_pasajeros.private_ip
  })

  tags = {
    Name    = "lab-3tier-node1-proxy"
    Project = var.project_tag
  }

  depends_on = [aws_instance.node2_reservas, aws_instance.node3_pasajeros]
}
