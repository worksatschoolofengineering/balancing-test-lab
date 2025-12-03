#!/bin/bash
set -e

echo "=================================================="
echo " INICIANDO SCRIPT DE LABORATORIO DOCKER + NGINX LB "
echo "=================================================="

# ------------------------------
# 1. CONFIGURAR DNS DEL SISTEMA
# ------------------------------

echo "[1/8] Configurando DNS del sistema (Netplan)..."

NETPLAN_FILE=$(ls /etc/netplan/*.yaml | head -n 1)

sudo bash -c "cat > $NETPLAN_FILE" <<EOF
network:
  version: 2
  ethernets:
    $(ip -o -4 route get 1.1.1.1 | awk '{print $5}'):
      dhcp4: yes
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
EOF

sudo netplan apply

sleep 2
echo "[✓] DNS del sistema configurado."

# ------------------------------
# 2. CONFIGURAR DNS PARA DOCKER
# ------------------------------

echo "[2/8] Configurando DNS para Docker..."

sudo mkdir -p /etc/docker

sudo bash -c "cat > /etc/docker/daemon.json" <<EOF
{
  "dns": ["1.1.1.1", "8.8.8.8"]
}
EOF

# ------------------------------
# 3. INSTALAR DOCKER SI NO EXISTE
# ------------------------------

echo "[3/8] Verificando Docker..."

if ! command -v docker &> /dev/null; then
    echo "[!] Docker no encontrado. Instalando..."
    sudo apt update
    sudo apt install docker.io -y
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "[✓] Docker ya está instalado."
fi

sudo systemctl restart docker
sleep 2

# ------------------------------
# 4. INSTALAR DOCKER COMPOSE (V2)
# ------------------------------

echo "[4/8] Verificando Docker Compose..."

if ! docker compose version >/dev/null 2>&1; then
    echo "[!] Docker Compose V2 no encontrado. Instalando..."
    sudo apt install docker-compose-plugin -y
else
    echo "[✓] Docker Compose V2 ya está instalado."
fi

# ------------------------------
# 5. PROBAR DESCARGA DESDE DOCKER HUB
# ------------------------------

echo "[5/8] Probando conexión a Docker Hub..."
if ! docker pull nginx:latest; then
    echo "[ERROR] No se pudo conectar a Docker Hub."
    echo "Revisa la red o la configuración del firewall."
    exit 1
else
    echo "[✓] Conectividad con Docker Hub exitosa."
fi

# ------------------------------
# 6. CREAR LABORATORIO DOCKER
# ------------------------------

LAB_DIR=~/lab-docker

echo "[6/8] Creando estructura del laboratorio en $LAB_DIR..."

mkdir -p $LAB_DIR/{backend1,backend2,loadbalancer}

echo "<h1>Backend 1</h1>" > $LAB_DIR/backend1/index.html
echo "<h1>Backend 2</h1>" > $LAB_DIR/backend2/index.html

cat <<EOF > $LAB_DIR/loadbalancer/default.conf
upstream backend_cluster {
    server backend1:80;
    server backend2:80;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend_cluster;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

cat <<EOF > $LAB_DIR/docker-compose.yml
services:
  backend1:
    image: nginx:latest
    container_name: backend1
    volumes:
      - ./backend1:/usr/share/nginx/html
    networks:
      - labnet

  backend2:
    image: nginx:latest
    container_name: backend2
    volumes:
      - ./backend2:/usr/share/nginx/html
    networks:
      - labnet

  loadbalancer:
    image: nginx:latest
    container_name: loadbalancer
    ports:
      - "8080:80"
    volumes:
      - ./loadbalancer/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - labnet

networks:
  labnet:
EOF

# ------------------------------
# 7. LEVANTAR CONTENEDORES
# ------------------------------

echo "[7/8] Levantando contenedores con Docker Compose..."

cd $LAB_DIR
docker compose up -d

sleep 3

echo "[✓] Contenedores levantados."
docker ps

# ------------------------------
# 8. INSTALAR APACHE BENCHMARK
# ------------------------------

echo "[8/8] Instalando Apache Benchmark..."
sudo apt install apache2-utils -y

echo "=================================================="
echo " ✔ LABORATORIO COMPLETAMENTE CONFIGURADO"
echo " ✔ DOCKER + NGINX LB OPERATIVO"
echo " ✔ APACHE BENCHMARK LISTO"
echo "=================================================="
echo ""
echo "Acceso al balanceador:"
echo "  http://$(hostname -I | awk '{print $1}'):8080/"
echo ""
echo "Pruebas recomendadas:"
echo "  ab -n 1000 -c 10 http://localhost:8080/"
echo "  ab -n 20000 -c 200 -k http://localhost:8080/"
echo ""
echo "=================================================="
