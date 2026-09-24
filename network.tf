terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- AMI Amazon Linux 2023 más reciente (equivalente a la elegida a mano en la consola) ---
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- PASO 2: VPC personalizada ---
resource "aws_vpc" "lab" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "lab-3tier-vpc"
    Project = var.project_tag
  }
}

# --- PASO 3: dos subnets, una por AZ ---
resource "aws_subnet" "az_a" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "lab-3tier-subnet-az-a"
    Project = var.project_tag
  }
}

resource "aws_subnet" "az_b" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "lab-3tier-subnet-az-b"
    Project = var.project_tag
  }
}

# --- PASO 4: Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name    = "lab-3tier-igw"
    Project = var.project_tag
  }
}

# --- PASO 5: Route table con ruta por defecto hacia el IGW, asociada a ambas subnets ---
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "lab-3tier-rt"
    Project = var.project_tag
  }
}

resource "aws_route_table_association" "az_a" {
  subnet_id      = aws_subnet.az_a.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "az_b" {
  subnet_id      = aws_subnet.az_b.id
  route_table_id = aws_route_table.main.id
}
