# --- PASO 6: sg-proxy → sg-services → sg-database, en ese orden de dependencia ---

resource "aws_security_group" "sg_proxy" {
  name        = "lab-3tier-sg-proxy"
  description = "Permite HTTP publico hacia el proxy nginx"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "HTTP publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "lab-3tier-sg-proxy"
    Project = var.project_tag
  }
}

resource "aws_security_group" "sg_services" {
  name        = "lab-3tier-sg-services"
  description = "Permite :8080 solo desde el proxy nginx"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description     = "8080 solo desde sg-proxy"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    security_groups  = [aws_security_group.sg_proxy.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "lab-3tier-sg-services"
    Project = var.project_tag
  }
}

resource "aws_security_group" "sg_database" {
  name        = "lab-3tier-sg-database"
  description = "Permite PostgreSQL :5432 solo desde los servicios Flask"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description     = "5432 solo desde sg-services"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = [aws_security_group.sg_services.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "lab-3tier-sg-database"
    Project = var.project_tag
  }
}
