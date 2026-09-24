variable "aws_region" {
  description = "Región de AWS donde se despliega el laboratorio"
  type        = string
  default     = "us-east-1"
}

variable "project_tag" {
  description = "Valor del tag Project usado para identificar todos los recursos del laboratorio"
  type        = string
  default     = "lab-3tier-uni"
}

variable "key_pair_name" {
  description = "Nombre del key pair EC2 ya existente en tu cuenta (el mismo del Laboratorio 1)"
  type        = string
  default     = "kp-laboratorio"
}

variable "db_password" {
  description = "Password de PostgreSQL (labuser). En producción usa una variable sensible / Secrets Manager."
  type        = string
  default     = "LabPass2024!"
  sensitive   = true
}

variable "instance_type" {
  description = "Tipo de instancia EC2 para los 4 nodos"
  type        = string
  default     = "t3.micro"
}
