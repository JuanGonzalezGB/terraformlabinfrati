#!/bin/bash
set -e
dnf update -y
dnf install -y nginx
rm -f /etc/nginx/conf.d/default.conf

cat > /etc/nginx/conf.d/lab.conf << 'NGINXEOF'
log_format upstream_log '$remote_addr - $upstream_addr [$time_local] "$request" $status';

upstream servicio_reservas { server ${node2_ip}:8080; }
upstream servicio_pasajeros { server ${node3_ip}:8080; }

server {
    listen 80;
    server_name _;
    access_log /var/log/nginx/access.log upstream_log;

    location = /health {
        default_type application/json;
        return 200 '{"nodo":"proxy-nginx","status":"ok"}';
    }

    location /api/reservas {
        proxy_pass http://servicio_reservas;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 10s;
    }

    location /api/pasajeros {
        proxy_pass http://servicio_pasajeros;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 10s;
    }

    location / {
        default_type application/json;
        return 200 '{"lab":"3-tier","rutas":["/api/reservas","/api/pasajeros","/health"]}';
    }
}
NGINXEOF

systemctl enable nginx
systemctl start nginx
echo "Node 1 (nginx proxy) listo."
