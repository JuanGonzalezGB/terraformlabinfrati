#!/bin/bash
set -e
dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker

# Lanzar contenedor PostgreSQL 16 Alpine con volumen persistente
docker run -d \
  --name postgres \
  --restart unless-stopped \
  -e POSTGRES_USER=labuser \
  -e POSTGRES_PASSWORD=${db_password} \
  -e POSTGRES_DB=labdb \
  -v pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16-alpine

# Esperar que PostgreSQL acepte conexiones
echo "Esperando PostgreSQL..."
for i in $(seq 1 20); do
  if docker exec postgres pg_isready -U labuser -d labdb > /dev/null 2>&1; then
    echo "PostgreSQL listo (intento $i)."
    break
  fi
  sleep 3
done

# Escribir SQL en archivo temporal
cat > /tmp/init.sql << 'EOF'
CREATE TABLE IF NOT EXISTS reservas (
  id SERIAL PRIMARY KEY,
  pasajero VARCHAR(100) NOT NULL,
  origen CHAR(3) NOT NULL,
  destino CHAR(3) NOT NULL,
  fecha_vuelo DATE NOT NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO reservas (pasajero, origen, destino, fecha_vuelo) VALUES
  ('Sofia Martinez', 'BOG', 'MDE', '2025-09-01'),
  ('Andres Gomez', 'CLO', 'BOG', '2025-09-05'),
  ('Valentina Restrepo', 'BOG', 'CTG', '2025-09-10');

CREATE TABLE IF NOT EXISTS pasajeros (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  telefono VARCHAR(20),
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO pasajeros (nombre, email, telefono) VALUES
  ('Sofia Martinez', 'smartinez@correo.co', '3101234567'),
  ('Andres Gomez', 'agomez@correo.co', '3209876543'),
  ('Mateo Ramirez', 'mramirez@correo.co', '3156547890');
EOF

# Copiar SQL al contenedor y ejecutar
docker cp /tmp/init.sql postgres:/tmp/init.sql
docker exec postgres psql -U labuser -d labdb -f /tmp/init.sql
echo "Node 4 (PostgreSQL) listo."
