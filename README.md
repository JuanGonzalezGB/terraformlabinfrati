# Lab 3-Tier — Despliegue con Terraform

Reproduce en código exactamente la infraestructura del laboratorio manual:
VPC + 2 subnets + IGW + route table + 3 Security Groups encadenados + 4 EC2
(nginx proxy, 2 APIs Flask en Docker, PostgreSQL en Docker), con las mismas
IPs privadas fijas y los mismos scripts de arranque.

## Requisitos previos

- AWS CLI configurado con credenciales válidas (`aws configure`).
- Terraform >= 1.5.
- Un key pair EC2 ya creado en tu cuenta (por defecto `kp-laboratorio`).

## Uso

```bash
cd terraform-lab3tier
terraform init
terraform plan
terraform apply
```

Terraform lanza Node 4 primero, espera a que exista su IP privada, y luego
lanza Node 2, Node 3 y Node 1 en ese orden (mismo orden que el manual).

Al terminar, `terraform output` te da la IP pública del proxy para correr las
mismas validaciones curl del laboratorio.

## Personalizar para otro propósito (Lab 3)

Si necesitas reutilizar esta misma red/SGs para otra cosa en el Lab 3:

- Cambia `var.project_tag` si quieres diferenciarlo con otro tag.
- Los archivos `user_data/*.sh.tpl` son los que definen qué corre en cada
  nodo — reemplázalos por lo que pida el nuevo laboratorio sin tocar
  `network.tf` ni `security_groups.tf` si la topología de red no cambia.
- Si el Lab 3 pide otros puertos/servicios, ajusta las reglas en
  `security_groups.tf` en lugar de crear SGs nuevos desde cero.

## Destruir todo (equivalente al Paso 13 del manual)

```bash
terraform destroy
```

Terraform elimina todo en el orden correcto automáticamente (instancias →
SGs → red), sin el riesgo de "no puedo borrar sg-proxy porque está
referenciado" que menciona el manual.
