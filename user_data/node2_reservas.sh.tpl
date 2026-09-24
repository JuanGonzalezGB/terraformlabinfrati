#!/bin/bash
set -e
dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker
mkdir -p /opt/servicio-reservas

cat > /opt/servicio-reservas/app.py << 'PYEOF'
import os, time, urllib.request
from flask import Flask, jsonify, request
import psycopg2

app = Flask(__name__)
DB_HOST = os.getenv("DB_HOST", "${db_host}")
DB_PASS = os.getenv("DB_PASS", "${db_password}")

def get_conn(retries=10, delay=5):
    for attempt in range(retries):
        try:
            return psycopg2.connect(host=DB_HOST, port=5432,
                dbname="labdb", user="labuser", password=DB_PASS, connect_timeout=5)
        except psycopg2.OperationalError as e:
            if attempt < retries - 1:
                time.sleep(delay)
            else:
                raise e

def get_meta(path):
    try:
        req = urllib.request.Request("http://169.254.169.254/latest/api/token", data=b"", method="PUT",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"})
        token = urllib.request.urlopen(req, timeout=2).read().decode()
        req2 = urllib.request.Request(
            f"http://169.254.169.254/latest/meta-data/{path}", headers={"X-aws-ec2-metadata-token": token})
        return urllib.request.urlopen(req2, timeout=2).read().decode()
    except:
        return "no-disponible"

@app.route("/health")
def health():
    return jsonify({"status":"ok","servicio":"reservas",
        "nodo":get_meta("instance-id"),"az":get_meta("placement/availability-zone")})

@app.route("/api/reservas", methods=["GET"])
def list_reservas():
    conn = get_conn(); cur = conn.cursor()
    cur.execute("SELECT id,pasajero,origen,destino,fecha_vuelo::text,creado_en::text FROM reservas ORDER BY id")
    rows = cur.fetchall(); cur.close(); conn.close()
    return jsonify([{"id":r[0],"pasajero":r[1],"origen":r[2],
        "destino":r[3],"fecha_vuelo":r[4],"creado_en":r[5]} for r in rows])

@app.route("/api/reservas", methods=["POST"])
def create_reserva():
    data = request.get_json(force=True); conn = get_conn(); cur = conn.cursor()
    cur.execute("INSERT INTO reservas (pasajero,origen,destino,fecha_vuelo) VALUES (%s,%s,%s,%s) RETURNING id",
        (data["pasajero"],data["origen"],data["destino"],data["fecha_vuelo"]))
    new_id = cur.fetchone()[0]; conn.commit(); cur.close(); conn.close()
    return jsonify({"id":new_id,"mensaje":"Reserva creada","nodo":get_meta("instance-id")}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PYEOF

cat > /opt/servicio-reservas/requirements.txt << 'EOF'
flask==3.0.3
psycopg2-binary==2.9.9
EOF

cat > /opt/servicio-reservas/Dockerfile << 'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 8080
CMD ["python", "app.py"]
EOF

cd /opt/servicio-reservas
docker build -t servicio-reservas:1.0 .
docker run -d --name servicio-reservas --restart unless-stopped \
  -p 8080:8080 -e DB_HOST=${db_host} -e DB_PASS=${db_password} \
  servicio-reservas:1.0
echo "Node 2 (servicio-reservas) listo."
